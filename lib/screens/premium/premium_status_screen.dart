import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Provider/SubscriptionProvider.dart';
import 'subscription_screen.dart';

/// Shows the current subscription status: premium/free card, plan details
/// (type, best-effort expiry), and the premium feature list (or an upgrade
/// prompt for free users).
class PremiumStatusScreen extends StatelessWidget {
  const PremiumStatusScreen({super.key});

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
            backgroundColor: isDark
                ? const Color(0xFF0A0E21)
                : const Color(0xFFF8F9FA),
            foregroundColor: isDark ? Colors.white : Colors.black,
            elevation: 0,
            title: Text(
              subscriptionProvider.isPremium
                  ? '💎 Premium Active'
                  : 'Premium Status',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(context, subscriptionProvider),
                  const SizedBox(height: 24),
                  if (subscriptionProvider.isPremium) ...[
                    _buildSubscriptionDetails(context, subscriptionProvider),
                    const SizedBox(height: 24),
                    _buildPremiumFeatures(context),
                  ] else
                    _buildUpgradePrompt(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    SubscriptionProvider subscriptionProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPremium = subscriptionProvider.isPremium;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                  Color(0xFFFF8C00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  isDark ? const Color(0xFF2A2D4A) : Colors.grey.shade300,
                  isDark ? const Color(0xFF1D1E33) : Colors.grey.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? const Color(0xFFFFD700).withOpacity(0.4)
                : Colors.black.withOpacity(0.15),
            blurRadius: isPremium ? 25 : 15,
            offset: Offset(0, isPremium ? 12 : 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              isPremium ? Icons.diamond : Icons.diamond_outlined,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isPremium ? 'Premium Active' : 'Free User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPremium
                  ? '✨ All Premium Features Unlocked'
                  : '🔒 Upgrade to Access Premium',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails(
    BuildContext context,
    SubscriptionProvider subscriptionProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6B4EFF).withOpacity(0.3)
              : const Color(0xFF6B4EFF).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EFF).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B4EFF), Color(0xFF4ECBFF)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Subscription Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            context,
            'Plan Type:',
            subscriptionProvider.subscriptionType,
            Icons.card_membership,
          ),
          if (subscriptionProvider.subscriptionExpiry != null)
            _buildDetailRow(
              context,
              'Expires On:',
              _formatDate(subscriptionProvider.subscriptionExpiry!),
              Icons.calendar_today,
            ),
          _buildDetailRow(
            context,
            'Status:',
            _getSubscriptionStatus(subscriptionProvider),
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF6B4EFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = [
      {'icon': Icons.wallpaper, 'text': 'Unlimited Premium Wallpapers'},
      {'icon': Icons.block, 'text': 'Ad-Free Experience'},
      {'icon': Icons.download, 'text': 'Unlimited Downloads'},
      {'icon': Icons.high_quality, 'text': '4K Quality Images'},
      {'icon': Icons.new_releases, 'text': 'Early Access to New Content'},
      {'icon': Icons.palette, 'text': 'Exclusive Categories'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x3300D9A5),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.star,
                    color: Color(0xFF00D9A5),
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Your Premium Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...features.map(
            (feature) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9A5).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: const Color(0xFF00D9A5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature['text'] as String,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00D9A5),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext screenContext) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B4EFF),
            Color(0xFF4ECBFF),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.diamond_outlined,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upgrade to Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Get unlimited access to premium wallpapers and enjoy an '
            'ad-free experience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  screenContext,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6B4EFF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Choose a Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getSubscriptionStatus(SubscriptionProvider subscriptionProvider) {
    if (!subscriptionProvider.isPremium) return 'Inactive';

    final expiry = subscriptionProvider.subscriptionExpiry;
    if (expiry != null) {
      final daysRemaining = expiry.difference(DateTime.now()).inDays;
      if (daysRemaining > 0) {
        return 'Active ($daysRemaining days left)';
      }
      return 'Active'; // expiry is a heuristic; never report "Expired"
    }
    return 'Active';
  }
}
