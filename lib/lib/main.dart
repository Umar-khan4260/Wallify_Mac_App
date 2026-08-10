import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Provider/SubscriptionProvider.dart';
import 'data/download_service.dart';
import 'data/favorites_service.dart';
import 'screens/main_screen.dart';
import 'theme/app_colors.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final subscriptionProvider = SubscriptionProvider();
  await subscriptionProvider.init();

  await ThemeController.instance.init();
  await FavoritesService.instance.init();
  await DownloadService.instance.init();
  runApp(WallifyApp(subscriptionProvider: subscriptionProvider));
}

class WallifyApp extends StatelessWidget {
  const WallifyApp({super.key, required this.subscriptionProvider});

  final SubscriptionProvider subscriptionProvider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubscriptionProvider>.value(
      value: subscriptionProvider,
      child: ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Wallify',
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
      ),
    );
  }
}
