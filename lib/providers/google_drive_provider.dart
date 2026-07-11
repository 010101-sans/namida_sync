import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../services/services.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

// [1] Provider for managing Google Drive backup and restore operations, including progress, error, and state tracking.
class GoogleDriveProvider extends ChangeNotifier {
  final GoogleDriveService driveService;
  bool _disposed = false;

  List<drive.File> files = [];
  bool isLoading = false;
  String? error;
  double uploadProgress = 0.0;
  double downloadProgress = 0.0;
  List<String> skippedFiles = [];
  List<String> uploadedFiles = [];
  Map<String, double> folderProgress = {}; // folderPath -> 0.0..1.0
  Map<String, double> fileProgress = {}; // filePath -> 0.0..1.0
  Map<String, int> folderTotalFiles = {}; // folderPath -> total files
  Map<String, int> folderUploadedFiles = {}; // folderPath -> uploaded files
  Set<String> fileFailed = {}; // filePath of failed uploads
  Set<String> unsyncedFolders = {}; // Folders skipped due to no audio files
  bool isUploading = false;
  bool hasUploaded = false;
  bool _cancelRequested = false;

  bool isRestoring = false;
  bool hasRestored = false;
  List<String> restoreSkippedFiles = [];
  List<String> restoreDownloadedFiles = [];
  Map<String, double> restoreFileProgress = {}; // filePath -> 0.0 ... 1.0
  Set<String> restoreFileFailed = {}; // filePath of failed downloads
  bool _cancelRestoreRequested = false;

  GoogleDriveProvider(this.driveService);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Helper method to check if provider is disposed
  bool get isDisposed => _disposed;

  // [2] Request cancellation of an ongoing backup operation.
  void requestCancelBackup() {
    // debugPrint('[GoogleDriveProvider] Backup cancellation requested.');
    _cancelRequested = true;
  }

  // [3] Request cancellation of an ongoing restore operation.
  void requestCancelRestore() {
    // debugPrint('[GoogleDriveProvider] Restore cancellation requested.');
    _cancelRestoreRequested = true;
  }

  // [4] Refreshes the list of files from Google Drive, optionally filtered by MIME type.
  Future<void> refreshFiles({String? mimeType}) async {
    // debugPrint('[GoogleDriveProvider] Refreshing file list from Google Drive.');
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      files = await driveService.listFiles(mimeType: mimeType);
      // debugPrint('[GoogleDriveProvider] File list refreshed.');
    } catch (e) {
      error = e.toString();
      // debugPrint('[GoogleDriveProvider] Error refreshing file list: $error');
    }
    isLoading = false;
    notifyListeners();
  }

  // [5] Upload a single file to Google Drive and track progress.
  Future<bool> uploadFile(File file, {String? mimeType}) async {
    // debugPrint('[GoogleDriveProvider] Uploading file: ${file.path}');
    uploadProgress = 0.0;
    error = null;
    notifyListeners();
    try {
      await driveService.uploadFile(
        file,
        mimeType: mimeType,
        onProgress: (p) {
          uploadProgress = p;
          notifyListeners();
        },
      );
      uploadProgress = 1.0;
      await refreshFiles();
      // debugPrint('[GoogleDriveProvider] File uploaded successfully: ${file.path}');
      return true;
    } catch (e) {
      error = e.toString();
      uploadProgress = 0.0;
      // debugPrint('[GoogleDriveProvider] Error uploading file: $error');
      notifyListeners();
      return false;
    }
  }

  // [6] Download a single file from Google Drive and track progress.
  Future<bool> downloadFile(drive.File file, File saveTo) async {
    // debugPrint('[GoogleDriveProvider] Downloading file: ${file.name}');
    downloadProgress = 0.0;
    error = null;
    notifyListeners();
    try {
      await driveService.downloadFile(
        file.id!,
        saveTo,
        onProgress: (p) {
          downloadProgress = p;
          notifyListeners();
        },
      );
      downloadProgress = 1.0;
      // debugPrint('[GoogleDriveProvider] File downloaded successfully: ${file.name}');
      return true;
    } catch (e) {
      error = e.toString();
      downloadProgress = 0.0;
      // debugPrint('[GoogleDriveProvider] Error downloading file: $error');
      notifyListeners();
      return false;
    }
  }

  // [7] Perform a full backup to Google Drive, including backup zip and music folders, and upload a manifest.
  Future<void> backupToDrive({
    String? backupZipPath,
    List<String>? musicFolders,
    void Function(String filePath, double progress)? onProgress,
    BuildContext? context,
  }) async {
    // debugPrint('[GoogleDriveProvider] Starting backup to Google Drive.');
    error = null;
    isLoading = true;
    isUploading = true;
    hasUploaded = false;
    skippedFiles.clear();
    uploadedFiles.clear();
    folderProgress.clear();
    fileProgress.clear();
    folderTotalFiles.clear();
    folderUploadedFiles.clear();
    fileFailed.clear();
    unsyncedFolders.clear();
    _cancelRequested = false;
    notifyListeners();
    try {
      final appFolderId = await driveService.ensureAppFolder(context: context);
      final backupsFolderId = await driveService.ensureSubfolder(appFolderId, 'Backups', context: context);
      final musicLibFolderId = await driveService.ensureSubfolder(appFolderId, 'MusicLibrary', context: context);
      if (backupZipPath != null && !_cancelRequested) {
        final file = File(backupZipPath);
        fileProgress[file.path] = 0.0;
        notifyListeners();
        try {
          await driveService.uploadFileOptimized(
            file,
            driveParentId: backupsFolderId,
            onProgress: (p) {},
            skippedFiles: skippedFiles,
            context: context,
          );
          fileProgress[file.path] = 1.0;
          if (!skippedFiles.contains(file.path)) uploadedFiles.add(file.path);
        } catch (e) {
          fileFailed.add(file.path);
          fileProgress[file.path] = 0.0;
        }
        notifyListeners();
      }
      // Upload music library folders to NamidaSync/MusicLiberary/
      if (musicFolders != null) {
        // debugPrint('[BACKUP] Music folders to include: $musicFolders');
        for (final folderPath in musicFolders) {
          // debugPrint('[BACKUP] Processing folder: $folderPath');
          if (_cancelRequested) break;
          final dir = Directory(folderPath);
          final parentDir = dir.parent;
          final folderName = dir.path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last;
          final allFiles = await dir.list(recursive: true, followLinks: false).where((e) => e is File).toList();
          if (allFiles.isEmpty) {
            // debugPrint('[BACKUP] Skipping folder (no files found): $folderPath');
            continue;
          }
          folderTotalFiles[folderPath] = allFiles.length;
          folderUploadedFiles[folderPath] = 0;
          folderProgress[folderPath] = 0.0;
          notifyListeners();
          //   final driveMusicFolderId = await driveService.ensureSubfolder(musicLibFolderId, folderName, context: context);
          final _ = await driveService.ensureSubfolder(musicLibFolderId, folderName, context: context);
          //   final List<String> rFelativeFiles = allFiles
          final List<String> _ = allFiles
              .map((f) => f.path.substring(parentDir.path.length).replaceAll('\\', '/').replaceAll(RegExp(r'^/'), ''))
              .toList();
          await driveService.uploadFolderOptimized(
            dir,
            driveParentId: musicLibFolderId,
            relativeTo: parentDir.path, // so the folder itself is included
            onFileStart: (filePath) {
              if (_cancelRequested) return;
              fileProgress[filePath] = 0.0;
              notifyListeners();
            },
            onFileComplete: (filePath) {
              if (_cancelRequested) return;
              fileProgress[filePath] = 1.0;
              folderUploadedFiles[folderPath] = (folderUploadedFiles[folderPath] ?? 0) + 1;
              folderProgress[folderPath] = (folderUploadedFiles[folderPath]! / (folderTotalFiles[folderPath]!));
              notifyListeners();
            },
            onFileError: (filePath) {
              if (_cancelRequested) return;
              fileFailed.add(filePath);
              fileProgress[filePath] = 0.0;
              notifyListeners();
            },
            onFolderSkipped: (folderPath) {
              if (_cancelRequested) return;
              unsyncedFolders.add(folderPath);
              notifyListeners();
            },
            skippedFiles: skippedFiles,
            uploadedFiles: uploadedFiles,
            context: context,
          );
        }
      }
      // Write and upload SyncManifest to /NamidaSync/Manifests/
      try {
        final now = DateTime.now();
        final deviceId = Platform.localHostname;
        final syncFolders = <SyncFolder>[];
        if (musicFolders != null) {
          for (final folderPath in musicFolders) {
            final dir = Directory(folderPath);
            final folderName = dir.path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last;
            final allFiles = await dir.list(recursive: true, followLinks: false).where((e) => e is File).toList();
            final files = <SyncFile>[];
            for (final fileEntity in allFiles) {
              final file = fileEntity as File;
              final stat = await file.stat();
              final relPath = file.path
                  .substring(dir.parent.path.length)
                  .replaceAll('\\', '/')
                  .replaceAll(RegExp(r'^/'), '');
              files.add(SyncFile(name: relPath, size: stat.size, lastModified: stat.modified));
            }
            syncFolders.add(
              SyncFolder(
                label: folderName,
                originalPath: dir.path,
                relativePath: folderName,
                platform: Platform.operatingSystem,
                files: files,
              ),
            );
          }
        }
        SyncBackupZip? syncBackupZip;
        if (backupZipPath != null) {
          final zipFile = File(backupZipPath);
          if (await zipFile.exists()) {
            final stat = await zipFile.stat();
            syncBackupZip = SyncBackupZip(
              name: zipFile.uri.pathSegments.last,
              size: stat.size,
              lastModified: stat.modified,
            );
          }
        }
        if (syncBackupZip != null) {
          final syncManifest = SyncManifest(
            manifestVersion: 2,
            type: 'backup',
            timestamp: now,
            deviceId: deviceId,
            platform: Platform.operatingSystem,
            folders: syncFolders,
            backupZip: syncBackupZip,
          );
          final syncManifestJson = syncManifest.toJsonString();
          final manifestFileName =
              'manifest_${now.toIso8601String().replaceAll(':', '-')}_${Platform.operatingSystem}_$deviceId.json';
          final syncManifestFile = File('${Directory.systemTemp.path}/$manifestFileName');
          await syncManifestFile.writeAsString(syncManifestJson);
          final appFolderId = await driveService.ensureAppFolder(context: context);
          final manifestsFolderId = await driveService.ensureSubfolder(appFolderId, 'Manifests', context: context);
          await driveService.uploadFileOptimized(
            syncManifestFile,
            driveParentId: manifestsFolderId,
            mimeType: 'application/json',
            skippedFiles: skippedFiles,
            context: context,
          );
        }
      } catch (e) {
        // debugPrint('Warning: Failed to write/upload SyncManifest: $e');
      }
      uploadProgress = 1.0;
      await refreshFiles();
      hasUploaded = true;
      // debugPrint('[GoogleDriveProvider] Backup completed successfully.');
    } catch (e) {
      error = e.toString();
      uploadProgress = 0.0;
      hasUploaded = true;
      // debugPrint('[GoogleDriveProvider] Error during backup: $error');
    }
    isUploading = false;
    isLoading = false;
    notifyListeners();
  }

  // [8] Retry uploading a failed file.
  Future<void> retryFileUpload(String filePath, String driveParentId) async {
    // debugPrint('[GoogleDriveProvider] Retrying upload for file: $filePath');
    fileFailed.remove(filePath);
    fileProgress[filePath] = 0.0;
    notifyListeners();
    try {
      final file = File(filePath);
      await driveService.uploadFileOptimized(
        file,
        driveParentId: driveParentId,
        onProgress: (p) {},
        skippedFiles: skippedFiles,
      );
      fileProgress[filePath] = 1.0;
      uploadedFiles.add(filePath);
      // debugPrint('[GoogleDriveProvider] File upload retried successfully: $filePath');
    } catch (e) {
      fileFailed.add(filePath);
      fileProgress[filePath] = 0.0;
      // debugPrint('[GoogleDriveProvider] Error retrying file upload: $filePath');
    }
    notifyListeners();
  }

  // [9] Returns the overall restore progress as a value between 0.0 and 1.0
  double get overallRestoreProgress {
    final total = restoreFileProgress.length;
    if (total == 0) return 0.0;
    final completed = restoreFileProgress.values.where((v) => v == 1.0).length;
    return completed / total;
  }

  // [10] Restore from Google Drive using the manifest, with options for backup zip and music library.
  // IMPORTANT: This method NEVER deletes any user data on the target device during restore.
  // It only adds or overwrites files as needed, and skips files that already exist if not overwriting.
  // No files or folders are ever deleted from the local filesystem during restore.
  Future<void> restoreFromDrive({
    required bool restoreZip,
    required bool restoreMusicFolders,
    required BuildContext context,
    required FolderProvider folderProvider,
    void Function(String filePath, double progress)? onProgress,
  }) async {
    // debugPrint('[GoogleDriveProvider] Starting restore from Google Drive.');
    error = null;
    isLoading = true;
    isRestoring = true;
    hasRestored = false;
    restoreSkippedFiles.clear();
    restoreDownloadedFiles.clear();
    restoreFileProgress.clear();
    restoreFileFailed.clear();
    _cancelRestoreRequested = false;
    notifyListeners();
    try {
      // Find and use the latest SyncManifest from /NamidaSync/Manifests/ ---
      final manifestTemp = File('${Directory.systemTemp.path}/latest_sync_manifest.json');
      final manifestFiles = await driveService.listSyncManifests(context: context);
      if (manifestFiles.isEmpty) {
        error = 'No backup manifest found in Drive.';
        isLoading = false;
        isRestoring = false;
        notifyListeners();
        return;
      }
      final latestManifestFile = manifestFiles.first;
      final downloadedManifest = await driveService.downloadSyncManifest(
        latestManifestFile.name ?? '',
        manifestTemp,
        context: context,
      );
      if (downloadedManifest == null || !await downloadedManifest.exists()) {
        error = 'Failed to download the latest backup manifest.';
        isLoading = false;
        isRestoring = false;
        notifyListeners();
        return;
      }
      // Print the raw manifest JSON for debugging
      final rawManifestJson = await downloadedManifest.readAsString();
      // debugPrint('[RESTORE] Raw manifest JSON: $rawManifestJson');
      SyncManifest? syncManifest;
      try {
        syncManifest = SyncManifest.fromJsonString(rawManifestJson);
      } catch (e) {
        // debugPrint('[RESTORE] Error parsing manifest: $e');
        error = 'Failed to parse backup manifest.';
        isLoading = false;
        isRestoring = false;
        notifyListeners();
        return;
      }
      // debugPrint('[RESTORE] Folders in manifest: ${syncManifest.folders.map((f) => f.label).toList()}');

      // Now use syncManifest for restore logic (restoreZip, restoreMusicFolders, etc.)
      // Restore backup zip if selected
      if (restoreZip && !_cancelRestoreRequested) {
        String restoreZipPath = folderProvider.backupFolder?.path ?? '';
        if (restoreZipPath.isEmpty) {
          // Prompt user for folder
          final result = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select folder to restore backup zip');
          if (result == null) {
            error = 'Restore cancelled (no folder selected).';
            isLoading = false;
            isRestoring = false;
            notifyListeners();
            return;
          }
          restoreZipPath = result;
        }
        final appFolderId = await driveService.ensureAppFolder(context: context);
        final backupsFolderId = await driveService.ensureSubfolder(appFolderId, 'Backups', context: context);
        final driveApi = await driveService.getDriveClient();
        final zipName = syncManifest.backupZip.name;
        final q = "'$backupsFolderId' in parents and name = '$zipName' and trashed = false";
        final files = await driveApi.files.list(q: q, orderBy: 'modifiedTime desc', spaces: 'drive');
        if (files.files == null || files.files!.isEmpty) {
          error = 'No backup zip found in Drive.';
          isLoading = false;
          isRestoring = false;
          notifyListeners();
          return;
        }
        final zipFile = files.files!.first;
        if (zipFile.id == null || zipFile.name == null) {
          error = 'Invalid backup zip in Drive.';
          isLoading = false;
          isRestoring = false;
          notifyListeners();
          return;
        }
        final localZip = File('$restoreZipPath/${zipFile.name}');
        final normalizedZipPath = normalizePath(localZip.path);
        // debugPrint('[RESTORE] Backup zip normalized path: $normalizedZipPath');
        if (await localZip.exists()) {
          restoreSkippedFiles.add(normalizedZipPath);
          restoreFileProgress[normalizedZipPath] = 1.0;
          // debugPrint('[RESTORE] Skipped zip: $normalizedZipPath');
          // debugPrint('[RESTORE] restoreFileProgress: \n$restoreFileProgress');
          // debugPrint('[RESTORE] restoreSkippedFiles: $restoreSkippedFiles');
          notifyListeners();
        } else {
          restoreFileProgress[normalizedZipPath] = 0.0;
          // debugPrint('[RESTORE] Start restoring zip: $normalizedZipPath');
          notifyListeners();
          try {
            await driveService.downloadFile(
              zipFile.id!,
              localZip,
              onProgress: (p) {
                restoreFileProgress[normalizedZipPath] = p;
                // debugPrint('[RESTORE] Downloading zip: $normalizedZipPath, progress: $p');
                if (onProgress != null) onProgress(normalizedZipPath, p);
                notifyListeners();
              },
            );
            restoreFileProgress[normalizedZipPath] = 1.0;
            restoreDownloadedFiles.add(normalizedZipPath);
            // debugPrint('[RESTORE] Downloaded zip: $normalizedZipPath');
          } catch (e) {
            restoreFileFailed.add(normalizedZipPath);
            restoreFileProgress[normalizedZipPath] = 0.0;
            // debugPrint('[RESTORE] Failed zip: $normalizedZipPath');
          }
          // debugPrint('[RESTORE] restoreFileProgress: \n$restoreFileProgress');
          // debugPrint('[RESTORE] restoreFileFailed: $restoreFileFailed');
          // debugPrint('[RESTORE] restoreDownloadedFiles: $restoreDownloadedFiles');
          notifyListeners();
        }
      }
      // Restore music library if selected
      if (restoreMusicFolders && !_cancelRestoreRequested) {
        final appFolderId = await driveService.ensureAppFolder(context: context);
        final musicLibFolderId = await driveService.ensureSubfolder(appFolderId, 'MusicLibrary', context: context);
        // Print folders in manifest
        // debugPrint('[RESTORE] Folders in manifest: \n${syncManifest.folders.map((f) => f.label).toList()}');
        // On Android, check permissions before restore
        if (Platform.isAndroid) {
          final granted = await PermissionsUtil.hasStoragePermission();
          // debugPrint('[RESTORE] Android storage permission granted: $granted');
          if (!granted) {
            final requested = await PermissionsUtil.requestStoragePermission();
            // debugPrint('[RESTORE] Android storage permission requested, result: $requested');
            if (!requested) {
              error = 'Storage permission is required to restore files.';
              isLoading = false;
              isRestoring = false;
              notifyListeners();
              return;
            }
          }
        }

        // Build normalized music folder list for comparison
        final normalizedMusicFolders = folderProvider.musicFoldersUnmodifiable
            .map((f) => f.path.replaceAll('\\', '/'))
            .toList();
        for (final entry in syncManifest.folders) {
          if (_cancelRestoreRequested) break;
          // debugPrint(
          // '[RESTORE] Folder entry: label= {entry.label}, originalPath= {entry.originalPath}, relativePath= {entry.relativePath}, platform= {entry.platform}',
          //   );
          // debugPrint('[RESTORE] Files:  {entry.files.map((f) => f.name).toList()}');
          // debugPrint('[RESTORE] Restoring folder:  {entry.label}');
          // debugPrint('[RESTORE] Files in folder:  {entry.files.map((f) => f.name).toList()}');

          // Check if folder is already in music library
          MusicFolderInfo? existingFolder;
          try {
            existingFolder = folderProvider.musicFoldersUnmodifiable.firstWhere((f) => f.name == entry.label);
          } catch (_) {
            existingFolder = null;
          }

          String? chosenPath;
          if (existingFolder != null) {
            // Restore directly to the existing folder location
            chosenPath = existingFolder.path;
          } else {
            // Show dialog with two options:
            // (1) Pick the folder's location on device if it exists
            // (2) Select a parent folder to restore the new folder as a sub-folder
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Restore "${entry.label}"'),
                content: Text('Where do you want to restore this folder?'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // Pick the folder's location on device if it exists
                      final picked = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: 'Pick location of ${entry.label} on your device',
                      );
                      if (picked != null && picked.isNotEmpty) {
                        chosenPath = picked; // Use as-is
                      }
                      Navigator.of(ctx).pop();
                    },
                    child: Text('Pick Existing Folder Location'),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Select a parent folder to restore the new folder as a child
                      final parent = await FilePicker.platform.getDirectoryPath(
                        dialogTitle: 'Select parent folder for ${entry.label}',
                      );
                      if (parent != null && parent.isNotEmpty) {
                        chosenPath = parent + Platform.pathSeparator + entry.label; // Always append folder name
                      }
                      Navigator.of(ctx).pop();
                    },
                    child: Text('Restore as sub-folder of Chosen Folder'),
                  ),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ],
              ),
            );
          }

          if (chosenPath == null || chosenPath!.isEmpty) {
            unsyncedFolders.add(entry.label);
            continue;
          }

          final restorePath = chosenPath!;
          final isDirectFolder = p.basename(restorePath) == entry.label;
          if (existingFolder == null) {
            await folderProvider.addMusicFolder(restorePath);
            normalizedMusicFolders.add(restorePath.replaceAll('\\', '/'));
          }

          folderTotalFiles[restorePath] = entry.files.length;
          folderUploadedFiles[restorePath] = 0;
          folderProgress[restorePath] = 0.0;
          notifyListeners();
          await driveService.downloadFilesFromManifest(
            driveParentId: musicLibFolderId,
            manifestFiles: entry.files.map((f) => f.name).toList(),
            localRoot: Directory(restorePath),
            stripRoot: isDirectFolder,
            onProgress: (filePath, p) {
              final normalizedPath = filePath.replaceAll('\\', '/');
              // debugPrint('[RESTORE] onProgress: $normalizedPath, $p');
              restoreFileProgress[normalizedPath] = p;
              if (onProgress != null) onProgress(normalizedPath, p);
              notifyListeners();
            },
            onFileComplete: (filePath) {
              final normalizedPath = filePath.replaceAll('\\', '/');
              // debugPrint('[RESTORE] onFileComplete: $normalizedPath');
              restoreFileProgress[normalizedPath] = 1.0;
              folderUploadedFiles[restorePath] = (folderUploadedFiles[restorePath] ?? 0) + 1;
              folderProgress[restorePath] = (folderUploadedFiles[restorePath]! / (folderTotalFiles[restorePath]!));
              restoreDownloadedFiles.add(normalizedPath);
              notifyListeners();
            },
            onFileError: (filePath) {
              final normalizedPath = filePath.replaceAll('\\', '/');
              // debugPrint('[RESTORE] onFileError: $normalizedPath');
              restoreFileFailed.add(normalizedPath);
              restoreFileProgress[normalizedPath] = 0.0;
              notifyListeners();
            },
            onFileSkipped: (filePath) {
              final normalizedPath = filePath.replaceAll('\\', '/');
              // debugPrint('[RESTORE] onFileSkipped: $normalizedPath');
              restoreSkippedFiles.add(normalizedPath);
              restoreFileProgress[normalizedPath] = 1.0;
              notifyListeners();
            },
            context: context,
          );
        }
      }
      hasRestored = true;
      // debugPrint('[GoogleDriveProvider] Restore completed successfully.');
    } catch (e) {
      error = e.toString();
      hasRestored = true;
      // debugPrint('[GoogleDriveProvider] Error during restore: $error');
    }
    isRestoring = false;
    isLoading = false;
    notifyListeners();
  }

  // [11] Clear the current error state and notify listeners.
  void clearError() {
    // debugPrint('[GoogleDriveProvider] Clearing error state.');
    error = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
