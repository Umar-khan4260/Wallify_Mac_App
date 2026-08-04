import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: replace with a list/grid of previously downloaded wallpapers.
    return const EmptyState(
      icon: Icons.download_outlined,
      title: 'No downloads yet',
      message: 'Wallpapers you download will show up here for quick access.',
    );
  }
}
