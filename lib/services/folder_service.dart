import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class FolderService {
  static const String backupFolderKey = 'backup_folder_path';
  static const String musicFoldersKey = 'music_folders_paths';

  // [1] Detects the default Namida backup folder path based on platform.
  static String getDefaultBackupFolder() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Namida/Backups';
    } else if (Platform.isWindows) {
      return 'C:/Namida/Backups';
    }
    return '';
  }

  // [2] Detects the default Namida music library folder path(s) based on platform.
  static List<String> getDefaultMusicFolders() {
    if (Platform.isAndroid) {
      return ['/storage/emulated/0/Music'];
    } else if (Platform.isWindows) {
      final user = Platform.environment['USERNAME'] ?? 'User';
      return ['C:/Users/$user/Music/Namida'];
    }
    return [];
  }

  // [3] Validates if the folder exists and contains required files (backup zip or .mp3).
  static Future<bool> validateFolder(String path, {bool isBackup = false}) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      // debugPrint('[FolderService] Directory does not exist: $path');
      return false;
    }
    if (isBackup) {
      final files = dir.listSync();
      final hasZip = files.any((f) => f.path.endsWith('.zip'));
      // debugPrint('[FolderService] Backup folder validation for $path: ${hasZip ? 'Valid' : 'No .zip found'}');
      return hasZip;
    } else {
      // Recursively check for .mp3 files in all subdirectories
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
            // debugPrint('[FolderService] Found .mp3 file in $path');
            return true;
          }
        }
      } catch (e) {
        // debugPrint('[FolderService] Error while validating music folder: $e');
        return false;
      }
      // debugPrint('[FolderService] No .mp3 files found in $path');
      return false;
    }
  }

  // [4] Saves the user-selected backup folder path.
  static Future<void> saveBackupFolder(String path) async {
    // debugPrint('[FolderService] Saving backup folder path: $path');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(backupFolderKey, path);
  }

  // [5] Loads the user-selected backup folder path.
  static Future<String?> loadBackupFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(backupFolderKey);
    // debugPrint('[FolderService] Loaded backup folder path: $path');
    return path;
  }

  // [6] Saves the user-selected music library folder paths.
  static Future<void> saveMusicFolders(List<String> paths) async {
    // debugPrint('[FolderService] Saving music folder paths: $paths');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(musicFoldersKey, paths);
  }

  // [7] Loads the user-selected music library folder paths.
  static Future<List<String>> loadMusicFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList(musicFoldersKey) ?? [];
    // debugPrint('[FolderService] Loaded music folder paths: $paths');
    return paths;
  }
}
