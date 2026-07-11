import 'dart:io';

// [1] Format a file size in bytes to a human-readable string (e.g., KB, MB).
String formatFileSize(int size) {
  if (size > 1024 * 1024) {
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  } else if (size > 1024) {
    return '${(size / 1024).toStringAsFixed(2)} KB';
  } else {
    return '$size B';
  }
}

// [2] Find the latest backup .zip file in the given directory path.
File? findLatestBackupFile(String? path) {
  if (path == null || path.isEmpty) return null;
  final dir = Directory(path);
  final files = dir.existsSync()
      ? dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.zip')).toList()
      : <File>[];
  if (files.isEmpty) return null;
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  final latest = files.first;
  // debugPrint('[storage_utils] Latest backup file found: ${latest.path}');
  return latest;
}
