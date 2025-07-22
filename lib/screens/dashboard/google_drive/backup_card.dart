import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../../providers/providers.dart';
import '../../../models/models.dart';
import '../../../widgets/custom_card.dart';

import '../../../utils/google_drive_utils.dart';

class GoogleDriveBackupCard extends StatefulWidget {
  const GoogleDriveBackupCard({super.key});
  @override
  State<GoogleDriveBackupCard> createState() => _GoogleDriveBackupCardState();
}

class _GoogleDriveBackupCardState extends State<GoogleDriveBackupCard> {
  bool backupZipSelected = true;
  bool musicFoldersSelected = false;
  String? lastBackupZipPath;

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

        if (!isSignedIn) {
          return const SizedBox.shrink();
        }

        // [1] Main Card
        return CustomCard(
          leadingIcon: Iconsax.cloud,
          title: 'Google Drive Backup',
          iconColor: primaryColor,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [1.1] Backup Options Section
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [1.1.1] Backup Options Title
                      Text(
                        'What do you want to backup?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // [1.1.2] Backup Zip Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: backupZipSelected,
                            onChanged: (v) => setState(() => backupZipSelected = v ?? false),
                            activeColor: primaryColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text('Namida Backup zip file'),
                        ],
                      ),

                      // [1.1.3] Music Folders Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: musicFoldersSelected,
                            onChanged: (v) => setState(() => musicFoldersSelected = v ?? false),
                            activeColor: primaryColor,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          const Text('Local Music library folders'),
                        ],
                      ),
                    ],
                  ),
                ),

                // [1.2] Backup Status Section
                if ((driveProvider.isUploading || driveProvider.hasUploaded) &&
                    (backupZipSelected || (musicFoldersSelected && validMusicFolders.isNotEmpty))) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // [1.2.1] Backup Status Title
                          Text(
                            'Backup Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // [1.2.2] Backup Zip Status Row
                          if (backupZipSelected)
                            Row(
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
                                  status: getFileStatus(
                                    driveProvider,
                                    lastBackupZipPath ?? '',
                                    driveProvider.fileFailed,
                                    driveProvider.skippedFiles,
                                    driveProvider.fileProgress,
                                  ),
                                ),
                              ],
                            ),

                          // [1.2.3] Music Folders Status
                          if (musicFoldersSelected)
                            ...validMusicFolders
                                .where((folderPath) => !driveProvider.unsyncedFolders.contains(folderPath))
                                .map((folderPath) {
                                  // [1.2.3.1] Music Folder Row
                                  final separator = Platform.isWindows ? '\\' : '/';
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

                                      // [1.2.3.2] File Progress Rows
                                      if (driveProvider.fileProgress.entries.any((e) => e.key.startsWith(folderPath)))
                                        Padding(
                                          padding: const EdgeInsets.only(left: 24, top: 4),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: driveProvider.fileProgress.entries
                                                .where((e) => e.key.startsWith(folderPath))
                                                .map((e) {
                                                  final fileSeparator = Platform.isWindows ? '\\' : '/';
                                                  final fileName = e.key.split(fileSeparator).last;
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
                                                          status: getFileStatus(
                                                            driveProvider,
                                                            e.key,
                                                            driveProvider.fileFailed,
                                                            driveProvider.skippedFiles,
                                                            driveProvider.fileProgress,
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
                  ),
                ],

                const SizedBox(height: 10),

                // [1.3] Action Button
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: driveProvider.isUploading
                      ? ElevatedButton.icon(
                          icon: const Icon(Iconsax.stop_circle, size: 24),
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
                            driveProvider.requestCancelBackup();
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Backup stopping...')));
                          },
                        )
                      : ElevatedButton.icon(
                          icon: Icon(Iconsax.cloud_plus, size: 24),
                          label: const Text('Backup', style: TextStyle(fontSize: 15)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor, width: 2),
                            foregroundColor: primaryColor,
                            backgroundColor: theme.colorScheme.surface,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          onPressed: (backupZipSelected || (musicFoldersSelected && validMusicFolders.isNotEmpty))
                              ? () async {
                                  final folderProvider = Provider.of<FolderProvider>(context, listen: false);
                                  final driveProvider = Provider.of<GoogleDriveProvider>(context, listen: false);
                                  String? backupZipPath;
                                  if (backupZipSelected) {
                                    // Find latest backup zip in backup folder
                                    final backupFolder = folderProvider.backupFolder?.path;
                                    if (backupFolder != null) {
                                      final dir = Directory(backupFolder);
                                      final files = dir
                                          .listSync()
                                          .whereType<File>()
                                          .where((f) => f.path.endsWith('.zip'))
                                          .toList();
                                      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
                                      if (files.isNotEmpty) {
                                        backupZipPath = files.first.path;
                                        setState(() => lastBackupZipPath = backupZipPath);
                                      }
                                    }
                                  }
                                  final musicFoldersToBackup = musicFoldersSelected
                                      ? validMusicFolders.cast<String>()
                                      : <String>[];
                                  // debugPrint(
                                  //     '[UI] About to call backupToDrive. musicFoldersSelected: '
                                  //     '$musicFoldersSelected, validMusicFolders: '
                                  //     '$validMusicFolders, musicFoldersToBackup: '
                                  //     '$musicFoldersToBackup',
                                  //   );
                                  // debugPrint(
                                  //     '[UI] FolderProvider.musicFoldersUnmodifiable: '
                                  //     '${folderProvider.musicFoldersUnmodifiable.map((f) => f.path).toList()}',
                                  //   );
                                  // debugPrint('[UI] Platform: ${Platform.operatingSystem}');
                                  await driveProvider.backupToDrive(
                                    backupZipPath: backupZipPath,
                                    musicFolders: musicFoldersToBackup,
                                    onProgress: (file, progress) {
                                      // Optionally show per-file progress
                                    },
                                  );
                                  if (driveProvider.error != null) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(SnackBar(content: Text('Backup failed:  ${driveProvider.error}')));
                                  } else {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(const SnackBar(content: Text('Backup complete!')));
                                  }
                                }
                              : null,
                        ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
