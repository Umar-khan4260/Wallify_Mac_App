import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Provider/SubscriptionProvider.dart';

/// Paywall presented as a centered modal dialog over a blurred background.
/// Layout matches the provided screenshot: light card, feature list rows,
/// side-by-side plan cards, selected-plan summary, large CTA button, footer.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  /// Pushes the SubscriptionScreen as a transparent route so the background
  /// glassy blur effect works over the previous screen.
  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SubscriptionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // 0 = weekly · 1 = monthly · 2 = yearly
  int _selectedPlan = 1; // Default to monthly (like screenshot)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().refreshSubscriptionPlans();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  static const _productIds = [
    SubscriptionProvider.weeklyProductId,
    SubscriptionProvider.monthlyProductId,
    SubscriptionProvider.yearlyProductId,
  ];

  void _handlePurchase(SubscriptionProvider provider) async {
    final productId = _productIds[_selectedPlan];
    _showLoadingDialog('Processing your purchase…');

    try {
      await provider.purchaseSubscription(productId);

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (provider.isPremium && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Wallify Premium! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleRestore(SubscriptionProvider provider) async {
    _showLoadingDialog('Restoring purchases…');

    try {
      await provider.restorePurchases();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.isPremium
                  ? 'Purchases restored successfully!'
                  : 'No active purchases found.',
            ),
            backgroundColor: provider.isPremium ? Colors.green : Colors.orange,
          ),
        );
      }
      if (provider.isPremium && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 240,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── blurred background ──────────────────────────────
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ),

              // ── centered modal card ─────────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: () {}, // Prevent tap from closing modal
                      child: FittedBox(
                        // Shrinks the card to fit the screen so no scrolling is
                        // ever needed (scaleDown never enlarges it).
                        fit: BoxFit.scaleDown,
                        child: Container(
                          width: 680,
                          constraints: const BoxConstraints(maxHeight: 820),
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── top bar: title area + restore button ────────
                              _buildTopBar(provider, primary, colorScheme),

                              // ── body ─────────────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  36,
                                  0,
                                  36,
                                  32,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildSubtitle(colorScheme),
                                    const SizedBox(height: 28),
                                    _buildFeatureList(primary, colorScheme),
                                    const SizedBox(height: 32),
                                    _buildPlanCards(
                                      provider,
                                      primary,
                                      colorScheme,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildSelectedPlanSummary(
                                      provider,
                                      primary,
                                      colorScheme,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildContinueButton(provider, primary),
                                    const SizedBox(height: 12),
                                    _buildLegalText(colorScheme),
                                    const SizedBox(height: 16),
                                    _buildFooter(provider, colorScheme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── sections ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(
    SubscriptionProvider provider,
    Color primary,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 24, 24, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title centered
          Text(
            'Unlock Premium',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          // Restore button top-right
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _handleRestore(provider),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Restore',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        'Get unlimited wallpapers, 4K downloads and an 4K Live Wallpapers.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.outline,
          fontSize: 14.5,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFeatureList(Color primary, ColorScheme colorScheme) {
    final features = [
      (
        Icons.all_inclusive_rounded,
        'Unlock all wallpapers',
        'Browse and download unlimited HD & 4K wallpapers without restrictions.',
      ),
      (
        Icons.block_rounded,
        '4K Live Wallpapers',
        'Enjoy stunning 4K live wallpapers.',
      ),
      (
        Icons.high_quality_rounded,
        '4K & HD quality downloads',
        'Download wallpapers in the highest available resolution.',
      ),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.$1, color: primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$2,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.$3,
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanCards(
    SubscriptionProvider provider,
    Color primary,
    ColorScheme colorScheme,
  ) {
    final savingsAmount = provider.getSavingsAmount();
    final monthlySave = _getMonthlySave(provider);

    final plans = [
      _PlanData(
        id: SubscriptionProvider.weeklyProductId,
        label: 'Weekly',
        badge: null,
        price: provider.getLocalizedPrice('weekly'),
        period: '/ week',
        description: 'All wallpapers.',
        saveBadge: null,
      ),
      _PlanData(
        id: SubscriptionProvider.monthlyProductId,
        label: 'Monthly',
        badge: null,
        price: provider.getLocalizedPrice('monthly'),
        period: '/ month',
        description: 'All wallpapers, 4K downloads.',
        saveBadge: monthlySave,
      ),
      _PlanData(
        id: SubscriptionProvider.yearlyProductId,
        label: 'Yearly',
        badge: 'Best Value',
        price: provider.getLocalizedPrice('yearly'),
        period: '/ year',
        description: 'All wallpapers 4K downloads.',
        saveBadge: savingsAmount,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: plans.asMap().entries.map((entry) {
        final idx = entry.key;
        final plan = entry.value;
        final selected = _selectedPlan == idx;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: idx < plans.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.06)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? primary : colorScheme.outlineVariant,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label + Best Value badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.label,
                        style: TextStyle(
                          color: selected ? primary : colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (plan.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plan.badge!,
                            style: TextStyle(
                              color: primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Price
                  Text(
                    plan.price.isEmpty ? '—' : plan.price,
                    style: TextStyle(
                      color: selected ? primary : colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // Period
                  Text(
                    plan.period,
                    style: TextStyle(
                      color: colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Description
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  // Save badge
                  if (plan.saveBadge != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        plan.saveBadge!,
                        style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
      ),
    );
  }

  /// Compute a rough monthly saving vs. yearly price
  String? _getMonthlySave(SubscriptionProvider provider) {
    final yearly = provider.productFor(SubscriptionProvider.yearlyProductId);
    final monthly = provider.productFor(SubscriptionProvider.monthlyProductId);
    final yearlyPrice =
        yearly?.rawPrice ??
        SubscriptionProvider.fallbackPrices[SubscriptionProvider
            .yearlyProductId];
    final monthlyPrice =
        monthly?.rawPrice ??
        SubscriptionProvider.fallbackPrices[SubscriptionProvider
            .monthlyProductId];
    if (yearlyPrice == null || monthlyPrice == null) return null;
    final monthlyVsYearlyPerMonth = yearlyPrice / 12;
    if (monthlyVsYearlyPerMonth >= monthlyPrice) return null;
    final pct = ((monthlyPrice - monthlyVsYearlyPerMonth) / monthlyPrice * 100)
        .round();
    if (pct <= 0) return null;
    return 'Save $pct%';
  }

  Widget _buildSelectedPlanSummary(
    SubscriptionProvider provider,
    Color primary,
    ColorScheme colorScheme,
  ) {
    final labels = ['Weekly', 'Monthly', 'Yearly'];
    final prices = [
      provider.getLocalizedPrice('weekly'),
      provider.getLocalizedPrice('monthly'),
      provider.getLocalizedPrice('yearly'),
    ];
    final periods = ['/ week', '/ month', '/ year'];
    final taglines = [
      'Cancel anytime.',
      'Best for individuals. Cancel anytime.',
      'Best value. Cancel anytime.',
    ];

    final price = prices[_selectedPlan];
    final period = periods[_selectedPlan];
    final tagline = taglines[_selectedPlan];
    final label = labels[_selectedPlan];

    return Column(
      children: [
        Text(
          '$price $period',
          style: TextStyle(
            color: primary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$label plan — $tagline',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(SubscriptionProvider provider, Color primary) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _handlePurchase(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          elevation: 0,
        ),
        child: provider.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Continue to checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLegalText(ColorScheme colorScheme) {
    return Text(
      'Your subscription will automatically renew unless auto-renew is turned off '
      'at least 24-hours before the end of the current period. Payment will be '
      'charged to your account at confirmation of purchase.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colorScheme.outlineVariant,
        fontSize: 11,
        height: 1.5,
      ),
    );
  }

  Widget _buildFooter(SubscriptionProvider provider, ColorScheme colorScheme) {
    final dotStyle = TextStyle(color: colorScheme.outlineVariant, fontSize: 14);
    final linkStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 12,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(
              'https://docs.google.com/document/d/1wXteNXc2pSdutH7YRAyS9Gtg0dr5LfjQI3oONcCBvck/edit?usp=sharing',
            ),
          ),
          child: Text('Terms & Conditions', style: linkStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('·', style: dotStyle),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text('Continue with Free Plan', style: linkStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('·', style: dotStyle),
        ),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(
              'https://sites.google.com/view/qasim-app-studio?usp=sharing')),
          child: Text('Privacy Policy', style: linkStyle),
        ),
      ],
    );
  }
}

// ─── data model ───────────────────────────────────────────────────────────────

class _PlanData {
  final String id;
  final String label;
  final String? badge;
  final String price;
  final String period;
  final String description;
  final String? saveBadge;

  const _PlanData({
    required this.id,
    required this.label,
    this.badge,
    required this.price,
    required this.period,
    required this.description,
    this.saveBadge,
  });
}
