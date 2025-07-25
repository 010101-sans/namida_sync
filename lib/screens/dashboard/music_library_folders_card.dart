import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/custom_card.dart';

// Displays the list of user-selected music library folders, with options to add, remove, and refresh.
class MusicLibraryFoldersCard extends StatelessWidget {
  final FolderProvider folderProvider;
  final GoogleDriveProvider? driveProvider;
  final VoidCallback onAddMusicFolder;
  final Future<void> Function(int) onRemoveMusicFolder;
  final VoidCallback onRefresh;

  const MusicLibraryFoldersCard({
    super.key,
    required this.folderProvider,
    this.driveProvider,
    required this.onAddMusicFolder,
    required this.onRemoveMusicFolder,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // [1] Main Card: Music Library Folders
    return CustomCard(
      leadingIcon: Iconsax.music,
      title: 'Music Library Folders',
      headerActions: [
        // [1.1] Refresh Button
        if (!folderProvider.isLoading)
          IconButton(
            icon: Icon(Iconsax.refresh, size: UIConstants.iconSizeL, color: colorScheme.primary),
            tooltip: 'Refresh Folder List',
            onPressed: onRefresh,
          ),

        // [1.2] Add Folder Button
        if (!folderProvider.isLoading)
          IconButton(
            icon: Icon(Iconsax.add_circle, size: UIConstants.iconSizeL, color: colorScheme.primary),
            tooltip: 'Add Folder',
            onPressed: onAddMusicFolder,
          ),
      ],
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [1.3] Empty State: No Folders Added
            if (folderProvider.musicFolders.isEmpty)
              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  'No music library folders added',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
              ),

            // [1.4] List of Music Folders
            for (int i = 0; i < folderProvider.musicFolders.length; i++) ...[
              // [1.4.1] Folder Row Container
              Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // [1.4.1.1] Folder Icon
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Platform.isAndroid ? Iconsax.mobile : Iconsax.monitor,
                          color: colorScheme.primary,
                          size: UIConstants.iconSizeM,
                        ),
                      ),
                    ),

                    // [1.4.1.2] Folder Info (Name & Path)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // [1.4.1.2.1] Folder Name
                            Text(
                              folderProvider.musicFolders[i].name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // [1.4.1.2.2] Folder Path (Platform-specific formatting)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final path = Platform.isAndroid
                                    ? folderProvider.musicFolders[i].path.replaceFirst(
                                        '/storage/emulated/0/',
                                        'Internal Memory/',
                                      )
                                    : folderProvider.musicFolders[i].path;
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    path,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),

                            // [1.4.1.2.3] (Optional) Invalid Folder Warning
                            // Uncomment and implement if folder status checking is enabled.
                            if (folderProvider.musicFolders[i].status == FolderStatus.invalid)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, size: 16, color: AppColors.errorRed),
                                    const SizedBox(width: 8),
                                    Text(
                                      'This folder does not contain any audio files',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.errorRed,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // [1.4.1.3] Remove Folder Button
                    IconButton(
                      icon: Icon(Iconsax.minus_cirlce, size: 22),
                      color: colorScheme.primary,
                      tooltip: 'Remove',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: folderProvider.musicFolders[i].isLoading
                          ? null
                          : () async => await onRemoveMusicFolder(i),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
