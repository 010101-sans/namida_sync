import 'package:flutter/material.dart';
import '../providers/providers.dart';
import 'package:iconsax/iconsax.dart';

// [1] Status label widget for file/folder upload/download status
Widget buildStatusLabel(BuildContext context, {required String status}) {
  Color color;
  IconData icon;
  switch (status) {
    case 'Uploaded':
      color = Colors.green;
      icon = Iconsax.tick_circle;
      break;
    case 'Uploading':
      color = Theme.of(context).colorScheme.primary;
      icon = Iconsax.cloud_plus;
      break;
    case 'Skipped':
      color = Colors.orange;
      icon = Iconsax.next;
      break;
    case 'Failed':
      color = Colors.red;
      icon = Iconsax.close_circle;
      break;
    default:
      color = Colors.blueGrey;
      icon = Iconsax.info_circle;
  }
  return Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(
        status,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

// [2] Get the status string for a file during upload
String getFileStatus(
  GoogleDriveProvider driveProvider,
  String filePath,
  Set<String> fileFailed,
  List<String> skippedFiles,
  Map<String, double> fileProgress,
) {
  if (fileFailed.contains(filePath)) return 'Failed';
  if (skippedFiles.contains(filePath)) return 'Skipped';
  if (fileProgress[filePath] == 1.0) return 'Uploaded';
  if (fileProgress[filePath] != null && fileProgress[filePath]! < 1.0) return 'Uploading';
  return 'Pending';
}

// [3] Get the status string for a file during restore
String getRestoreFileStatus(
  GoogleDriveProvider driveProvider,
  String filePath,
  Set<String> fileFailed,
  List<String> skippedFiles,
  Map<String, double> fileProgress,
) {
  if (fileFailed.contains(filePath)) return 'Failed';
  if (skippedFiles.contains(filePath)) return 'Skipped';
  if (fileProgress[filePath] == 1.0) return 'Downloaded';
  if (fileProgress[filePath] != null && fileProgress[filePath]! < 1.0) return 'Downloading';
  return 'Pending';
}

// [4] Normalize file/folder paths for consistent comparison
String normalizePath(String path) {
  var n = path.replaceAll('\\', '/');
  if (n.length > 2 && n[1] == ':') {
    n = n[0].toLowerCase() + n.substring(1);
  }
  if (n.endsWith('/')) n = n.substring(0, n.length - 1);
  return n;
}
