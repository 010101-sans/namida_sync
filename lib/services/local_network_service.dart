import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transfer_manifest.dart';
import '../providers/local_network_provider.dart';
import '../providers/folder_provider.dart';

/// Service for local network backup/restore: device discovery, server, and file transfer.
class LocalNetworkService {
  static const int defaultPort = 53317;
  static const String multicastAddress = '224.0.0.251';
  static const Duration discoveryTimeout = Duration(seconds: 2);
  HttpServer? _httpServer;
  bool _isServerRunning = false;

  // In-memory session for demonstration
  Map<String, dynamic>? _latestManifestJson;
  List<String> _receivedFilePaths = [];
  int _expectedFileCount = 0;
  LocalNetworkProvider? provider;

  Directory? _backupDir;
  Directory? _musicDir;

  // Set backup and music directories from FolderProvider
  void setDirsFromFolderProvider(FolderProvider folderProvider) {
    final backupPath = folderProvider.backupFolder?.path;
    final musicPaths = folderProvider.musicFolders.map((f) => f.path).toList();
    if (backupPath != null && backupPath.isNotEmpty) {
      _backupDir = Directory(backupPath);
    }
    // For music, use the first folder as root for now (can be extended for multi-root)
    if (musicPaths.isNotEmpty) {
      _musicDir = Directory(musicPaths.first);
    }
  }

  // Existing method for manual setting
  void setBackupAndMusicDirs({required Directory backupDir, required Directory musicDir}) {
    _backupDir = backupDir;
    _musicDir = musicDir;
  }

  // Allow setting the provider for callbacks
  void setProvider(LocalNetworkProvider p) {
    provider = p;
  }

  // Fetch the local IP address for display/debugging, prefer Wi-Fi/Ethernet
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        debugPrint('[LocalNetworkService] Interface: ${interface.name}');
        // Prefer Wi-Fi/Ethernet interfaces
        if (interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('wi-fi') ||
            interface.name.toLowerCase().contains('eth')) {
          for (var addr in interface.addresses) {
            debugPrint('[LocalNetworkService] Found address: ${addr.address}');
            if (!addr.isLoopback &&
                (addr.address.startsWith('192.') ||
                 addr.address.startsWith('10.') ||
                 addr.address.startsWith('172.'))
            ) {
              debugPrint('[LocalNetworkService] Selected local IP: ${addr.address} (interface: ${interface.name})');
              return addr.address;
            }
          }
        }
      }
      // Fallback: use any non-loopback private IP
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.') ||
               addr.address.startsWith('10.') ||
               addr.address.startsWith('172.'))
          ) {
            debugPrint('[LocalNetworkService] Fallback local IP: ${addr.address} (interface: ${interface.name})');
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalNetworkService] Error getting local IP: $e');
    }
    return null;
  }

  /// Start the local HTTP server for receiving files.
  Future<void> startServer({required String alias}) async {
    if (_isServerRunning) return;
    _alias = alias;
    debugPrint('[LocalNetworkService] Starting server with alias: $alias');
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, defaultPort);
    _isServerRunning = true;
    debugPrint('[LocalNetworkService] HTTP server started on port $defaultPort');

    _httpServer!.listen((HttpRequest request) async {
      final path = request.uri.path;
      debugPrint('[LocalNetworkService] Incoming request: $path');
      if (path == '/api/namidasync/v1/register') {
        await _handleRegister(request);
      } else if (path == '/api/namidasync/v1/prepare-upload') {
        await _handlePrepareUpload(request);
      } else if (path == '/api/namidasync/v1/upload') {
        await _handleUpload(request);
      } else if (path == '/api/namidasync/v1/cancel') {
        await _handleCancel(request);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    });
  }

  /// Stop the local server.
  Future<void> stopServer() async {
    if (_httpServer != null) {
      debugPrint('[LocalNetworkService] Stopping server...');
      await _httpServer!.close(force: true);
      _httpServer = null;
      _isServerRunning = false;
      debugPrint('[LocalNetworkService] HTTP server stopped');
    }
  }

  // --- Endpoint Handlers ---

  String _alias = '';
  Future<void> _handleRegister(HttpRequest request) async {
    // Respond with alias for HTTP scan
    request.response
      ..statusCode = HttpStatus.ok
      ..write(_alias)
      ..close();
  }

  Future<void> _handlePrepareUpload(HttpRequest request) async {
    try {
      final content = await utf8.decoder.bind(request).join();
      final manifestJson = jsonDecode(content);
      _latestManifestJson = manifestJson;
      _receivedFilePaths = [];
      _expectedFileCount = (manifestJson['files'] as List).length;
      // Optionally: validate manifestJson structure here

      // TODO: Integrate with provider to prompt user for confirmation
      debugPrint('[LocalNetworkService] Received manifest: $manifestJson');

      // For now, always accept
      request.response
        ..statusCode = HttpStatus.ok
        ..write('Ready for upload')
        ..close();
    } catch (e) {
      debugPrint('[LocalNetworkService] Error parsing manifest: $e');
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Invalid manifest')
        ..close();
    }
  }

  Future<void> _handleUpload(HttpRequest request) async {
    try {
      final type = request.uri.queryParameters['type'];
      final relativePath = request.uri.queryParameters['relativePath'];
      // Use actual backup/music folder paths from config
      final backupDir = _backupDir ?? Directory('/tmp/namida_backup');
      final musicDir = _musicDir ?? Directory('/tmp/namida_music');

      // Determine save location
      File saveFile;
      if (type == 'backupZip') {
        await backupDir.create(recursive: true);
        saveFile = File('${backupDir.path}/backup.zip');
        _receivedFilePaths.add(saveFile.path);
      } else if (type == 'music' && relativePath != null) {
        saveFile = File('${musicDir.path}/$relativePath');
        await saveFile.parent.create(recursive: true);
        _receivedFilePaths.add(saveFile.path);
      } else {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Invalid upload type or missing relativePath')
          ..close();
        return;
      }

      // Save file data
      final sink = saveFile.openWrite();
      await request.listen((data) {
        sink.add(data);
      }).asFuture();
      await sink.close();

      debugPrint('[LocalNetworkService] File saved: ${saveFile.path}');
      request.response
        ..statusCode = HttpStatus.ok
        ..write('File received')
        ..close();

      // Only trigger restore when all files in the manifest are received
      if (_latestManifestJson != null && provider != null && _receivedFilePaths.length >= _expectedFileCount) {
        final manifest = TransferManifest(
          backupName: _latestManifestJson!['backupName'] ?? 'Unknown',
          files: (_latestManifestJson!['files'] as List)
              .map((f) => TransferFileEntry(
                    name: f['name'],
                    path: f['path'],
                    size: f['size'],
                    folderLabel: f['folderLabel'],
                    relativePath: f['relativePath'],
                  ))
              .toList(),
        );
        provider!.receiveBackup(
          manifest: manifest,
          filePaths: List<String>.from(_receivedFilePaths),
        );
      }
    } catch (e) {
      debugPrint('[LocalNetworkService] Error saving file: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('File save error')
        ..close();
    }
  }

  Future<void> _handleCancel(HttpRequest request) async {
    // TODO: Cancel the current session/transfer
    request.response
      ..statusCode = HttpStatus.ok
      ..write('Cancelled')
      ..close();
  }

  /// Send a UDP multicast hello packet to announce this device.
  Future<void> sendHello({required String alias, int? port}) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final helloMsg = jsonEncode({
      'alias': alias,
      'port': port ?? defaultPort,
    });
    debugPrint('[LocalNetworkService] Sending hello packet to $multicastAddress:$defaultPort');
    socket.send(utf8.encode(helloMsg), InternetAddress(multicastAddress), defaultPort);
    socket.close();
  }

  /// Listen for hello packets and collect discovered devices.
  Future<List<DiscoveredDevice>> listenForHellos() async {
    final List<DiscoveredDevice> devices = [];
    // Remove reusePort:true for compatibility
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, defaultPort, reuseAddress: true);
    socket.joinMulticast(InternetAddress(multicastAddress));
    final completer = Completer<List<DiscoveredDevice>>();
    final foundIps = <String>{};

    debugPrint('[LocalNetworkService] Listening for hello packets on $defaultPort');
    Timer(discoveryTimeout, () {
      socket.close();
      if (!completer.isCompleted) completer.complete(devices);
    });

    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          try {
            final msg = utf8.decode(datagram.data);
            final data = jsonDecode(msg);
            final ip = datagram.address.address;
            debugPrint('[LocalNetworkService] Received hello from $ip: $data');
            if (!foundIps.contains(ip)) {
              foundIps.add(ip);
              devices.add(DiscoveredDevice(
                alias: data['alias'] ?? 'Unknown',
                ip: ip,
                port: data['port'] ?? defaultPort,
              ));
            }
          } catch (e) {
            debugPrint('[LocalNetworkService] Error decoding hello packet: $e');
          }
        }
      }
    });

    return completer.future;
  }

  /// HTTP subnet scan fallback for device discovery
  Future<List<DiscoveredDevice>> httpSubnetScan({required String alias}) async {
    final List<DiscoveredDevice> devices = [];
    final localIp = await getLocalIpAddress();
    if (localIp == null) return devices;
    final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    final futures = <Future>[];
    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      if (ip == localIp) continue;
      futures.add(HttpClient()
          .getUrl(Uri.parse('http://$ip:$defaultPort/api/namidasync/v1/register'))
          .timeout(const Duration(milliseconds: 500))
          .then((req) => req.close())
          .then((resp) async {
            if (resp.statusCode == 200) {
              final body = await resp.transform(utf8.decoder).join();
              debugPrint('[LocalNetworkService] HTTP scan found device at $ip: $body');
              devices.add(DiscoveredDevice(alias: body, ip: ip, port: defaultPort));
            }
          })
          .catchError((_) {}));
    }
    await Future.wait(futures);
    return devices;
  }

  /// Discover devices on the local network using UDP multicast and HTTP scan fallback.
  Future<List<DiscoveredDevice>> discoverDevices({required String alias}) async {
    // Send hello so others can discover us
    await sendHello(alias: alias);
    // Listen for hellos from others
    final multicastDevices = await listenForHellos();
    // HTTP subnet scan fallback
    final httpDevices = await httpSubnetScan(alias: alias);
    // Merge and deduplicate, filter out local device
    final all = <String, DiscoveredDevice>{};
    final localIp = await getLocalIpAddress();
    for (final d in multicastDevices) {
      if (d.ip != localIp) all[d.ip] = d;
    }
    for (final d in httpDevices) {
      if (d.ip != localIp) all[d.ip] = d;
    }
    debugPrint('[LocalNetworkService] All discovered devices (excluding self): ${all.values.map((d) => '${d.alias} (${d.ip}:${d.port})').join(', ')}');
    return all.values.toList();
  }

  /// Send a backup manifest and files to a target device.
  Future<void> sendBackup({
    required DiscoveredDevice target,
    required File manifest,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    // TODO: Implement sending manifest and files via HTTP(S) POST
  }

  /// Handle receiving a backup (called by server endpoints).
  Future<void> receiveBackup({
    required File manifest,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    // TODO: Implement receiving and saving files
  }

  /// Send the manifest to the target device.
  Future<bool> sendManifest({
    required DiscoveredDevice target,
    required Map<String, dynamic> manifestJson,
  }) async {
    final url = Uri.http('${target.ip}:${target.port}', '/api/namidasync/v1/prepare-upload');
    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(manifestJson));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      return response.statusCode == 200 && responseBody.contains('Ready');
    } catch (e) {
      debugPrint('[LocalNetworkService] Error sending manifest: $e');
      return false;
    } finally {
      client.close();
    }
  }

  /// Send a file (backup zip or music file) to the target device.
  Future<bool> sendFile({
    required DiscoveredDevice target,
    required File file,
    required String type, // 'backupZip' or 'music'
    String? relativePath, // required for music files
    void Function(double progress)? onProgress,
  }) async {
    final queryParams = {
      'type': type,
      if (relativePath != null) 'relativePath': relativePath,
    };
    final url = Uri.http('${target.ip}:${target.port}', '/api/namidasync/v1/upload', queryParams);
    final client = HttpClient();
    try {
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.binary;
      final totalBytes = await file.length();
      int sentBytes = 0;
      final fileStream = file.openRead();
      await for (final chunk in fileStream) {
        request.add(chunk);
        sentBytes += chunk.length;
        if (onProgress != null && totalBytes > 0) {
          onProgress(sentBytes / totalBytes);
        }
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      return response.statusCode == 200 && responseBody.contains('File received');
    } catch (e) {
      debugPrint('[LocalNetworkService] Error sending file: $e');
      return false;
    } finally {
      client.close();
    }
  }
}

/// Model for a discovered device on the network.
class DiscoveredDevice {
  final String alias;
  final String ip;
  final int port;
  // Add more fields as needed (e.g., device type, OS)

  DiscoveredDevice({required this.alias, required this.ip, required this.port});
}
