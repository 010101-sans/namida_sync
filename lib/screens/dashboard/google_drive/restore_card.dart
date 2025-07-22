import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../../providers/providers.dart';
import '../../../models/models.dart';
import '../../../utils/utils.dart';
import '../../../widgets/custom_card.dart';

class GoogleDriveRestoreCard extends StatefulWidget {
  final VoidCallback? onRestoreComplete;
  const GoogleDriveRestoreCard({super.key, this.onRestoreComplete});
  @override
  State<GoogleDriveRestoreCard> createState() => _GoogleDriveRestoreCardState();
}

class _GoogleDriveRestoreCardState extends State<GoogleDriveRestoreCard> {
  bool restoreZipSelected = true;
  bool restoreMusicFoldersSelected = false;
  String? lastRestoreZipPath;
  SyncManifest? currentManifest;

  Future<void> _runRestore(GoogleDriveProvider driveProvider, FolderProvider folderProvider) async {
    // Try to download and parse manifest to show platform info
    try {
      final manifestTemp = File('${Directory.systemTemp.path}/sync_manifest.json');
      final manifestFile = await driveProvider.driveService.downloadLatestManifest(manifestTemp);
      if (manifestFile != null && await manifestFile.exists()) {
        final manifest = SyncManifest.fromJsonString(await manifestFile.readAsString());
        setState(() {
          currentManifest = manifest;
        });
      }
    } catch (_) {
      // Ignore manifest download errors, proceed with restore
    }

    String? zipPath;
    if (restoreZipSelected) {
      final backupFolder = folderProvider.backupFolder?.path;
      if (backupFolder != null) {
        final dir = Directory(backupFolder);
        if (dir.existsSync()) {
          final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.zip')).toList();
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          if (files.isNotEmpty) {
            zipPath = files.first.path;
          }
        }
      }
    }
    setState(() {
      lastRestoreZipPath = zipPath;
    });

    await driveProvider.restoreFromDrive(
      restoreZip: restoreZipSelected,
      restoreMusicFolders: restoreMusicFoldersSelected,
      context: context,
      folderProvider: folderProvider,
      onProgress: (file, progress) {},
    );
    // Call the onRestoreComplete callback after restore
    widget.onRestoreComplete?.call();

    // After restore, update lastRestoreZipPath to the actual restored file
    if (restoreZipSelected) {
      final backupFolder = folderProvider.backupFolder?.path;
      if (backupFolder != null) {
        final dir = Directory(backupFolder);
        if (dir.existsSync()) {
          final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.zip')).toList();
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          if (files.isNotEmpty) {
            setState(() {
              lastRestoreZipPath = files.first.path;
            });
          }
        }
      }
    }
  }

  String _platformDisplayName(String platform) {
    switch (platform) {
      case 'android':
        return 'Android';
      case 'windows':
        return 'Windows';
      case 'linux':
        return 'Linux';
      case 'macos':
        return 'macOS';
      case 'ios':
        return 'iOS';
      default:
        return platform;
    }
  }

  String _backupDateDisplay(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<GoogleAuthProvider, GoogleDriveProvider, FolderProvider>(
      builder: (context, authProvider, driveProvider, folderProvider, _) {
        final user = authProvider.authService.currentCreds;
        final isSignedIn = user != null;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final validMusicFolders = folderProvider.musicFoldersUnmodifiable
            .where((f) => f.status == FolderStatus.valid)
            .map((f) => f.path)
            .toList();
        final normalizedMusicFolders = validMusicFolders.map((p) => p.replaceAll('\\', '/')).toList();

        // debugPrint('[UI] validMusicFolders: $validMusicFolders');
        // debugPrint('[UI] normalizedMusicFolders: $normalizedMusicFolders');
        // debugPrint('[UI] restoreFileProgress keys: \n${driveProvider.restoreFileProgress.keys.toList()}');

        if (!isSignedIn) {
          return const SizedBox.shrink();
        }
        // [1] Main Column
        return Column(
          children: [
            // [1.1] Main Card
            CustomCard(
              leadingIcon: Iconsax.cloud,
              title: 'Google Drive Restore',
              iconColor: primaryColor,
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Match backup.dart
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [1.1.1] Platform Compatibility Info
                    if (currentManifest != null)
                      Container(
                        decoration: BoxDecoration(
                          color: (currentManifest!.platform == Platform.operatingSystem)
                              ? AppColors.successGreen.withValues(alpha: 0.10)
                              : AppColors.warningOrange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (currentManifest!.platform == Platform.operatingSystem)
                                ? AppColors.successGreen.withValues(alpha: 0.3)
                                : AppColors.warningOrange.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  (currentManifest!.platform == Platform.operatingSystem)
                                      ? Iconsax.tick_circle
                                      : Iconsax.info_circle,
                                  color: (currentManifest!.platform == Platform.operatingSystem)
                                      ? AppColors.successGreen
                                      : AppColors.warningOrange,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (currentManifest!.platform == Platform.operatingSystem)
                                            ? 'Same Platform Restore'
                                            : 'Cross-Platform Restore',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: (currentManifest!.platform == Platform.operatingSystem)
                                              ? AppColors.successGreen
                                              : AppColors.warningOrange,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Backup created on  ${_platformDisplayName(currentManifest!.platform)} on ${_backupDateDisplay(currentManifest!.timestamp)}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: (currentManifest!.platform == Platform.operatingSystem)
                                              ? AppColors.successGreen
                                              : AppColors.warningOrange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // [1.1.2] Restore Options Section
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.06), // Match backup.dart
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16), // Match backup.dart
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // [1.1.2.1] Restore Options Title
                          Text(
                            'What do you want to restore?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // [1.1.2.2] Restore Zip Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: restoreZipSelected,
                                onChanged: (v) => setState(() => restoreZipSelected = v ?? false),
                                activeColor: primaryColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text('Namida Backup zip file'),
                            ],
                          ),
                          // [1.1.2.3] Restore Music Folders Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: restoreMusicFoldersSelected,
                                onChanged: (v) => setState(() => restoreMusicFoldersSelected = v ?? false),
                                activeColor: primaryColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text('Local Music library folders'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // [1.1.3] Restore Status Section
                    if ((driveProvider.isRestoring || driveProvider.hasRestored) &&
                        (restoreZipSelected || (restoreMusicFoldersSelected && validMusicFolders.isNotEmpty)))
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor.withValues(alpha: 0.06), // Match backup.dart
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Match backup.dart
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Restore Status Title
                            Text(
                              'Restore Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Restore Zip Status Row
                            if (restoreZipSelected)
                              (() {
                                final normalizedZipPath = normalizePath(lastRestoreZipPath ?? '');
                                // debugPrint('[UI] Checking status for backup zip: $normalizedZipPath');
                                // debugPrint(
                                //   '[UI] restoreFileProgress keys: ${driveProvider.restoreFileProgress.keys.toList()}',
                                // );
                                return Row(
                                  children: [
                                    Icon(Iconsax.archive, color: theme.colorScheme.secondary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Namida Backup Zip',
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    buildStatusLabel(
                                      context,
                                      status: getRestoreFileStatus(
                                        driveProvider,
                                        normalizedZipPath,
                                        driveProvider.restoreFileFailed,
                                        driveProvider.restoreSkippedFiles,
                                        driveProvider.restoreFileProgress,
                                      ),
                                    ),
                                  ],
                                );
                              })(),
                            // Restore Music Folders Status
                            if (restoreMusicFoldersSelected)
                              ...normalizedMusicFolders
                                  .where((folderPath) => !driveProvider.unsyncedFolders.contains(folderPath))
                                  .map((folderPath) {
                                    // debugPrint('[UI] Checking folderPath: $folderPath');
                                    final separator = '/';
                                    final folderName = folderPath.split(separator).last;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Iconsax.folder, color: primaryColor, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    folderName,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.colorScheme.outline,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: Divider(
                                                      indent: 15,
                                                      thickness: 1,
                                                      color: Colors.grey.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // File Progress Rows
                                        if (driveProvider.restoreFileProgress.entries.any(
                                          (e) => e.key.startsWith(folderPath),
                                        ))
                                          Padding(
                                            padding: const EdgeInsets.only(left: 24, top: 4),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: driveProvider.restoreFileProgress.entries
                                                  .where((e) => e.key.startsWith(folderPath))
                                                  .map((e) {
                                                    final normalizedMusicFilePath = e.key.replaceAll('\\', '/');
                                                    final fileSeparator = '/';
                                                    final fileName = e.key.split(fileSeparator).last;
                                                    // debugPrint(
                                                    //   '[UI] Checking status for music file: $normalizedMusicFilePath',
                                                    // );
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 2),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Iconsax.music,
                                                            size: 15,
                                                            color: theme.colorScheme.secondary,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              fileName,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: Colors.blueGrey,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          buildStatusLabel(
                                                            context,
                                                            status: getRestoreFileStatus(
                                                              driveProvider,
                                                              normalizedMusicFilePath,
                                                              driveProvider.restoreFileFailed,
                                                              driveProvider.restoreSkippedFiles,
                                                              driveProvider.restoreFileProgress,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                            ),
                                          ),
                                      ],
                                    );
                                  }),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // [1.1.4] Action Button
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: driveProvider.isRestoring
                          ? ElevatedButton.icon(
                              icon: Icon(Iconsax.stop_circle, size: 24),
                              label: const Text('Stop', style: TextStyle(fontSize: 15)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryColor, width: 2),
                                foregroundColor: primaryColor,
                                backgroundColor: theme.colorScheme.surface,
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              onPressed: () {
                                driveProvider.requestCancelRestore();
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(const SnackBar(content: Text('Restore stopping...')));
                              },
                            )
                          : ElevatedButton.icon(
                              icon: Icon(Iconsax.cloud_plus, size: 24),
                              label: const Text('Restore', style: TextStyle(fontSize: 15)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                                side: BorderSide(color: primaryColor, width: 2),
                                foregroundColor: primaryColor,
                                backgroundColor: theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              onPressed:
                                  (restoreZipSelected || (restoreMusicFoldersSelected && validMusicFolders.isNotEmpty))
                                  ? () async {
                                      final folderProvider = Provider.of<FolderProvider>(context, listen: false);
                                      final driveProvider = Provider.of<GoogleDriveProvider>(context, listen: false);
                                      await _runRestore(driveProvider, folderProvider);
                                      if (driveProvider.error != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Restore failed:   ${driveProvider.error}')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(const SnackBar(content: Text('Restore complete!')));
                                      }
                                    }
                                  : null,
                            ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
