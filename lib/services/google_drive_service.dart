import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'google_auth_service.dart';
import 'package:flutter/material.dart';

class GoogleDriveService {
  final GoogleAuthService authService;
  String? _appFolderId;

  GoogleDriveService(this.authService);

  // [1] Helper to retry on 401 errors by refreshing token and optionally showing a snackbar.
  Future<T> withAuthRetry<T>(Future<T> Function() action, {BuildContext? context}) async {
    try {
      return await action();
    } catch (e) {
      if (e.toString().contains('401')) {
        // debugPrint('[GoogleDriveService] 401 error, attempting token refresh.');
        await authService.signIn(); // silent sign-in/token refresh
        try {
          return await action();
        } catch (e2) {
          if (e2.toString().contains('401')) {
            // debugPrint('[GoogleDriveService] 401 after retry, signing out.');
            await authService.signOut();
            if (context != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Session expired. Please sign in again.')));
            }
            throw Exception('Authentication required. Please sign in again.');
          }
          rethrow;
        }
      }
      rethrow;
    }
  }

  // [2] Get an authenticated Drive API client.
  Future<drive.DriveApi> getDriveClient({bool forceRefresh = false}) async {
    // debugPrint('[GoogleDriveService] Getting Drive API client.');
    final headers = await authService.getAuthHeaders();
    if (headers == null) throw Exception('Not authenticated');
    final client = _GoogleAuthClient(headers);
    return drive.DriveApi(client);
  }

  // [3] Ensure the NamidaSync app folder exists in Drive and return its ID.
  Future<String> ensureAppFolder({BuildContext? context}) async {
    if (_appFolderId != null) return _appFolderId!;
    // debugPrint('[GoogleDriveService] Ensuring NamidaSync app folder exists.');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final q = "mimeType = 'application/vnd.google-apps.folder' and name = 'NamidaSync' and trashed = false";
      final folders = await api.files.list(q: q, spaces: 'drive');
      if (folders.files != null && folders.files!.isNotEmpty) {
        _appFolderId = folders.files!.first.id;
        return _appFolderId!;
      }
      final folder = drive.File()
        ..name = 'NamidaSync'
        ..mimeType = 'application/vnd.google-apps.folder';
      final created = await api.files.create(folder);
      _appFolderId = created.id;
      return _appFolderId!;
    }, context: context);
  }

  // [4] Ensure a subfolder exists in Drive and return its ID.
  Future<String> ensureSubfolder(String parentId, String name, {BuildContext? context}) async {
    // debugPrint('[GoogleDriveService] Ensuring subfolder "$name" exists under parent $parentId.');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final q =
          "'$parentId' in parents and name = '$name' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final folders = await api.files.list(q: q, spaces: 'drive');
      if (folders.files != null && folders.files!.isNotEmpty) {
        return folders.files!.first.id!;
      } else {
        final folderMeta = drive.File()
          ..name = name
          ..parents = [parentId]
          ..mimeType = 'application/vnd.google-apps.folder';
        final created = await api.files.create(folderMeta);
        return created.id!;
      }
    }, context: context);
  }

  // [5] Check if a file should be uploaded (not already present in Drive).
  Future<bool> shouldUploadFile(File localFile, String driveParentId, {BuildContext? context}) async {
    // debugPrint('[GoogleDriveService] Checking if file should be uploaded: ${localFile.path}');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final q = "'$driveParentId' in parents and name = '${localFile.uri.pathSegments.last}' and trashed = false";
      final files = await api.files.list(q: q, spaces: 'drive', $fields: 'files(id)');
      if (files.files != null && files.files!.isNotEmpty) {
        // debugPrint('[GoogleDriveService] File already exists in Drive, skipping upload: ${localFile.path}');
        return false;
      }
      return true; // Upload if not present
    }, context: context);
  }

  // [6] Upload a file to Drive, skipping if already present.
  Future<drive.File?> uploadFileOptimized(
    File file, {
    required String driveParentId,
    String? mimeType,
    void Function(double)? onProgress,
    List<String>? skippedFiles,
    BuildContext? context,
  }) async {
    // debugPrint('[GoogleDriveService] Uploading file (optimized): ${file.path}');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final shouldUpload = await shouldUploadFile(file, driveParentId, context: context);
      if (!shouldUpload) {
        skippedFiles?.add(file.path);
        // debugPrint('[GoogleDriveService] Skipped upload (already exists): ${file.path}');
        return null;
      }
      final media = drive.Media(file.openRead(), file.lengthSync());
      final driveFile = drive.File()
        ..name = file.uri.pathSegments.last
        ..parents = [driveParentId]
        ..mimeType = mimeType;
      return await api.files.create(driveFile, uploadMedia: media);
    }, context: context);
  }

  // [7] List files in the NamidaSync app folder, optionally filtered by MIME type.
  Future<List<drive.File>> listFiles({String? mimeType, BuildContext? context}) async {
    // debugPrint('[GoogleDriveService] Listing files in NamidaSync app folder.');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final folderId = await ensureAppFolder(context: context);
      final q = "'$folderId' in parents and trashed = false ${(mimeType != null ? " and mimeType = '$mimeType'" : '')}";
      final files = await api.files.list(q: q, spaces: 'drive');
      return files.files ?? [];
    }, context: context);
  }

  // [8] Upload a file to the NamidaSync app folder.
  Future<drive.File> uploadFile(
    File file, {
    String? mimeType,
    void Function(double)? onProgress,
    BuildContext? context,
  }) async {
    // debugPrint('[GoogleDriveService] Uploading file to NamidaSync app folder: ${file.path}');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final folderId = await ensureAppFolder(context: context);
      final media = drive.Media(file.openRead(), file.lengthSync());
      final driveFile = drive.File()
        ..name = file.uri.pathSegments.last
        ..parents = [folderId]
        ..mimeType = mimeType;
      return await api.files.create(driveFile, uploadMedia: media);
    }, context: context);
  }

  // [9] Download a file from Drive to a local file.
  Future<void> downloadFile(
    String fileId,
    File saveTo, {
    void Function(double)? onProgress,
    BuildContext? context,
  }) async {
    // debugPrint('[GoogleDriveService] Downloading file from Drive: $fileId to ${saveTo.path}');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final media = await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final sink = saveTo.openWrite();
      await media.stream.pipe(sink);
      await sink.close();
    }, context: context);
  }

  // [10] Finds and downloads the latest backup_manifest.json from the MusicLibrary folder in Drive.
  Future<File?> downloadLatestManifest(File saveTo, {BuildContext? context}) async {
    // debugPrint('[GoogleDriveService] Downloading latest backup_manifest.json.');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final appFolderId = await ensureAppFolder(context: context);
      final musicLibFolderId = await ensureSubfolder(appFolderId, 'MusicLibrary', context: context);
      // Find the latest manifest file
      final q =
          "'$musicLibFolderId' in parents and name = 'backup_manifest.json' and trashed = false and mimeType = 'application/json'";
      final files = await api.files.list(q: q, orderBy: 'modifiedTime desc', spaces: 'drive');
      if (files.files == null || files.files!.isEmpty) return null;
      final manifestFile = files.files!.first;
      if (manifestFile.id == null) return null;
      // Download to saveTo
      if (await saveTo.exists()) await saveTo.delete();
      await downloadFile(manifestFile.id!, saveTo, context: context);
      return saveTo;
    }, context: context);
  }

  // [11] Deletes any existing backup_manifest.json in the MusicLibrary folder.
  Future<void> deleteOldManifest({BuildContext? context}) async {
    // debugPrint('[GoogleDriveService] Deleting old backup_manifest.json files.');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final appFolderId = await ensureAppFolder(context: context);
      final musicLibFolderId = await ensureSubfolder(appFolderId, 'MusicLibrary', context: context);
      final q =
          "'$musicLibFolderId' in parents and name = 'backup_manifest.json' and trashed = false and mimeType = 'application/json'";
      final files = await api.files.list(q: q, spaces: 'drive');
      if (files.files != null && files.files!.isNotEmpty) {
        for (final file in files.files!) {
          if (file.id != null) {
            await api.files.delete(file.id!);
          }
        }
      }
    }, context: context);
  }

  // [12] Downloads a file from Drive to a local path, skipping if already exists.
  Future<bool> downloadFileIfNotExists(String fileId, File saveTo) async {
    if (await saveTo.exists()) return false;
    // debugPrint('[GoogleDriveService] Downloading file if not exists: $fileId');
    await downloadFile(fileId, saveTo);
    return true;
  }

  // [13] Finds a file by name in a given Drive folder and downloads it to a local path (skipping if exists).
  Future<bool> downloadFileByNameIfNotExists(
    String parentId,
    String fileName,
    File saveTo, {
    BuildContext? context,
  }) async {
    if (await saveTo.exists()) return false;
    // debugPrint('[GoogleDriveService] Downloading file by name if not exists: $fileName');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final q = "'$parentId' in parents and name = '$fileName' and trashed = false";
      final files = await api.files.list(q: q, spaces: 'drive');
      if (files.files == null || files.files!.isEmpty) return false;
      final file = files.files!.first;
      if (file.id == null) return false;
      await downloadFile(file.id!, saveTo, context: context);
      return true;
    }, context: context);
  }

  // [14] Recursively downloads files from Drive to local, using manifest info and skipping files that already exist.
  // [driveParentId] is the Drive folder ID, [manifestFiles] is a list of relative file paths, [localRoot] is the local folder to restore into.
  Future<void> downloadFilesFromManifest({
    required String driveParentId,
    required List<String> manifestFiles,
    required Directory localRoot,
    bool stripRoot = false,
    void Function(String filePath, double progress)? onProgress,
    void Function(String filePath)? onFileComplete,
    void Function(String filePath)? onFileError,
    void Function(String filePath)? onFileSkipped,
    BuildContext? context,
  }) async {
    // debugPrint('[GoogleDriveService] Downloading files from manifest.');
    final api = await getDriveClient();
    for (final relPath in manifestFiles) {
      // If stripRoot, remove the first path segment
      String effectiveRelPath = relPath;
      if (stripRoot) {
        final parts = relPath.split('/');
        if (parts.length > 1) {
          effectiveRelPath = parts.sublist(1).join('/');
        } else {
          effectiveRelPath = parts.last;
        }
      }
      final localFile = File('${localRoot.path}/$effectiveRelPath');
      if (await localFile.exists()) {
        if (onFileSkipped != null) onFileSkipped(localFile.path);
        continue;
      }
      // Ensure parent directory exists
      await localFile.parent.create(recursive: true);
      // Find file in Drive
      final relSegments = relPath.split('/');
      final parentSegments = relSegments.length > 1 ? relSegments.sublist(0, relSegments.length - 1) : [];
      final parentId = parentSegments.isEmpty
          ? driveParentId
          : await ensureDrivePath(driveParentId, parentSegments.cast<String>());
      final fileName = relSegments.last;
      final q = "'$parentId' in parents and name = '$fileName' and trashed = false";
      final files = await api.files.list(q: q, spaces: 'drive');
      if (files.files == null || files.files!.isEmpty) {
        if (onFileError != null) onFileError(localFile.path);
        continue;
      }
      final file = files.files!.first;
      if (file.id == null) {
        if (onFileError != null) onFileError(localFile.path);
        continue;
      }
      try {
        await downloadFile(
          file.id!,
          localFile,
          onProgress: (p) {
            if (onProgress != null) onProgress(localFile.path, p);
          },
          context: context,
        );
        if (onFileComplete != null) onFileComplete(localFile.path);
      } catch (e) {
        if (onFileError != null) onFileError(localFile.path);
      }
    }
  }

  // [15] Helper to create nested folders in Drive given a relative path.
  Future<String> ensureDrivePath(String parentId, List<String> pathSegments) async {
    String currentId = parentId;
    for (final segment in pathSegments) {
      currentId = await ensureSubfolder(currentId, segment);
    }
    return currentId;
  }

  // [16] Optimized recursive upload with correct folder structure.
  Future<void> uploadFolderOptimized(
    Directory folder, {
    required String driveParentId,
    String? relativeTo,
    void Function(String filePath)? onFileStart,
    void Function(String filePath)? onFileComplete,
    void Function(String filePath)? onFileError,
    void Function(String filePath, double progress)? onProgress,
    void Function(String folderPath)? onFolderSkipped,
    List<String>? skippedFiles,
    List<String>? uploadedFiles,
    BuildContext? context,
  }) async {
    // debugPrint('[GoogleDriveService] Uploading folder (optimized): ${folder.path}');
    await getDriveClient();
    final rootPath = relativeTo ?? folder.path;
    // List all files and directories in this folder
    final entities = await folder.list(recursive: false, followLinks: false).toList();
    // Filter audio files
    final audioExtensions = ['.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a', '.wma', '.alac', '.aiff', '.opus'];
    final audioFiles = entities
        .whereType<File>()
        .where((f) => audioExtensions.any((ext) => f.path.toLowerCase().endsWith(ext)))
        .toList();
    final subDirs = entities.whereType<Directory>().toList();
    // If this folder and all subfolders contain no audio files, skip
    if (audioFiles.isEmpty && subDirs.isEmpty) {
      // No audio files and no subfolders
      if (onFolderSkipped != null) onFolderSkipped(folder.path);
      // debugPrint('[GoogleDriveService] Skipping folder (no audio files or subfolders): ${folder.path}');
      return;
    }
    // If this folder has no audio files and all subfolders also have no audio files, skip
    bool subDirsContainAudio = false;
    for (final subDir in subDirs) {
      final subEntities = await subDir.list(recursive: true, followLinks: false).toList();
      if (subEntities.whereType<File>().any((f) => audioExtensions.any((ext) => f.path.toLowerCase().endsWith(ext)))) {
        subDirsContainAudio = true;
        break;
      }
    }
    if (audioFiles.isEmpty && !subDirsContainAudio) {
      // No audio files in this folder or any subfolders
      if (onFolderSkipped != null) onFolderSkipped(folder.path);
      // debugPrint('[GoogleDriveService] Skipping folder (no audio files in folder or subfolders): ${folder.path}');
      return;
    }
    // Upload audio files in this folder
    for (final file in audioFiles) {
      // Compute relative path from root
      final relPath = file.path.substring(rootPath.length).replaceAll('\\', '/').replaceAll(RegExp(r'^/'), '');
      final relSegments = relPath.split('/');
      final parentSegments = relSegments.length > 1 ? relSegments.sublist(0, relSegments.length - 1) : [];
      final parentId = parentSegments.isEmpty
          ? driveParentId
          : await ensureDrivePath(driveParentId, parentSegments.cast<String>());
      if (onFileStart != null) onFileStart(file.path);
      try {
        final uploaded = await uploadFileOptimized(
          file,
          driveParentId: parentId,
          onProgress: (p) {
            if (onProgress != null) onProgress(file.path, p);
          },
          skippedFiles: skippedFiles,
          context: context,
        );
        if (uploaded != null) uploadedFiles?.add(file.path);
        if (onFileComplete != null) onFileComplete(file.path);
      } catch (e) {
        if (onFileError != null) onFileError(file.path);
        // debugPrint('[GoogleDriveService] Error uploading file: ${file.path}');
      }
    }
    // Recursively process subdirectories
    for (final subDir in subDirs) {
      await uploadFolderOptimized(
        subDir,
        driveParentId: driveParentId,
        relativeTo: rootPath,
        onFileStart: onFileStart,
        onFileComplete: onFileComplete,
        onFileError: onFileError,
        onProgress: onProgress,
        onFolderSkipped: onFolderSkipped,
        skippedFiles: skippedFiles,
        uploadedFiles: uploadedFiles,
        context: context,
      );
    }
  }

  // [17] List all manifest files in /NamidaSync/Manifests/
  Future<List<drive.File>> listSyncManifests({BuildContext? context}) async {
    // debugPrint('[GoogleDriveService] Listing all manifest files in /NamidaSync/Manifests/.');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final appFolderId = await ensureAppFolder(context: context);
      final manifestsFolderId = await ensureSubfolder(appFolderId, 'Manifests', context: context);
      final q = "'$manifestsFolderId' in parents and trashed = false and mimeType = 'application/json'";
      final files = await api.files.list(q: q, orderBy: 'modifiedTime desc', spaces: 'drive');
      return files.files ?? [];
    }, context: context);
  }

  // [18] Download a specific manifest file by name from /NamidaSync/Manifests/
  Future<File?> downloadSyncManifest(String fileName, File saveTo, {BuildContext? context}) async {
    // debugPrint('[GoogleDriveService] Downloading manifest file: $fileName');
    return await withAuthRetry(() async {
      final api = await getDriveClient();
      final appFolderId = await ensureAppFolder(context: context);
      final manifestsFolderId = await ensureSubfolder(appFolderId, 'Manifests', context: context);
      final q =
          "'$manifestsFolderId' in parents and name = '$fileName' and trashed = false and mimeType = 'application/json'";
      final files = await api.files.list(q: q, spaces: 'drive');
      if (files.files == null || files.files!.isEmpty) return null;
      final manifestFile = files.files!.first;
      if (manifestFile.id == null) return null;
      if (await saveTo.exists()) await saveTo.delete();
      await downloadFile(manifestFile.id!, saveTo, context: context);
      return saveTo;
    }, context: context);
  }
}

// [19] Google auth client for Drive API requests (adds auth headers to each request).
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
