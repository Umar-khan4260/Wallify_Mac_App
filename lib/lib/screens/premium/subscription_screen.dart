import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Provider/SubscriptionProvider.dart';
import '../../theme/app_colors.dart';

/// Paywall presented as a frosted-glass dialog that floats over a blurred,
/// gradient background – matching the Wallify blue theme.
///
/// Shows three plan cards and a "Continue" CTA, with a loading dialog that
/// also has a glassmorphism treatment.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 0 = weekly · 1 = monthly · 2 = yearly
  int _selectedPlan = 2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
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

  Color get _primaryBlue => AppColors.primary;
  Color get _lightBlue => const Color(0xFF2979FF);
  Color get _accentBlue => const Color(0xFF448AFF);

  void _handlePurchase(SubscriptionProvider provider) async {
    final productId = _productIds[_selectedPlan];
    _showGlassyLoadingDialog('Processing your purchase…');

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
    _showGlassyLoadingDialog('Restoring purchases…');

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

  void _showGlassyLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── animated gradient backdrop ──────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryBlue.withValues(alpha: 0.95),
                      const Color(0xFF001D6C),
                      _lightBlue.withValues(alpha: 0.9),
                      const Color(0xFF0A1628),
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),

              // ── decorative blurred circles ──────────────────────────────
              Positioned(
                top: -80,
                left: -60,
                child: _blurCircle(220, _accentBlue.withValues(alpha: 0.3)),
              ),
              Positioned(
                bottom: 60,
                right: -80,
                child: _blurCircle(260, _primaryBlue.withValues(alpha: 0.25)),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: MediaQuery.of(context).size.width * 0.5,
                child: _blurCircle(180, Colors.white.withValues(alpha: 0.05)),
              ),

              // ── glass panel ─────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // close button
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _GlassIconButton(
                              icon: Icons.close,
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildTitle(),
                                const SizedBox(height: 28),
                                _buildFeatureChips(),
                                const SizedBox(height: 32),
                                _buildPlanCards(provider),
                                const SizedBox(height: 28),
                                _buildContinueButton(provider),
                                const SizedBox(height: 16),
                                _buildFooter(provider),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTitle() {
    return Column(
      children: [
        // diamond icon in glass circle
        ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.diamond_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Unlock Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get unlimited wallpapers, 4K downloads\nand an ad-free experience.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 14.5,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChips() {
    const features = [
      (Icons.wallpaper_rounded, 'Unlimited Wallpapers'),
      (Icons.block, 'Ad-Free Experience'),
      (Icons.high_quality, '4K Downloads'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.$1, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      f.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanCards(SubscriptionProvider provider) {
    final plans = [
      _PlanData(
        id: SubscriptionProvider.weeklyProductId,
        label: 'Weekly',
        badge: null,
        price: provider.getLocalizedPrice('weekly'),
        period: '/ week',
        subtitle: 'Cancel anytime',
      ),
      _PlanData(
        id: SubscriptionProvider.monthlyProductId,
        label: 'Monthly',
        badge: null,
        price: provider.getLocalizedPrice('monthly'),
        period: '/ month',
        subtitle: 'Cancel anytime',
      ),
      _PlanData(
        id: SubscriptionProvider.yearlyProductId,
        label: 'Yearly',
        badge: 'Best Value',
        price: provider.getLocalizedPrice('yearly'),
        period: '/ year',
        subtitle: provider.getSavingsAmount() != null
            ? 'Save ${provider.getSavingsAmount()} vs. Monthly'
            : 'Most popular',
      ),
    ];

    return Column(
      children: plans.asMap().entries.map((entry) {
        final idx = entry.key;
        final plan = entry.value;
        final selected = _selectedPlan == idx;

        return GestureDetector(
          onTap: () => setState(() => _selectedPlan = idx),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.15),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // selection indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: selected ? 1 : 0.4,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: selected
                            ? Icon(Icons.check, size: 14, color: _primaryBlue)
                            : null,
                      ),
                      const SizedBox(width: 16),

                      // label + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  plan.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (plan.badge != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      plan.badge!,
                                      style: TextStyle(
                                        color: _primaryBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              plan.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan.price.isEmpty ? '—' : plan.price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            plan.period,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(SubscriptionProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : () => _handlePurchase(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(SubscriptionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _footerLink('Restore Purchases', () => _handleRestore(provider)),
        _footerDot(),
        _footerLink(
          'Terms of Service',
          () => launchUrl(Uri.parse('https://example.com/terms')),
        ),
        _footerDot(),
        _footerLink(
          'Privacy Policy',
          () => launchUrl(Uri.parse('https://example.com/privacy')),
        ),
      ],
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 11.5,
        decoration: TextDecoration.underline,
        decorationColor: Colors.white.withValues(alpha: 0.3),
      ),
    ),
  );

  Widget _footerDot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      '·',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 14,
      ),
    ),
  );

  // ─── helper widgets ───────────────────────────────────────────────────────────

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

// ─── glass icon button ────────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
