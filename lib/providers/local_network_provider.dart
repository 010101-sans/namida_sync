import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../services/services.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

// State management for local network transfer
class LocalNetworkProvider extends ChangeNotifier {
  // [1] State Fields
  final LocalNetworkService networkService;
  List<DiscoveredDevice> discoveredDevices = [];
  bool isDiscovering = false;
  TransferSession? currentSession;
  double progress = 0.0;
  String? error;
  bool isSending = false;
  bool isReceiving = false;
  bool isServerRunning = false;
  String deviceAlias = 'My Device';
  String? ipAddress;
  int port = 53317;
  String? deviceUuid;
  bool _restoreInProgress = false;
  FolderProvider? folderProvider;

  LocalNetworkProvider(this.networkService);

  // Callbacks for UI interacto
  Function(TransferManifest manifest)? onIncomingBackup;
  Future<void> Function()? onRestoreComplete;
  // Callback for prompting user to pick restore location.
  Future<String?> Function(String folderLabel)? onPickRestoreLocation;

  void setOnIncomingBackup(Function(TransferManifest manifest)? callback) {
    onIncomingBackup = callback;
  }

  void setOnRestoreComplete(Future<void> Function()? callback) {
    onRestoreComplete = callback;
  }

  void setOnPickRestoreLocation(Future<String?> Function(String folderLabel)? callback) {
    onPickRestoreLocation = callback;
  }

  void setFolderProvider(FolderProvider provider) {
    folderProvider = provider;
  }

  // [2] Discover devices on the local network.
  Future<void> discoverDevices() async {
    final devices = await networkService.discoverDevices();
    discoveredDevices = devices;
    notifyListeners();
  }

  // [3] Send backup to a selected device.
  Future<void> sendBackup({
    required DiscoveredDevice target,
    required String backupZipPath, // Path to latest backup zip file
    required List<Directory> musicFolders, // List of music folder paths
  }) async {
    isSending = true;
    progress = 0.0;
    error = null;
    notifyListeners();
    try {
      // debugPrint('[LocalNetworkProvider] Preparing to send backup to ${target.alias} at ${target.ip}:${target.port}');

      // Step 1 : Build manifest entries for backup zip and all music files
      final manifestFiles = <TransferFileEntry>[];

      // Add backup zip entry
      final backupZipFile = File(backupZipPath);
      manifestFiles.add(
        TransferFileEntry(
          name: backupZipFile.uri.pathSegments.last,
          path: backupZipFile.path,
          size: await backupZipFile.length(),
          folderLabel: '',
          relativePath: '',
        ),
      );

      // Add music files, preserving folder hierarchy
      for (final folder in musicFolders) {
        final folderLabel = folder.uri.pathSegments.isNotEmpty
            ? folder.uri.pathSegments.where((s) => s.isNotEmpty).last
            : folder.path;
        await for (final entity in folder.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final relativePath = entity.path
                .substring(folder.path.length)
                .replaceAll('\\', '/')
                .replaceAll(RegExp(r'^/'), '');
            manifestFiles.add(
              TransferFileEntry(
                name: entity.uri.pathSegments.last,
                path: entity.path,
                size: await entity.length(),
                folderLabel: folderLabel,
                relativePath: relativePath,
              ),
            );
          }
        }
      }
      final manifest = TransferManifest(backupName: backupZipFile.uri.pathSegments.last, files: manifestFiles);

      // Step 2 : Send manifest to the selected peer device
      final manifestJson = {
        'backupName': manifest.backupName,
        'files': manifest.files
            .map(
              (f) => {
                'name': f.name,
                'path': f.path,
                'size': f.size,
                'folderLabel': f.folderLabel,
                'relativePath': f.relativePath,
              },
            )
            .toList(),
      };

      // debugPrint('[LocalNetworkProvider] Sending manifest to ${target.alias} at ${target.ip}:${target.port}');
      final manifestOk = await networkService.sendManifest(target: target, manifestJson: manifestJson);
      if (!manifestOk) {
        error = 'Failed to send manifest or target declined.';
        isSending = false;
        notifyListeners();
        return;
      }

      // Step 3 : Send backup zip to the selected peer device

      // debugPrint('[LocalNetworkProvider] Sending backup zip to ${target.alias} at ${target.ip}:${target.port}');
      final okZip = await networkService.sendFile(
        target: target,
        file: backupZipFile,
        type: 'backupZip',
        onProgress: (p) {
          progress = 0.1 + 0.4 * p; // 10-50% for zip
          notifyListeners();
        },
        name: backupZipFile.uri.pathSegments.last,
      );
      if (!okZip) {
        error = 'Failed to send backup zip.';
        isSending = false;
        notifyListeners();
        return;
      }

      // Step 4 : Send music files to the selected peer device
      final musicFileEntries = manifest.files.where((f) => f.folderLabel.isNotEmpty).toList();
      final totalFiles = musicFileEntries.length;
      for (int i = 0; i < totalFiles; i++) {
        final entry = musicFileEntries[i];
        final file = File(entry.path);

        // debugPrint('[LocalNetworkProvider] Sending music file ${entry.name} to ${target.alias} at ${target.ip}:${target.port}',);
        final ok = await networkService.sendFile(
          target: target,
          file: file,
          type: 'music',
          relativePath: entry.relativePath,
          onProgress: (p) {
            progress = 0.5 + 0.5 * ((i + p) / totalFiles); // 50-100% for music
            notifyListeners();
          },
          folderLabel: entry.folderLabel,
        );
        if (!ok) {
          error = 'Failed to send music file: ${entry.path}';
          isSending = false;
          notifyListeners();
          return;
        }
      }
      progress = 1.0;
      isSending = false;
      notifyListeners();
    } catch (e) {
      error = 'Error during send: $e';
      isSending = false;
      notifyListeners();
    }
  }

  // [4] Receive backup from another device.
  Future<void> receiveBackup({required TransferManifest manifest, required List<String> filePaths}) async {
    // Prevent duplicate processing
    if (_restoreInProgress) {
      // debugPrint('[LocalNetworkProvider] Restore already in progress, skipping duplicate call');
      return;
    }

    // Set flag immediately to prevent duplicate calls
    _restoreInProgress = true;

    try {
      // debugPrint('[LocalNetworkProvider] Processing received backup: ${manifest.backupName}');
      isReceiving = true;
      progress = 0.0;
      error = null;
      notifyListeners();

      // debugPrint('[LocalNetworkProvider] Receiving manifest: \nBackup: \n\tName: ${manifest.backupName}');
      // for (final file in manifest.files) {
      //    debugPrint('[LocalNetworkProvider] File: ${file.name} (size: ${file.size}), folderLabel: ${file.folderLabel}, relativePath: ${file.relativePath}',);
      // }

      // Files are already saved to temp by the service, just update progress
      progress = 1.0;
      isReceiving = false;
      notifyListeners();

      // debugPrint('[LocalNetworkProvider] All files received, starting restore process...');

      // Trigger the restore process if we have a context
      if (onRestoreComplete != null) {
        await onRestoreComplete!();
      }
    } catch (e) {
      error = 'Error during receive: $e';
      isReceiving = false;
      // debugPrint('[LocalNetworkProvider] Error in receiveBackup: $e');
    } finally {
      // Reset flag only after everything is complete
      _restoreInProgress = false;
      notifyListeners();
    }
  }

  // [5] Restore Logic
  Future<void> restoreFromTempReceivedFiles(BuildContext context) async {
    // debugPrint('[LocalNetworkProvider] Starting restoreFromTempReceivedFiles');

    if (folderProvider == null) {
      error = 'Folder provider not available.';
      notifyListeners();
      return;
    }

    final tempRoot = networkService.tempRoot;
    final manifestPath = '$tempRoot/Manifests/manifest.json';
    final manifestFile = File(manifestPath);

    if (!await manifestFile.exists()) {
      error = 'No received manifest found.';
      // debugPrint('[LocalNetworkProvider] Manifest file not found at: $manifestPath');
      notifyListeners();
      return;
    }

    try {
      final manifestJson = await manifestFile.readAsString();
      final manifest = TransferManifest.fromJson(jsonDecode(manifestJson));

      // debugPrint('[LocalNetworkProvider] Starting restore from manifest: ${manifest.backupName}');

      // Step 1 : Restore backup zip to the configured backup folder
      final backupZipPath = '$tempRoot/Backups/${manifest.backupName}';
      final backupZipFile = File(backupZipPath);

      if (await backupZipFile.exists()) {
        final backupFolder = folderProvider!.backupFolder?.path;
        if (backupFolder != null && backupFolder.isNotEmpty) {
          final destZipPath = normalizePath('$backupFolder/${manifest.backupName}');
          final destZipFile = File(destZipPath);

          if (!await destZipFile.exists()) {
            await backupZipFile.copy(destZipPath);
            // debugPrint('[LocalNetworkProvider] Backup zip restored to: $destZipPath');
          } else {
            // debugPrint('[LocalNetworkProvider] Backup zip already exists, skipping: $destZipPath');
          }
        } else {
          // debugPrint('[LocalNetworkProvider] No backup folder configured, skipping backup zip restore');
        }
      } else {
        // debugPrint('[LocalNetworkProvider] Backup zip not found in temp: $backupZipPath');
      }

      // Step 2 : Restore music folders
      final musicEntries = manifest.files.where((f) => f.folderLabel.isNotEmpty).toList();
      final uniqueFolders = <String>{};

      // debugPrint('[LocalNetworkProvider] Processing ${musicEntries.length} music files in ${musicEntries.map((e) => e.folderLabel).toSet().length} unique folders');

      // Group by folderLabel to handle each folder once
      for (final entry in musicEntries) {
        if (uniqueFolders.contains(entry.folderLabel)) continue;
        uniqueFolders.add(entry.folderLabel);

        // debugPrint('[LocalNetworkProvider] Processing folder: ${entry.folderLabel}');

        // Check if a folder with the same name exists in music library
        final existingFolder = folderProvider!.musicFolders.where((f) => f.name == entry.folderLabel).firstOrNull;

        String? chosenPath;

        if (existingFolder != null) {
          // debugPrint('[LocalNetworkProvider] Using existing folder path for "${entry.folderLabel}": $chosenPath');
          chosenPath = existingFolder.path;
        } else {
          // [6.11] Prompting user for folder restore location, if folder doesn't exist
          chosenPath = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text('Restore "${entry.folderLabel}"'),
              content: Text('This folder is not in your music library. How would you like to restore it?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Option 1: Pick an existing location on device
                    final picked = await FilePicker.platform.getDirectoryPath(
                      dialogTitle: 'Pick location for ${entry.folderLabel}',
                    );
                    Navigator.of(ctx).pop(picked);
                  },
                  child: const Text('Pick Existing Location'),
                ),
                TextButton(
                  onPressed: () async {
                    // Option 2: Pick parent folder for new subfolder
                    final parent = await FilePicker.platform.getDirectoryPath(
                      dialogTitle: 'Select parent folder for ${entry.folderLabel}',
                    );
                    if (parent != null && parent.isNotEmpty) {
                      Navigator.of(ctx).pop(normalizePath('$parent/${entry.folderLabel}'));
                    } else {
                      Navigator.of(ctx).pop(null);
                    }
                  },
                  child: const Text('Pick Parent Folder'),
                ),
                TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Skip')),
              ],
            ),
          );
        }

        if (chosenPath == null || chosenPath.isEmpty) {
          // debugPrint('[LocalNetworkProvider] Skipping folder "${entry.folderLabel}" - no path chosen');
          continue;
        }

        // Copy all files for this folder
        final folderEntries = musicEntries.where((e) => e.folderLabel == entry.folderLabel).toList();

        // debugPrint('[LocalNetworkProvider] Copying ${folderEntries.length} files for folder "${entry.folderLabel}"');
        for (final fileEntry in folderEntries) {
          final tempFilePath = normalizePath('$tempRoot/MusicLibrary/${entry.folderLabel}/${fileEntry.relativePath}');
          final tempFile = File(tempFilePath);

          if (await tempFile.exists()) {
            final destFilePath = normalizePath('$chosenPath/${fileEntry.relativePath}');
            final destFile = File(destFilePath);

            // Create parent directories
            await destFile.parent.create(recursive: true);

            if (!await destFile.exists()) {
              await tempFile.copy(destFilePath);
              // debugPrint('[LocalNetworkProvider] Restored: ${fileEntry.name} to $destFilePath');
            } else {
              // debugPrint('[LocalNetworkProvider] File already exists, skipping: $destFilePath');
            }
          } else {
            // debugPrint('[LocalNetworkProvider] Temp file not found: $tempFilePath');
          }
        }

        // Add to music library if it's a new folder
        if (existingFolder == null) {
          await folderProvider!.addMusicFolder(chosenPath);
          // debugPrint('[LocalNetworkProvider] Added new folder to music library: $chosenPath');
        }
      }

      // debugPrint('[LocalNetworkProvider] Restore completed successfully');
    } catch (e) {
      error = 'Error during restore: $e';
      // debugPrint('[LocalNetworkProvider] Restore error: $e');
    }

    notifyListeners();
  }

  // [6] Reset state and errors.
  void reset() {
    progress = 0.0;
    error = null;
    isSending = false;
    isReceiving = false;
    currentSession = null;
    _restoreInProgress = false;
    notifyListeners();
  }

  // [7] Server Management Methods
  Future<void> startServer(String alias) async {
    deviceAlias = alias;
    // debugPrint('[LocalNetworkProvider] Starting server with alias: $alias');
    await networkService.startServer(alias: alias);
    ipAddress = await networkService.getLocalIpAddress();
    deviceUuid = await networkService.deviceUuid;
    isServerRunning = true;
    // debugPrint('[LocalNetworkProvider] Server started. IP: $ipAddress, Port: $port, UUID: $deviceUuid');
    notifyListeners();
  }

  Future<void> stopServer() async {
    // debugPrint('[LocalNetworkProvider] Stopping server...');
    await networkService.stopServer();
    isServerRunning = false;
    // debugPrint('[LocalNetworkProvider] Server stopped.');
    notifyListeners();
  }

  Future<void> cancelTransfer() async {
    await networkService.requestCancel();
    reset();
    notifyListeners();
  }

  // Getter for refreshDevices
  VoidCallback get refreshDevices =>
      () => refreshDevicesImpl();

  Future<void> refreshDevicesImpl() async {
    isDiscovering = true;
    notifyListeners();
    // debugPrint('[LocalNetworkProvider] Starting device discovery...');
    try {
      final devices = await networkService.discoverDevices(alias: deviceAlias);
      // final localIp = ipAddress ?? await networkService.getLocalIpAddress();
      final localUuid = deviceUuid ?? await networkService.deviceUuid;
      // Filter out self (same UUID)
      discoveredDevices = devices.where((d) => d.uuid != localUuid).toList();
      // debugPrint('[LocalNetworkProvider] Local IP: $localIp, UUID: $localUuid');
      // debugPrint('[LocalNetworkProvider] Discovered devices: \n${discoveredDevices.map((d) => '${d.alias} (${d.ip}:${d.port}, uuid: ${d.uuid})').join(', ')}');
    } catch (e) {
      // debugPrint('[LocalNetworkProvider] Error discovering devices: $e');
    }
    isDiscovering = false;
    notifyListeners();
  }
}
