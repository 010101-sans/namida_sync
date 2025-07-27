import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/providers.dart';
import '../../widgets/custom_card.dart';
import '../../utils/utils.dart';

class BackupFolderCard extends StatelessWidget {
  final FolderProvider folderProvider;
  final bool noBackupFile;
  final String? latestBackupName;
  final String? latestBackupSize;
  final VoidCallback onEditBackupFolder;
  final VoidCallback onRefresh;

  const BackupFolderCard({
    super.key,
    required this.folderProvider,
    required this.noBackupFile,
    required this.latestBackupName,
    required this.latestBackupSize,
    required this.onEditBackupFolder,
    required this.onRefresh,
  });

  String? formatBackupDate(String backupName) {
    // Extracts and formats the backup date from the backup file name.
    // Matches both formats:
    // (1) Manually created backup : "Namida Backup - 2025-07-17 12.56.58.zip"
    // (2) Automatically created backup : "Namida Backup - 2025-07-17 12.56.58 - auto.zip"
    final regex = RegExp(r'Namida Backup - (\d{4}-\d{2}-\d{2} \d{2}\.\d{2}\.\d{2})');
    final match = regex.firstMatch(backupName);
    if (match != null) {
      final dateStr = match.group(1)!; // e.g. "2025-07-17 12.56.58"
      try {
        final date = DateFormat('yyyy-MM-dd HH.mm.ss').parse(dateStr);
        // Format: "January 20th, 2025 | 07:55"
        final day = date.day;
        String daySuffix;
        if (day >= 11 && day <= 13) {
          daySuffix = 'th';
        } else {
          switch (day % 10) {
            case 1:
              daySuffix = 'st';
              break;
            case 2:
              daySuffix = 'nd';
              break;
            case 3:
              daySuffix = 'rd';
              break;
            default:
              daySuffix = 'th';
          }
        }
        final formattedDate = DateFormat("MMMM d'$daySuffix', yyyy | HH:mm").format(date);
        return 'Latest Backup - $formattedDate';
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard(
      leadingIcon: Iconsax.folder_open,
      title: 'Backup Folder',
      headerActions: [

        // [1] Refresh Button
        IconButton(
          icon: Icon(Iconsax.refresh, color: colorScheme.primary, size: 22),
          tooltip: 'Refresh',
          onPressed: onRefresh,
        ),

        // [2] Edit Backup Folder Button
        IconButton(
          icon: Icon(Iconsax.edit, color: colorScheme.primary, size: 22),
          tooltip: 'Edit Backup Folder',
          onPressed: folderProvider.isLoading ? null : onEditBackupFolder,
        ),
      ],
      body: Padding(
        padding: Platform.isWindows
            ? const EdgeInsets.only(left: 32, right: 32, bottom: 28, top: 25)
            : const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // [3] Folder Path Row
            if (folderProvider.backupFolder?.path != null && folderProvider.backupFolder!.path.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    
                  // [3.1] Folder Path Container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Text(
                        Platform.isAndroid
                            ? folderProvider.backupFolder!.path.replaceFirst('/storage/emulated/0/', 'Internal Memory/')
                            : folderProvider.backupFolder!.path,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontFamily: Platform.isWindows ? 'monospace' : null,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),

            // [4] No folder selected message
            if (folderProvider.backupFolder?.path == null || folderProvider.backupFolder!.path.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  children: [
                    
                    // [4.1] Error Icon
                    Icon(Iconsax.close_circle, size: 16, color: AppColors.warningOrange),
                    const SizedBox(width: 8),

                    // [4.2] Error Message
                    Expanded(
                      child: Text(
                        'No backup folder selected. Please select a folder to continue.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warningOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // [5] Backup file info
            if (latestBackupName != null && latestBackupSize != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // [5.1] Backup Date
                    Text(
                      formatBackupDate(latestBackupName!) ?? latestBackupName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.light ? Colors.black : AppColors.successGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // [5.2] Backup Size
                    Text(
                      latestBackupSize!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.light ? Colors.black : AppColors.successGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
