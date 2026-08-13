import 'package:flutter/material.dart';

import '../../data/download_service.dart';
import '../../models/wallpaper.dart';
import '../../theme/app_dimens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/wallpaper_card.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Wallpaper>>(
      valueListenable: DownloadService.instance.listenable,
      builder: (context, downloaded, _) {
        if (downloaded.isEmpty) {
          return const EmptyState(
            icon: Icons.download_outlined,
            title: 'No downloads yet',
            message:
                'Wallpapers you download will show up here for quick access.',
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginEdge,
            AppSpacing.stackLg,
            AppSpacing.marginEdge,
            AppSpacing.stackLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${downloaded.length} Downloaded Wallpaper${downloaded.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Expanded(
                child: GridView.builder(
                  itemCount: downloaded.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 200,
                    crossAxisSpacing: AppSpacing.stackMd,
                    mainAxisSpacing: AppSpacing.stackMd,
                  ),
                  itemBuilder: (context, index) {
                    return WallpaperCard(
                      wallpaper: downloaded[index],
                      wallpapers: downloaded,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
