import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: replace with a grid of the user's saved wallpapers once
    // favorites are persisted (e.g. via local storage or the API).
    return const EmptyState(
      icon: Icons.favorite_border,
      title: 'No favorites yet',
      message: 'Tap the heart icon on any wallpaper to save it here.',
    );
  }
}
