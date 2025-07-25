import 'package:flutter/material.dart';
import '../services/local_network_service.dart';
import '../models/transfer_session.dart';
import '../models/transfer_manifest.dart';
import 'dart:io'; // Added for File
import '../providers/folder_provider.dart';

/// Provider for managing local network backup/restore state and actions.
class LocalNetworkProvider extends ChangeNotifier {
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

  LocalNetworkProvider(this.networkService);

  FolderProvider? folderProvider;
  void setFolderProvider(FolderProvider provider) {
    folderProvider = provider;
  }

  /// Discover devices on the local network.
  Future<void> discoverDevices() async {
    // Use a static alias for now; in production, use device name or user alias
    final devices = await networkService.discoverDevices(alias: 'NamidaSync');
    discoveredDevices = devices;
    notifyListeners();
  }

  /// Send backup to a selected device.
  Future<void> sendBackup({
    required DiscoveredDevice target,
    required String backupZipPath, // Path to latest backup zip file
    required List<Directory> musicFolders, // List of music folder roots
  }) async {
    isSending = true;
    progress = 0.0;
    error = null;
    notifyListeners();
    try {
      debugPrint('[LocalNetworkProvider] Preparing to send backup to ${target.alias} at ${target.ip}:${target.port}');
      // 1. Build manifest entries for backup zip and all music files
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
      // 2. Send manifest to the selected peer device
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
      debugPrint('[LocalNetworkProvider] Sending manifest to ${target.alias} at ${target.ip}:${target.port}');
      final manifestOk = await networkService.sendManifest(target: target, manifestJson: manifestJson);
      if (!manifestOk) {
        error = 'Failed to send manifest or target declined.';
        isSending = false;
        notifyListeners();
        return;
      }
      // 3. Send backup zip to the selected peer device
      debugPrint('[LocalNetworkProvider] Sending backup zip to ${target.alias} at ${target.ip}:${target.port}');
      final okZip = await networkService.sendFile(
        target: target,
        file: backupZipFile,
        type: 'backupZip',
        onProgress: (p) {
          progress = 0.1 + 0.4 * p; // 10-50% for zip
          notifyListeners();
        },
      );
      if (!okZip) {
        error = 'Failed to send backup zip.';
        isSending = false;
        notifyListeners();
        return;
      }
      // 4. Send music files to the selected peer device
      final musicFileEntries = manifest.files.where((f) => f.folderLabel.isNotEmpty).toList();
      final totalFiles = musicFileEntries.length;
      for (int i = 0; i < totalFiles; i++) {
        final entry = musicFileEntries[i];
        final file = File(entry.path);
        debugPrint(
          '[LocalNetworkProvider] Sending music file ${entry.name} to ${target.alias} at ${target.ip}:${target.port}',
        );
        final ok = await networkService.sendFile(
          target: target,
          file: file,
          type: 'music',
          relativePath: entry.relativePath,
          onProgress: (p) {
            progress = 0.5 + 0.5 * ((i + p) / totalFiles); // 50-100% for music
            notifyListeners();
          },
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

  /// Callback for user confirmation before accepting a backup
  Function(TransferManifest manifest)? onIncomingBackup;

  /// Callback for prompting user to pick restore location.
  Future<String?> Function(String folderLabel)? onPickRestoreLocation;

  void setOnIncomingBackup(Function(TransferManifest manifest)? callback) {
    onIncomingBackup = callback;
  }

  void setOnPickRestoreLocation(Future<String?> Function(String folderLabel)? callback) {
    onPickRestoreLocation = callback;
  }

  /// Receive backup from another device.
  Future<void> receiveBackup({required TransferManifest manifest, required List<String> filePaths}) async {
    // Prompt user for confirmation before accepting backup
    if (onIncomingBackup != null) {
      final accepted = await onIncomingBackup!(manifest);
      if (accepted != true) {
        error = 'User declined incoming backup.';
        isReceiving = false;
        notifyListeners();
        return;
      }
    }
    isReceiving = true;
    progress = 0.0;
    error = null;
    notifyListeners();
    try {
      debugPrint('[LocalNetworkProvider] Receiving manifest: \nBackup: \n\tName: ${manifest.backupName}');
      for (final file in manifest.files) {
        debugPrint(
          '[LocalNetworkProvider] File: ${file.name} (size: ${file.size}), folderLabel: ${file.folderLabel}, relativePath: ${file.relativePath}',
        );
      }
      // Restore music files
      int restored = 0;
      final total = manifest.files.where((f) => f.folderLabel.isNotEmpty).length;
      for (final file in manifest.files.where((f) => f.folderLabel.isNotEmpty)) {
        String? restoreRoot;
        // Try to find matching music library folder
        if (folderProvider != null) {
          String? foundPath;
          for (final f in folderProvider!.musicFolders) {
            if (f.name == file.folderLabel) {
              foundPath = f.path;
              break;
            }
          }
          if (foundPath != null) {
            restoreRoot = foundPath;
            debugPrint('[LocalNetworkProvider] Restoring to existing music library folder: $restoreRoot');
          }
        }
        // If not found, prompt user for restore location
        if (restoreRoot == null) {
          if (onPickRestoreLocation != null) {
            restoreRoot = await onPickRestoreLocation!(file.folderLabel);
            if (restoreRoot == null) {
              error = 'User cancelled restore location selection.';
              isReceiving = false;
              notifyListeners();
              return;
            }
            debugPrint('[LocalNetworkProvider] User picked restore location: $restoreRoot');
          } else {
            restoreRoot = '/tmp/restore/${file.folderLabel}';
            debugPrint('[LocalNetworkProvider] Defaulting restore location to: $restoreRoot');
          }
        }
        final restorePath = '$restoreRoot/${file.relativePath}';
        final srcFilePath = filePaths.firstWhere(
          (p) => p.endsWith('/${file.relativePath}') || p.endsWith('\\${file.relativePath}'),
          orElse: () => '',
        );
        if (srcFilePath.isEmpty) {
          debugPrint('[LocalNetworkProvider] Could not find received file for: ${file.relativePath}');
          continue;
        }
        final srcFile = File(srcFilePath);
        final destFile = File(restorePath);
        await destFile.parent.create(recursive: true);
        // Skip if file already exists (duplicate)
        if (await destFile.exists()) {
          debugPrint('[LocalNetworkProvider] Skipping duplicate file: $restorePath');
          continue;
        }
        await srcFile.copy(destFile.path);
        debugPrint('[LocalNetworkProvider] Restored file to: $restorePath');
        restored++;
        progress = restored / total;
        notifyListeners();
      }
      progress = 1.0;
      isReceiving = false;
      notifyListeners();
    } catch (e) {
      error = 'Error during receive: $e';
      isReceiving = false;
      notifyListeners();
    }
  }

  /// Reset state and errors.
  void reset() {
    progress = 0.0;
    error = null;
    isSending = false;
    isReceiving = false;
    currentSession = null;
    notifyListeners();
  }

  Future<void> startServer(String alias) async {
    deviceAlias = alias;
    debugPrint('[LocalNetworkProvider] Starting server with alias: $alias');
    await networkService.startServer(alias: alias);
    ipAddress = await networkService.getLocalIpAddress();
    deviceUuid = await networkService.deviceUuid;
    isServerRunning = true;
    debugPrint('[LocalNetworkProvider] Server started. IP: $ipAddress, Port: $port, UUID: $deviceUuid');
    notifyListeners();
  }

  Future<void> stopServer() async {
    debugPrint('[LocalNetworkProvider] Stopping server...');
    await networkService.stopServer();
    isServerRunning = false;
    debugPrint('[LocalNetworkProvider] Server stopped.');
    notifyListeners();
  }

  Future<void> cancelTransfer() async {
    await networkService.requestCancel();
    reset();
    notifyListeners();
  }

  // Getter for refreshDevices for UI wiring
  VoidCallback get refreshDevices =>
      () => refreshDevicesImpl();

  Future<void> refreshDevicesImpl() async {
    isDiscovering = true;
    notifyListeners();
    debugPrint('[LocalNetworkProvider] Starting device discovery...');
    try {
      final devices = await networkService.discoverDevices(alias: deviceAlias);
      final localIp = ipAddress ?? await networkService.getLocalIpAddress();
      final localUuid = deviceUuid ?? await networkService.deviceUuid;
      // Filter out self (same UUID)
      discoveredDevices = devices.where((d) => d.uuid != localUuid).toList();
      debugPrint('[LocalNetworkProvider] Local IP: $localIp, UUID: $localUuid');
      debugPrint('[LocalNetworkProvider] Discovered devices: \n${discoveredDevices.map((d) => '${d.alias} (${d.ip}:${d.port}, uuid: ${d.uuid})').join(', ')}');
    } catch (e) {
      debugPrint('[LocalNetworkProvider] Error discovering devices: $e');
    }
    isDiscovering = false;
    notifyListeners();
  }
}
