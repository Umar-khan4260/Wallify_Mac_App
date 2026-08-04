import 'package:flutter/material.dart';

import '../widgets/app_top_bar.dart';
import '../widgets/side_nav_bar.dart';
import 'categories/categories_screen.dart';
import 'downloads/downloads_screen.dart';
import 'explore/explore_screen.dart';
import 'favorites/favorites_screen.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';
import 'trending/trending_screen.dart';

/// The app "shell": fixed sidebar + fixed top bar on every page, with an
/// [IndexedStack] swapping the body. Index order matches [primaryNavItems]
/// (0-5) plus Settings pinned at index 6 — see side_nav_bar.dart.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Home by default

  static const _pages = [
    HomeScreen(),
    ExploreScreen(),
    CategoriesScreen(),
    TrendingScreen(),
    FavoritesScreen(),
    DownloadsScreen(),
    SettingsScreen(),
  ];

  static const _pageTitles = [
    'Home',
    'Explore',
    'Categories',
    'Trending',
    'Favorites',
    'Downloads',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SideNavBar(
            activeIndex: _selectedIndex,
            onIndexChanged: (index) => setState(() => _selectedIndex = index),
          ),
          Expanded(
            child: Column(
              children: [
                AppTopBar(title: _pageTitles[_selectedIndex]),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
