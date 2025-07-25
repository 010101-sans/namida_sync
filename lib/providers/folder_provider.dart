import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/folder_service.dart';
import '../utils/helper_methods.dart';

// [1] Model for representing a music folder's path, status, and loading state.
class MusicFolderInfo {
  final String path;
  final FolderStatus status;
  final bool isLoading;
  MusicFolderInfo({required this.path, this.status = FolderStatus.unknown, this.isLoading = false});
  MusicFolderInfo copyWith({String? path, FolderStatus? status, bool? isLoading}) {
    return MusicFolderInfo(
      path: path ?? this.path,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String get name {
    return path.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty).last;
  }
}

// [2] Provider for managing backup and music folder state, including validation and persistence.
class FolderProvider extends ChangeNotifier {
  FolderInfo? backupFolder;
  List<MusicFolderInfo> musicFolders = [];
  bool isLoading = false;

  List<MusicFolderInfo> get musicFoldersUnmodifiable => List.unmodifiable(musicFolders);

  // [3] Loads backup and music folders from storage and validates them.
  Future<void> loadFolders() async {
    isLoading = true;
    // debugPrint('[FolderProvider] Loading backup and music folders from storage.');
    notifyListeners();
    final backupPath = await FolderService.loadBackupFolder();
    final musicPaths = await FolderService.loadMusicFolders();
    backupFolder = backupPath != null
        ? FolderInfo(path: backupPath, type: FolderType.backup)
        : FolderInfo(path: FolderService.getDefaultBackupFolder(), type: FolderType.backup);
    musicFolders = musicPaths.isNotEmpty ? musicPaths.map((p) => MusicFolderInfo(path: p)).toList() : [];
    await validateAll();
    isLoading = false;
    // debugPrint('[FolderProvider] Folders loaded and validated.');
    notifyListeners();
  }

  // [4] Validates all folders and updates their status.
  Future<void> validateAll() async {
    // debugPrint('[FolderProvider] Validating backup and music folders.');
    if (backupFolder != null) {
      final valid = await FolderService.validateFolder(backupFolder!.path, isBackup: true);
      backupFolder = backupFolder!.copyWith(status: valid ? FolderStatus.valid : FolderStatus.invalid);
    }
    for (int i = 0; i < musicFolders.length; i++) {
      final valid = await FolderService.validateFolder(musicFolders[i].path);
      musicFolders[i] = musicFolders[i].copyWith(status: valid ? FolderStatus.valid : FolderStatus.invalid);
    }
    // debugPrint('[FolderProvider] Validation complete.');
    notifyListeners();
  }

  // [5] Updates the backup folder and persists it.
  Future<void> setBackupFolder(String path) async {
    isLoading = true;
    // debugPrint('[FolderProvider] Setting backup folder: $path');
    notifyListeners();
    final normalizedPath = normalizePath(path);
    backupFolder = FolderInfo(path: normalizedPath, type: FolderType.backup);
    await FolderService.saveBackupFolder(normalizedPath);
    await validateAll();
    isLoading = false;
    // debugPrint('[FolderProvider] Backup folder set and validated.');
    notifyListeners();
  }

  // [6] Adds a music folder and persists the list.
  Future<void> addMusicFolder(String path) async {
    // debugPrint('[FolderProvider] Adding music folder: $path');
    final normalizedPath = normalizePath(path);
    musicFolders.add(MusicFolderInfo(path: normalizedPath, isLoading: true));
    notifyListeners();
    final idx = musicFolders.length - 1;
    await FolderService.saveMusicFolders(musicFolders.map((f) => f.path).toList());
    await validateMusicFolder(idx);
    musicFolders[idx] = musicFolders[idx].copyWith(isLoading: false);
    // debugPrint('[FolderProvider] Music folder added and validated: $normalizedPath');
    notifyListeners();
  }

  // [7] Updates a music folder at a specific index.
  Future<void> updateMusicFolder(int index, String newPath) async {
    if (index >= 0 && index < musicFolders.length) {
      // debugPrint('[FolderProvider] Updating music folder at index $index to new path: $newPath');
      final normalizedPath = normalizePath(newPath);
      musicFolders[index] = musicFolders[index].copyWith(isLoading: true);
      notifyListeners();
      musicFolders[index] = MusicFolderInfo(path: normalizedPath, isLoading: true);
      await FolderService.saveMusicFolders(musicFolders.map((f) => f.path).toList());
      await validateMusicFolder(index);
      musicFolders[index] = musicFolders[index].copyWith(isLoading: false);
      // debugPrint('[FolderProvider] Music folder updated and validated at index $index.');
      notifyListeners();
    }
  }

  // [8] Removes a music folder at a specific index and persists the list.
  Future<void> removeMusicFolder(int index) async {
    if (index >= 0 && index < musicFolders.length) {
      // debugPrint('[FolderProvider] Removing music folder at index $index: ${musicFolders[index].path}');
      musicFolders[index] = musicFolders[index].copyWith(isLoading: true);
      notifyListeners();
      musicFolders.removeAt(index);
      await FolderService.saveMusicFolders(musicFolders.map((f) => f.path).toList());
      // debugPrint('[FolderProvider] Music folder removed at index $index.');
      notifyListeners();
    }
  }

  // [9] Validates a single music folder at the given index.
  Future<void> validateMusicFolder(int index) async {
    if (index >= 0 && index < musicFolders.length) {
      // debugPrint('[FolderProvider] Validating music folder at index $index: ${musicFolders[index].path}');
      final valid = await FolderService.validateFolder(musicFolders[index].path);
      musicFolders[index] = musicFolders[index].copyWith(status: valid ? FolderStatus.valid : FolderStatus.invalid);
      // debugPrint('[FolderProvider] Validation result for index $index: ${musicFolders[index].status}');
    }
  }

  // [10] Replaces all music folders with the provided list and persists them.
  Future<void> setMusicFolders(List<String> paths) async {
    isLoading = true;
    notifyListeners();
    final normalizedPaths = paths.map((p) => normalizePath(p)).toList();
    musicFolders = normalizedPaths.map((p) => MusicFolderInfo(path: p, isLoading: true)).toList();
    await FolderService.saveMusicFolders(normalizedPaths);
    await validateAll();
    isLoading = false;
    notifyListeners();
  }

  // [11] Public method to refresh the music folder list and their statuses.
  Future<void> refreshFolderList() async {
    // debugPrint('[FolderProvider] Refreshing folder list.');
    await loadFolders();
  }
}
