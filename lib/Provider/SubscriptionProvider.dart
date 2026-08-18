import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/notification_service.dart';

/// Owns the three auto-renewing subscription plans and the premium
/// entitlement, talking to the store through Flutter's official
/// `in_app_purchase` plugin (StoreKit on iOS/macOS, Play Billing on Android).
///
/// Plans (auto-renewing subscriptions only — no one-time / lifetime option):
///   - [weeklyProductId]   "precom.macwallapp.kly"
///   - [monthlyProductId]  "prcom.macwallapp.nthly"
///   - [yearlyProductId]   "premium_yearly"
///
/// ## No-backend limitation (read this before relying on expiry)
/// There is no server performing App Store / Play Store receipt verification,
/// so this provider cannot know the *authoritative* state of an auto-renewing
/// subscription (renewal, lapse, refund, billing retry, ...). The design:
///
///   * `isPremium` means "the store confirmed this user purchased or restored
///     one of our products at some point". That entitlement is the gate used
///     everywhere (PremiumHelper, gating, ...).
///   * `subscriptionExpiry` is a **best-effort heuristic**, computed as
///     `transactionDate + nominal period` for the purchased plan. It is NOT
///     authoritative: an auto-renewal extends the real expiry but we cannot
///     observe that without a backend. It is refreshed on every purchase /
///     restore event and on every launch's `restorePurchases()` reconciliation,
///     so it is informational only and must never be used to revoke access.
///   * Entitlement is cached in [SharedPreferences] as a read-through cache so
///     premium survives a cold start, but every launch re-runs
///     `restorePurchases()` to reconcile with the store. The cache is only a
///     fallback when the store is unreachable; it is never the sole source of
///     truth.
///   * Consequence: we can *grant* premium after a successful purchase/restore
///     but we cannot detect cancellation/lapse client-side. Once granted it
///     stays granted for the session and (via the cache) across launches until
///     the store explicitly reports otherwise. For a production app, add a
///     backend that verifies the store receipt and exposes the real expiry.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider() {
    // Static handle for service-layer gating (download/wallpaper services run
    // outside the widget tree and can't read a Provider). Widgets should
    // prefer Provider.of / context.watch.
    instance = this;
    // The purchase stream MUST be listened to before any purchase attempt.
    // Only platforms with a store implementation (Android/iOS/macOS) expose a
    // working stream; on Windows/Linux/web accessing it throws, so skip it.
    if (isSupportedPlatform) {
      _subscribeToPurchaseStream();
    } else {
      debugPrint(
        'SubscriptionProvider: store not supported on '
        '$defaultTargetPlatform; premium stays locked.',
      );
    }
  }

  /// True when `in_app_purchase` has a real store implementation for this
  /// platform (Android, iOS, macOS). Elsewhere the store is unavailable and
  /// premium stays locked, but the rest of the app must still run normally.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Last created instance. Only use where there is no [BuildContext] (e.g.
  /// DownloadService/WallpaperService guards); in widgets use the provider
  /// from the widget tree instead.
  static SubscriptionProvider? instance;

  // ── Product identifiers ───────────────────────────────────────────────────
  static const String weeklyProductId = 'com.macwallapp.weekly';
  static const String monthlyProductId = 'com.macwallapp.monthly';
  static const String yearlyProductId = 'com.macwallapp.yearly';

  static const List<String> productIds = [
    weeklyProductId,
    monthlyProductId,
    yearlyProductId,
  ];

  // ── Fallback display pricing ───────────────────────────────────────────────
  // Shown on the paywall whenever the store product list isn't loaded yet
  // (e.g. the StoreKit Configuration file is not attached in Xcode, or the
  // products don't exist in App Store Connect / Play Console yet). Real store
  // prices always override these once ProductDetails arrive. Display-only:
  // purchases always go through the store's ProductDetails.
  static const Map<String, double> fallbackPrices = {
    weeklyProductId: 2.99,
    monthlyProductId: 9.99,
    yearlyProductId: 49.99,
  };

  // ── SharedPreferences keys (read-through entitlement cache) ───────────────
  static const String _prefsKeyPremium = 'subscription_is_premium';
  static const String _prefsKeyType = 'subscription_type';
  static const String _prefsKeyProductId = 'subscription_product_id';
  static const String _prefsKeyExpiry = 'subscription_expiry_millis';
  static const String _prefsKeyPurchaseDate =
      'subscription_purchase_date_millis';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _streamSubscription;
  SharedPreferences? _prefs;

  List<ProductDetails> _products = const [];
  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _isLoading = true;
  bool _isLoadingPlans = true;
  bool _isPurchasing = false;
  bool _disposed = false;

  // Entitlement state (ChangeNotifier state — notify on any change).
  bool _isPremium = false;
  String _subscriptionType = '';
  String _subscriptionProductId = '';
  DateTime? _subscriptionExpiry;
  DateTime? _subscriptionPurchaseDate;

  // ── Public state ───────────────────────────────────────────────────────────

  /// Whether the user currently holds the premium entitlement (see class doc).
  bool get isPremium => _isPremium;

  /// Human label of the active plan, e.g. "Weekly", "Monthly" or "Yearly".
  String get subscriptionType => _subscriptionType;

  /// Product ID of the active plan (e.g. [monthlyProductId]), empty if none.
  String get subscriptionProductId => _subscriptionProductId;

  /// Best-effort expiry (see class doc: informational, NOT authoritative).
  DateTime? get subscriptionExpiry => _subscriptionExpiry;

  /// Store-reported transaction date of the last entitlement grant, if any.
  DateTime? get subscriptionPurchaseDate => _subscriptionPurchaseDate;

  /// True while initializing (loading products + reconciling with the store).
  bool get isLoading => _isLoading;

  /// True while product prices are being (re)loaded.
  bool get isLoadingPlans => _isLoadingPlans;

  /// True while a store purchase / pending event is in flight.
  bool get isPurchasing => _isPurchasing;

  /// Whether the store is reachable on this device/platform.
  bool get isAvailable => _isAvailable;

  /// Raw [ProductDetails] for all three plans (empty until loaded).
  List<ProductDetails> get products => _products;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call once at startup (before the app is shown). Loads the cached
  /// entitlement, fetches real store prices and kicks off a `restorePurchases`
  /// reconciliation. Never throws.
  Future<void> init() async {
    if (_isInitialized) return;
    if (!isSupportedPlatform) {
      // No store implementation (Windows/Linux/web): finish quickly with the
      // store marked unavailable so premium stays locked but the app runs.
      _isInitialized = true;
      _isLoading = false;
      _isLoadingPlans = false;
      _notify();
      return;
    }
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadCachedEntitlement();

      _isAvailable = await _inAppPurchase.isAvailable();
      if (_isAvailable) {
        await _queryProductDetails();
        // Reconcile entitlement with the store (fire-and-forget: on iOS/macOS
        // this may prompt for a sign-in, so it must not block first frame).
        unawaited(_reconcileOnLaunch());
      } else {
        _isLoadingPlans = false;
        debugPrint(
          'SubscriptionProvider: in-app purchases are not available on this '
          'platform; premium stays locked.',
        );
      }
    } catch (e) {
      debugPrint('SubscriptionProvider: init failed: $e');
      _isLoadingPlans = false;
    } finally {
      _isInitialized = true;
      _isLoading = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _streamSubscription?.cancel();
    super.dispose();
  }

  // ── Purchasing ─────────────────────────────────────────────────────────────

  /// Starts the store purchase flow for [productId]. The outcome (and the
  /// entitlement grant) is delivered asynchronously on the purchase stream.
  ///
  /// Throws a [StateError] when the store is unavailable or the product id is
  /// not loaded, so callers can surface it to the user.
  Future<void> purchaseSubscription(String productId) async {
    if (_isPurchasing) return;
    if (!_isAvailable) {
      throw StateError('In-app purchases are not available on this platform.');
    }

    final product = _productFor(productId);
    if (product == null) {
      throw StateError(
        'Subscription "$productId" was not found. Add it in App Store '
        'Connect / Play Console, or attach a StoreKit Configuration file to '
        'the Xcode scheme for local testing, then restart the app.',
      );
    }

    _isPurchasing = true;
    _notify();

    // Subscriptions are bought with buyNonConsumable(): in_app_purchase has no
    // dedicated subscription method. The transaction result and entitlement are
    // handled in the purchase-stream listener below.
    try {
      await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e) {
      debugPrint('SubscriptionProvider: buyNonConsumable threw: $e');
      _isPurchasing = false;
      _notify();
      rethrow;
    }
  }

  /// Simulates a successful purchase for local testing without Xcode StoreKit.
  Future<void> mockPurchase(String productId) async {
    _isPurchasing = true;
    _notify();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    _isPremium = true;
    _subscriptionProductId = productId;
    _subscriptionType = _typeLabelForProduct(productId);
    _subscriptionPurchaseDate = DateTime.now();
    _subscriptionExpiry = _computeBestEffortExpiry(
      productId,
      _subscriptionPurchaseDate,
    );
    await _persistEntitlement();

    _isPurchasing = false;
    _notify();
  }

  /// Asks the store to restore prior purchases. Restored entitlements arrive
  /// on the purchase stream (restored status) — same code path as a purchase.
  /// Throws when the store is unavailable or restore fails.
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      throw StateError('In-app purchases are not available on this platform.');
    }
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('SubscriptionProvider: restorePurchases failed: $e');
      rethrow;
    }
  }

  // ── Product plans / pricing ────────────────────────────────────────────────

  /// Re-queries the three product ids from the store (used by the paywall
  /// screen on load). Safe to call repeatedly.
  Future<void> refreshSubscriptionPlans() async {
    if (!_isAvailable) {
      _isLoadingPlans = false;
      _notify();
      return;
    }
    await _queryProductDetails();
  }

  /// ProductDetails for [productId], or null if not loaded yet.
  ProductDetails? productFor(String productId) => _productFor(productId);

  /// Real, store-localized price string (e.g. "$4.99") for
  /// "weekly" / "monthly" / "yearly". Falls back to [fallbackPrices] while the
  /// store products aren't loaded. Returns "--" only for unknown ids.
  String getLocalizedPrice(String period) =>
      getProductPrice(_productIdForPeriod(period));

  /// Real, store-localized price string for a raw [productId]. Falls back to
  /// [fallbackPrices] (e.g. "$5", "$20", "$100") when the store product list
  /// isn't loaded yet.
  String getProductPrice(String productId) {
    final product = _productFor(productId);
    if (product != null && product.price.isNotEmpty) return product.price;
    final fallback = fallbackPrices[productId];
    if (fallback != null) return _formatFallbackPrice(fallback);
    return '--';
  }

  String _formatFallbackPrice(double value) {
    if (value == value.roundToDouble()) {
      return '\$${value.round()}';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  /// "Save X%" for the yearly plan vs 12 × the monthly price, computed from
  /// the store's numeric [ProductDetails.rawPrice] (locale-independent) or the
  /// [fallbackPrices] when store products aren't loaded. Returns null when
  /// there is no saving or prices are unavailable.
  ///
  /// `rawPrice`/`currencyCode` (in_app_purchase >= 3.1.0) give real numeric
  /// prices, so this is computed reliably instead of parsing the localized
  /// price strings (parsing "$4.99"-style strings across locales is fragile).
  String? getSavingsAmount() {
    final yearly = _productFor(yearlyProductId);
    final monthly = _productFor(monthlyProductId);
    final yearlyPrice = yearly?.rawPrice ?? fallbackPrices[yearlyProductId];
    final monthlyPrice = monthly?.rawPrice ?? fallbackPrices[monthlyProductId];
    if (yearlyPrice == null || monthlyPrice == null) return null;
    final monthlyTotal = monthlyPrice * 12;
    if (monthlyTotal <= 0 || yearlyPrice <= 0) return null;
    final percent = ((monthlyTotal - yearlyPrice) / monthlyTotal * 100).round();
    if (percent <= 0) return null;
    return 'Save $percent%';
  }

  /// Whether the store returned our product list. False when products are not
  /// configured (missing StoreKit Configuration in Xcode / App Store Connect),
  /// which the paywall surfaces as a hint.
  bool get hasLoadedPlans => _products.isNotEmpty;

  // ── Purchase-stream handling ───────────────────────────────────────────────

  void _subscribeToPurchaseStream() {
    if (_streamSubscription != null) return;
    try {
      _streamSubscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object error) {
          debugPrint('SubscriptionProvider: purchase stream error: $error');
          _isPurchasing = false;
          _notify();
        },
      );
    } catch (e) {
      debugPrint(
        'SubscriptionProvider: cannot subscribe to purchase stream: $e',
      );
      _isAvailable = false;
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> details) async {
    for (final purchase in details) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // e.g. sandbox/TestFlight purchases awaiting approval elsewhere.
          debugPrint(
            'SubscriptionProvider: purchase pending for ${purchase.productID}',
          );
          _isPurchasing = true;
          _notify();
          break;
        case PurchaseStatus.purchased:
          debugPrint(
            'SubscriptionProvider: ${purchase.status} for ${purchase.productID}',
          );
          await _grantEntitlement(purchase);
          await _completePurchaseIfNeeded(purchase);
          _isPurchasing = false;
          _notify();
          // Celebrate only brand-new purchases — a restored entitlement was
          // already owned (and presumably celebrated) before.
          NotificationService.instance.show(
            'Welcome to Premium!',
            'Enjoy all wallpapers',
          );
          break;
        case PurchaseStatus.restored:
          debugPrint(
            'SubscriptionProvider: ${purchase.status} for ${purchase.productID}',
          );
          await _grantEntitlement(purchase);
          await _completePurchaseIfNeeded(purchase);
          _isPurchasing = false;
          _notify();
          break;
        case PurchaseStatus.error:
          debugPrint(
            'SubscriptionProvider: purchase error for ${purchase.productID}: '
            '${purchase.error}',
          );
          // Some platforms keep a dangling transaction on error; finishing it
          // avoids a stuck purchase queue.
          await _completePurchaseIfNeeded(purchase);
          _isPurchasing = false;
          _notify();
          break;
        case PurchaseStatus.canceled:
          debugPrint(
            'SubscriptionProvider: purchase cancelled for ${purchase.productID}',
          );
          _isPurchasing = false;
          _notify();
          break;
      }
    }
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      try {
        await _inAppPurchase.completePurchase(purchase);
      } catch (e) {
        debugPrint('SubscriptionProvider: completePurchase failed: $e');
      }
    }
  }

  Future<void> _grantEntitlement(PurchaseDetails purchase) async {
    final productId = purchase.productID;
    if (!productIds.contains(productId)) {
      debugPrint(
        'SubscriptionProvider: ignoring unknown product "$productId".',
      );
      return;
    }
    _isPremium = true;
    _subscriptionProductId = productId;
    _subscriptionType = _typeLabelForProduct(productId);
    _subscriptionPurchaseDate = _parseTransactionDate(purchase.transactionDate);
    // Best-effort expiry only — see the class doc. Never authoritative for
    // auto-renewing subscriptions without server-side receipt verification.
    _subscriptionExpiry = _computeBestEffortExpiry(
      productId,
      _subscriptionPurchaseDate,
    );
    await _persistEntitlement();
  }

  /// `transactionDate` is an ISO-8601 string from the store; normalize to a
  /// [DateTime] or null when the platform did not provide one.
  DateTime? _parseTransactionDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      debugPrint('SubscriptionProvider: unparseable transactionDate: $raw');
      return null;
    }
  }

  /// transactionDate + the nominal billing period of the plan.
  DateTime? _computeBestEffortExpiry(
    String productId,
    DateTime? transactionDate,
  ) {
    if (transactionDate == null) return null;
    return transactionDate.add(_periodForProduct(productId));
  }

  // ── Local entitlement cache (read-through) ─────────────────────────────────

  void _loadCachedEntitlement() {
    final prefs = _prefs;
    if (prefs == null) return;
    if (prefs.getBool(_prefsKeyPremium) ?? false) {
      _isPremium = true;
      _subscriptionType = prefs.getString(_prefsKeyType) ?? '';
      _subscriptionProductId = prefs.getString(_prefsKeyProductId) ?? '';
      final expiry = prefs.getInt(_prefsKeyExpiry);
      if (expiry != null) {
        _subscriptionExpiry = DateTime.fromMillisecondsSinceEpoch(expiry);
      }
      final purchasedAt = prefs.getInt(_prefsKeyPurchaseDate);
      if (purchasedAt != null) {
        _subscriptionPurchaseDate = DateTime.fromMillisecondsSinceEpoch(
          purchasedAt,
        );
      }
    }
  }

  Future<void> _persistEntitlement() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyPremium, _isPremium);
    await prefs.setString(_prefsKeyType, _subscriptionType);
    await prefs.setString(_prefsKeyProductId, _subscriptionProductId);
    final expiry = _subscriptionExpiry;
    if (expiry != null) {
      await prefs.setInt(_prefsKeyExpiry, expiry.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_prefsKeyExpiry);
    }
    final purchasedAt = _subscriptionPurchaseDate;
    if (purchasedAt != null) {
      await prefs.setInt(
        _prefsKeyPurchaseDate,
        purchasedAt.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_prefsKeyPurchaseDate);
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Re-runs `restorePurchases()` on launch so the cached entitlement is
  /// reconciled against the store. Store-unreachable is non-fatal: the cached
  /// entitlement (if any) remains until the store can be reached.
  Future<void> _reconcileOnLaunch() async {
    if (!_isAvailable) return;
    try {
      await restorePurchases();
    } catch (_) {
      debugPrint(
        'SubscriptionProvider: launch reconciliation failed; keeping cache.',
      );
    }
  }

  Future<void> _queryProductDetails() async {
    _isLoadingPlans = true;
    _notify();
    try {
      final response = await _inAppPurchase.queryProductDetails(
        productIds.toSet(),
      );
      if (response.error != null) {
        debugPrint(
          'SubscriptionProvider: product query error: ${response.error}',
        );
      } else {
        _products = response.productDetails;
      }
    } catch (e) {
      debugPrint('SubscriptionProvider: product query threw: $e');
    } finally {
      _isLoadingPlans = false;
      _notify();
    }
  }

  ProductDetails? _productFor(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  String _productIdForPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'weekly':
        return weeklyProductId;
      case 'monthly':
        return monthlyProductId;
      case 'yearly':
        return yearlyProductId;
      default:
        return weeklyProductId;
    }
  }

  String _typeLabelForProduct(String productId) {
    switch (productId) {
      case weeklyProductId:
        return 'Weekly';
      case monthlyProductId:
        return 'Monthly';
      case yearlyProductId:
        return 'Yearly';
      default:
        return 'Premium';
    }
  }

  Duration _periodForProduct(String productId) {
    switch (productId) {
      case weeklyProductId:
        return const Duration(days: 7);
      case monthlyProductId:
        return const Duration(days: 30);
      case yearlyProductId:
        return const Duration(days: 365);
      default:
        return const Duration(days: 30);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
