import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/SubscriptionProvider.dart';
import '../screens/premium/subscription_screen.dart';

/// Static helper used app-wide for premium checks and the "upgrade required"
/// dialog. All checks delegate to [SubscriptionProvider] from the widget tree,
/// so premium state stays reactive and consistent everywhere.
class PremiumHelper {
  static bool isPremiumUser(BuildContext context) {
    return Provider.of<SubscriptionProvider>(context, listen: false).isPremium;
  }

  static bool shouldShowAds(BuildContext context) {
    return !isPremiumUser(context);
  }

  static bool canDownloadUnlimited(BuildContext context) {
    return isPremiumUser(context);
  }

  static bool canAccessPremiumWallpapers(BuildContext context) {
    return isPremiumUser(context);
  }

  static bool canAccessExclusiveCategories(BuildContext context) {
    return isPremiumUser(context);
  }

  static bool canAccessHighQuality(BuildContext context) {
    return isPremiumUser(context);
  }

  static bool hasEarlyAccess(BuildContext context) {
    return isPremiumUser(context);
  }

  /// Show the "premium required" dialog. The page behind it is dimmed and
  /// blurred (glassy background); the dialog itself keeps the standard look.
  /// "Upgrade Now" pushes the paywall.
  static void showPremiumRequiredDialog(
    BuildContext context, {
    String? feature,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Premium Required',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return Stack(
              children: [
                // Glassy background: blur + dim whatever is behind the dialog.
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Center(
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.diamond, color: Colors.purple, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Premium Required',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature != null
                              ? 'This $feature requires a premium subscription.'
                              : 'This feature requires a premium subscription.',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Upgrade to premium to enjoy:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• Unlimited premium wallpapers',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '• 4K Live Wallpapers',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '• High-quality downloads',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '• Exclusive categories',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Maybe Later',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          SubscriptionScreen.show(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Upgrade Now'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
    );
  }

  // Premium badge widget.
  static Widget getPremiumBadge({double size = 16}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond, size: size, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            'PRO',
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Expiry helpers ─────────────────────────────────────────────────────────
  // NOTE: subscriptionExpiry is a best-effort heuristic (no server-side
  // receipt verification). See SubscriptionProvider class doc. These helpers
  // are informational; gating must use [isPremiumUser] only.

  static bool isPremiumExpired(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    if (!subscriptionProvider.isPremium) return false;
    final expiry = subscriptionProvider.subscriptionExpiry;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  static int getDaysRemaining(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final expiry = subscriptionProvider.subscriptionExpiry;
    if (!subscriptionProvider.isPremium || expiry == null) return 0;
    return expiry.difference(DateTime.now()).inDays;
  }

  static void checkAndShowExpiryWarning(BuildContext context) {
    if (!isPremiumUser(context)) return;
    final daysRemaining = getDaysRemaining(context);
    if (daysRemaining <= 3 && daysRemaining > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showExpiryWarning(context, daysRemaining);
      });
    }
  }

  static void _showExpiryWarning(BuildContext context, int daysRemaining) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Subscription Expiring Soon',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Your premium subscription will expire in $daysRemaining '
            '${daysRemaining == 1 ? 'day' : 'days'}. Renew now to continue '
            'enjoying premium features.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Remind Me Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                SubscriptionScreen.show(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Renew Now'),
            ),
          ],
        );
      },
    );
  }
}
