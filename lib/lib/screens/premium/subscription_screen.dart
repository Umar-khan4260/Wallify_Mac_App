import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Provider/SubscriptionProvider.dart';
import 'premium_status_screen.dart';

/// Paywall: plan cards driven by the real store products (prices come from
/// [SubscriptionProvider]'s [ProductDetails]), a purchase + restore flow and
/// the standard subscription legal footer.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // Refresh subscription plans (real prices) when the paywall loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().refreshSubscriptionPlans();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePurchase(String productId, SubscriptionProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Processing your purchase...',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      await provider.purchaseSubscription(productId);

      // Wait a moment for the store transaction to be delivered via the
      // purchase stream and the entitlement to be granted.
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loading
      }

      if (provider.isPremium) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Successfully subscribed! Enjoy premium features.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loading
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleRestorePurchases(SubscriptionProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Restoring purchases...',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      await provider.restorePurchases();

      // Restored purchases arrive on the purchase stream; give it a moment.
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loading
      }

      if (provider.isPremium) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchases to restore'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loading
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, _) {
        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF0A0E21)
              : const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text(
              '✨ Premium',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            backgroundColor: isDark
                ? const Color(0xFF1D1E33)
                : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1D1E33), const Color(0xFF2A2D4A)]
                      : [Colors.white, const Color(0xFFF0F0F5)],
                ),
              ),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: subscriptionProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildHeader(subscriptionProvider),
                        if (subscriptionProvider.isPremium) ...[
                          const SizedBox(height: 16),
                          _buildStatusButton(),
                        ],
                        const SizedBox(height: 24),
                        _buildFeaturesList(),
                        const SizedBox(height: 32),
                        _buildSubscriptionPlans(subscriptionProvider),
                        const SizedBox(height: 24),
                        _buildRestoreButton(subscriptionProvider),
                        const SizedBox(height: 24),
                        _buildFooter(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatusButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PremiumStatusScreen(),
            ),
          );
        },
        icon: Icon(
          Icons.verified,
          color: isDark ? Colors.white : const Color(0xFF6B4EFF),
        ),
        label: Text(
          'You\'re Premium — View Subscription Status',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF6B4EFF),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SubscriptionProvider subscriptionProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B4EFF),
            Color(0xFF4ECBFF),
            Color(0xFF7B42FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EFF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.diamond,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Go Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'From ${subscriptionProvider.getLocalizedPrice('weekly')}/week',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🔥 Unlimited Premium Content',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = [
      {
        'icon': Icons.wallpaper,
        'title': 'Unlimited Premium Wallpapers',
        'description': 'Access to exclusive HD wallpapers',
        'color': const Color(0xFF6B4EFF),
      },
      {
        'icon': Icons.block,
        'title': 'Ad-Free Experience',
        'description': 'Browse without interruptions',
        'color': const Color(0xFFFF6B9D),
      },
      {
        'icon': Icons.download,
        'title': 'Unlimited Downloads',
        'description': 'Download as many wallpapers as you want',
        'color': const Color(0xFF4ECBFF),
      },
      {
        'icon': Icons.high_quality,
        'title': '4K Quality Images',
        'description': 'Get the highest resolution wallpapers',
        'color': const Color(0xFFFFA621),
      },
      {
        'icon': Icons.new_releases,
        'title': 'Early Access',
        'description': 'Get new wallpapers before everyone else',
        'color': const Color(0xFF00D9A5),
      },
      {
        'icon': Icons.palette,
        'title': 'Exclusive Categories',
        'description': 'Access to premium-only categories',
        'color': const Color(0xFFFF4B55),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'What You Get',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...features.map(
          (feature) => _buildFeatureItem(
            feature['icon'] as IconData,
            feature['title'] as String,
            feature['description'] as String,
            feature['color'] as Color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans(SubscriptionProvider subscriptionProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subscriptionProvider.isLoadingPlans) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D1E33) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF6B4EFF),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading subscription plans...',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // All three plans, driven by the real product ids. Prices are pulled from
    // the store's ProductDetails via the provider (no hardcoded strings).
    // Yearly is the highlighted/"most popular" plan with a computed savings
    // badge (null until real prices are loaded → badge hidden).
    final plans = [
      {
        'id': SubscriptionProvider.weeklyProductId,
        'title': 'Premium Wallpapers',
        'duration': '7 days',
        'color': const Color(0xFFFF6B9D),
        'popular': false,
        'description': subscriptionProvider.getLocalizedPrice('weekly'),
      },
      {
        'id': SubscriptionProvider.monthlyProductId,
        'title': 'Live Videos Wallpaper',
        'duration': '30 days',
        'color': const Color(0xFF6B4EFF),
        'popular': false,
        'description': subscriptionProvider.getLocalizedPrice('monthly'),
      },
      {
        'id': SubscriptionProvider.yearlyProductId,
        'title': 'All Premium & Remove Ads',
        'duration': '12 months',
        'color': const Color(0xFF00D9A5),
        'popular': true,
        'savings': subscriptionProvider.getSavingsAmount(),
        'description': subscriptionProvider.getLocalizedPrice('yearly'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Choose Your Plan',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...plans
            .map(
              (plan) => _buildSubscriptionPlan(
                plan['id'] as String,
                plan['title'] as String,
                plan['duration'] as String,
                plan['color'] as Color,
                plan['popular'] as bool,
                plan['savings'] as String?,
                subscriptionProvider,
                description: plan['description'] as String?,
              ),
            ),
      ],
    );
  }

  Widget _buildSubscriptionPlan(
    String productId,
    String title,
    String duration,
    Color color,
    bool isPopular,
    String? savings,
    SubscriptionProvider subscriptionProvider, {
    String? description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = description ?? subscriptionProvider.getProductPrice(productId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isPopular
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              )
            : null,
        color: !isPopular
            ? (isDark ? const Color(0xFF1D1E33) : Colors.white)
            : null,
        borderRadius: BorderRadius.circular(20),
        border: !isPopular
            ? Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? color.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isPopular ? 20 : 10,
            offset: Offset(0, isPopular ? 8 : 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'POPULAR',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isPopular
                                        ? Colors.white
                                        : (isDark ? Colors.white : Colors.black),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (savings != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPopular
                                        ? Colors.white
                                        : const Color(0xFFFF4B55),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    savings,
                                    style: TextStyle(
                                      color: isPopular ? color : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            duration,
                            style: TextStyle(
                              color: isPopular
                                  ? Colors.white.withOpacity(0.8)
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: isPopular
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          _handlePurchase(productId, subscriptionProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular ? Colors.white : color,
                        foregroundColor: isPopular ? color : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Subscribe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreButton(SubscriptionProvider subscriptionProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextButton(
      onPressed: () => _handleRestorePurchases(subscriptionProvider),
      child: Text(
        'Restore Purchases',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'Subscription will be charged to your account. Subscriptions '
            'automatically renew unless auto-renewal is turned off at least '
            '24 hours before the end of the current period.',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              final appUrl =
                  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
              launchUrl(Uri.parse(appUrl));
            },
            child: Text(
              'Terms of Service',
              style: TextStyle(
                color: isDark ? Colors.blue[300] : Colors.blue,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
