import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Provider/SubscriptionProvider.dart';

/// Paywall presented as a centered modal dialog over a blurred background.
/// Matches the dark theme of the app while following the layout of the provided screenshot:
/// - Vertical feature list
/// - Side-by-side plan cards
/// - Large Continue button
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
  int _selectedPlan = 2;

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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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

    // Force a dark modal look as requested, but using theme colors where appropriate
    final modalBgColor = const Color(0xFF1E1E1E); // Dark gray modal background
    final textColor = Colors.white;
    final textSubColor = Colors.white70;
    final borderColor = Colors.white.withValues(alpha: 0.1);

    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── blurred background ──────────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),

              // ── centered modal ─────────────────────────────────────────────
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: () {}, // Prevent tap from closing modal
                      child: Container(
                        width: 700, // Wide enough for 3 side-by-side plans
                        constraints: const BoxConstraints(maxHeight: 800),
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: modalBgColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Close button row
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: textSubColor,
                                  onPressed: () => Navigator.pop(context),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                            ),

                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  40,
                                  0,
                                  40,
                                  40,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildTitle(textColor, textSubColor),
                                    const SizedBox(height: 32),
                                    _buildFeatureList(theme, textColor),
                                    const SizedBox(height: 40),
                                    _buildPlanCards(
                                      provider,
                                      theme,
                                      textColor,
                                      textSubColor,
                                      borderColor,
                                    ),
                                    const SizedBox(height: 32),
                                    _buildContinueButton(provider, theme),
                                    const SizedBox(height: 24),
                                    _buildFooter(provider, textSubColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildTitle(Color textColor, Color textSubColor) {
    return Column(
      children: [
        Text(
          'Unlock Premium',
          style: TextStyle(
            color: textColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Get unlimited wallpapers, 4K downloads and an ad-free experience.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textSubColor, fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildFeatureList(ThemeData theme, Color textColor) {
    final features = [
      (Icons.all_inclusive_rounded, 'Unlimited Wallpapers'),
      (Icons.block, 'Ad-Free Experience'),
      (Icons.high_quality, '4K Downloads'),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(f.$1, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 16),
              Text(
                f.$2,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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
    ThemeData theme,
    Color textColor,
    Color textSubColor,
    Color borderColor,
  ) {
    final plans = [
      _PlanData(
        id: SubscriptionProvider.weeklyProductId,
        label: 'Weekly Plan',
        badge: null,
        price: provider.getLocalizedPrice('weekly'),
        period: '/ week',
        subtitle: 'Cancel anytime',
      ),
      _PlanData(
        id: SubscriptionProvider.monthlyProductId,
        label: 'Monthly Plan',
        badge: null,
        price: provider.getLocalizedPrice('monthly'),
        period: '/ month',
        subtitle: 'Cancel anytime',
      ),
      _PlanData(
        id: SubscriptionProvider.yearlyProductId,
        label: 'Yearly Access',
        badge: 'Best Value',
        price: provider.getLocalizedPrice('yearly'),
        period:
            'One-time payment', // Displayed as one-time per year for clarity
        subtitle: provider.getSavingsAmount() != null
            ? '${provider.getSavingsAmount()} vs. Monthly'
            : 'Most popular',
      ),
    ];

    return Row(
      children: plans.asMap().entries.map((entry) {
        final idx = entry.key;
        final plan = entry.value;
        final selected = _selectedPlan == idx;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = idx),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: idx < plans.length - 1 ? 16 : 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? theme.colorScheme.primary : borderColor,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Selection indicator (circle check or empty circle)
                      Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        color: selected
                            ? theme.colorScheme.primary
                            : borderColor,
                        size: 20,
                      ),
                    ],
                  ),
                  if (plan.badge != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      plan.badge!,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24), // Spacer to align prices
                  ],
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.price.isEmpty ? '—' : plan.price,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (plan.period.startsWith('/')) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            plan.period,
                            style: TextStyle(color: textSubColor, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!plan.period.startsWith('/')) ...[
                    Text(
                      plan.period,
                      style: TextStyle(color: textSubColor, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (plan.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        plan.subtitle,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      plan.subtitle,
                      style: TextStyle(color: textSubColor, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(SubscriptionProvider provider, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _handlePurchase(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(SubscriptionProvider provider, Color textSubColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _footerLink(
          'Restore Purchases',
          () => _handleRestore(provider),
          textSubColor,
        ),
        _footerDot(textSubColor),
        _footerLink(
          'Terms of Service',
          () => launchUrl(Uri.parse('https://example.com/terms')),
          textSubColor,
        ),
        _footerDot(textSubColor),
        _footerLink(
          'Privacy Policy',
          () => launchUrl(Uri.parse('https://example.com/privacy')),
          textSubColor,
        ),
      ],
    );
  }

  Widget _footerLink(String text, VoidCallback onTap, Color color) =>
      GestureDetector(
        onTap: onTap,
        child: Text(text, style: TextStyle(color: color, fontSize: 12)),
      );

  Widget _footerDot(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      '·',
      style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 14),
    ),
  );
}

// ─── data model ───────────────────────────────────────────────────────────────

class _PlanData {
  final String id;
  final String label;
  final String? badge;
  final String price;
  final String period;
  final String subtitle;

  const _PlanData({
    required this.id,
    required this.label,
    this.badge,
    required this.price,
    required this.period,
    required this.subtitle,
  });
}
