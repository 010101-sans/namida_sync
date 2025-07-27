import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../providers/local_network_provider.dart';
import '../utils/helper_methods.dart';

// To Handle all local network operations (discovery, server, transfer)
class LocalNetworkService {

  // [1] Constants and State
  static const int defaultPort = 53317;
  static const String multicastAddress = '224.0.0.251';
  static const Duration discoveryTimeout = Duration(seconds: 2);
  HttpServer? _httpServer;
  bool _isServerRunning = false;

  Map<String, dynamic>? _latestManifestJson;
  List<String> _receivedFilePaths = [];
  int _expectedFileCount = 0;
  bool _receiveBackupTriggered = false;
  LocalNetworkProvider? provider;
  String? _deviceUuid;
  String _alias = '';

  // [2] Provider Setter : Allow setting the provider for callbacks
  void setProvider(LocalNetworkProvider p) {
    provider = p;
  }

  // [3] Device UUID Management
  Future<String> get deviceUuid async {
    if (_deviceUuid != null) return _deviceUuid!;
    final prefs = await SharedPreferences.getInstance();
    _deviceUuid = prefs.getString('deviceUuid');
    if (_deviceUuid == null) {
      _deviceUuid = const Uuid().v4();
      await prefs.setString('deviceUuid', _deviceUuid!);
    }
    return _deviceUuid!;
  }

  // [4] Temp Directory Management
  String get tempRoot {
    if (Platform.isWindows) {
      return 'C:/NamidaSync';
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/NamidaSync';
    } else {
      return '${Directory.systemTemp.path}/NamidaSync';
    }
  }

  // [5] Fetch the local IP address for display/debugging, prefer Wi-Fi/Ethernet
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        // debugPrint('[LocalNetworkService] Interface: ${interface.name}');
        // Prefer Wi-Fi/Ethernet interfaces
        if (interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('wi-fi') ||
            interface.name.toLowerCase().contains('eth')) {
          for (var addr in interface.addresses) {
            // debugPrint('[LocalNetworkService] Found address: ${addr.address}');
            if (!addr.isLoopback &&
                (addr.address.startsWith('192.') ||
                    addr.address.startsWith('10.') ||
                    addr.address.startsWith('172.'))) {
              // debugPrint('[LocalNetworkService] Selected local IP: ${addr.address} (interface: ${interface.name})');
              return addr.address;
            }
          }
        }
      }
      // Fallback: use any non-loopback private IP
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.') || addr.address.startsWith('10.') || addr.address.startsWith('172.'))) {
            // debugPrint('[LocalNetworkService] Fallback local IP: ${addr.address} (interface: ${interface.name})');
            return addr.address;
          }
        }
      }
    } catch (e) {
      // debugPrint('[LocalNetworkService] Error getting local IP: $e');
    }
    return null;
  }

  // [6] HTTP Server Management

  // [6.1] Start the local HTTP server for receiving files.
  Future<void> startServer({required String alias}) async {
    
    if (_isServerRunning) return;

    _alias = alias;
    
    // debugPrint('[LocalNetworkService] Starting server with alias: $alias');
    await deviceUuid;

    // Reset provider flags when starting a new server session
    if (provider != null) {
      provider!.reset();
    }

    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, defaultPort);
    _isServerRunning = true;
    // debugPrint('[LocalNetworkService] HTTP server started on port $defaultPort');

    _httpServer!.listen((HttpRequest request) async {
      final path = request.uri.path;
      // debugPrint('[LocalNetworkService] Incoming request: $path');
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

  // [6.2] Stop the local server.
  Future<void> stopServer() async {
    if (_httpServer != null) {
      
      // debugPrint('[LocalNetworkService] Stopping server...');
      await _httpServer!.close(force: true);
      _httpServer = null;
      _isServerRunning = false;

      // Reset provider flags when stopping the server
      if (provider != null) {
        provider!.reset();
      }

      // debugPrint('[LocalNetworkService] HTTP server stopped');
    }
  }

  // [7] HTTP Endpoint Handlers

  // [7.1] Register handler
  Future<void> _handleRegister(HttpRequest request) async {
    // Respond with alias and uuid for HTTP scan
    final uuid = await deviceUuid;
    request.response
      ..statusCode = HttpStatus.ok
      ..write(jsonEncode({'alias': _alias, 'uuid': uuid}))
      ..close();
  }

  // [7.2] Upload preparation handler
  Future<void> _handlePrepareUpload(HttpRequest request) async {
    try {
      final content = await utf8.decoder.bind(request).join();
      final manifestJson = jsonDecode(content);
      _latestManifestJson = manifestJson;
      _receivedFilePaths = [];
      _expectedFileCount = (manifestJson['files'] as List).length;
      _receiveBackupTriggered = false; // Reset flag for new transfer
      // debugPrint('[LocalNetworkService] Received manifest: $manifestJson');

      // Save manifest to file for restore process
      final manifestDir = '$tempRoot/Manifests';
      await Directory(manifestDir).create(recursive: true);
      final manifestPath = '$manifestDir/manifest.json';
      final manifestFile = File(manifestPath);
      await manifestFile.writeAsString(content);
      // Don't add manifest to _receivedFilePaths since it's not part of the file count
      // [7.3] Manifest saved
      // debugPrint('[LocalNetworkService] Manifest saved to: $manifestPath');

      bool accepted = true;
      if (provider != null && provider!.onIncomingBackup != null) {
        final manifest = TransferManifest(
          backupName: manifestJson['backupName'] ?? 'Unknown',
          files: (manifestJson['files'] as List)
              .map(
                (f) => TransferFileEntry(
                  name: f['name'],
                  path: '',
                  size: f['size'],
                  folderLabel: f['folderLabel'] ?? '',
                  relativePath: f['relativePath'] ?? '',
                ),
              )
              .toList(),
        );
        accepted = await provider!.onIncomingBackup!(manifest) == true;
      }

      if (accepted) {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('Ready for upload')
          ..close();
      } else {
        // User declined the backup - clean up and reset state
        // [7.4] User declined backup
        // debugPrint('[LocalNetworkService] User declined backup, cleaning up...');

        // Clean up manifest file
        try {
          final manifestPath = '$tempRoot/Manifests/manifest.json';
          final manifestFile = File(manifestPath);
          if (await manifestFile.exists()) {
            await manifestFile.delete();
            // [7.5] Deleted manifest file after user declined
            // debugPrint('[LocalNetworkService] Deleted manifest file after user declined: $manifestPath');
          }
        } catch (e) {
          // [7.6] Error deleting manifest file after decline
          // debugPrint('[LocalNetworkService] Error deleting manifest file after decline: $e');
        }

        // Reset service state
        _latestManifestJson = null;
        _receivedFilePaths.clear();
        _expectedFileCount = 0;
        _receiveBackupTriggered = false;

        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Transfer declined by user')
          ..close();
      }
    } catch (e) {
      // [7.7] Error parsing manifest
      // debugPrint('[LocalNetworkService] Error parsing manifest: $e');
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('Invalid manifest')
        ..close();
    }
  }

  // [7.3] Upload handler
  Future<void> _handleUpload(HttpRequest request) async {
    try {
      final type = request.uri.queryParameters['type'];
      final relativePath = request.uri.queryParameters['relativePath'];
      final originalName = request.uri.queryParameters['name'];
      // Use tempRoot and subfolders for storage
      String savePath;
      if (type == 'backupZip') {
        final backupDir = '$tempRoot/Backups';
        await Directory(backupDir).create(recursive: true);
        final fileName = originalName ?? 'backup.zip';
        savePath = '$backupDir/$fileName';
        _receivedFilePaths.add(normalizePath(savePath));
      } else if (type == 'music' && relativePath != null) {
        final folderLabel = request.uri.queryParameters['folderLabel'] ?? '';
        final musicDir = '$tempRoot/MusicLibrary';
        savePath = '$musicDir/$folderLabel${relativePath.isNotEmpty ? '/$relativePath' : ''}';
        String parentDir = '';
        final lastSlash = relativePath.lastIndexOf('/');
        if (lastSlash != -1) {
          parentDir = relativePath.substring(0, lastSlash);
        }
        await Directory(
          '$musicDir/$folderLabel${parentDir.isNotEmpty ? '/$parentDir' : ''}',
        ).create(recursive: true);
        _receivedFilePaths.add(normalizePath(savePath));
      } else {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Invalid upload type or missing relativePath')
          ..close();
        return;
      }

      // Save file data
      final saveFile = File(savePath);
      final sink = saveFile.openWrite();
      await request.listen((data) {
        sink.add(data);
      }).asFuture();
      await sink.close();

      // [7.8] File saved
      // debugPrint('[LocalNetworkService] File saved: ${saveFile.path}');
      request.response
        ..statusCode = HttpStatus.ok
        ..write('File received')
        ..close();

      // Only trigger receiveBackup when all files in the manifest are received
      if (_latestManifestJson != null &&
          provider != null &&
          _receivedFilePaths.length >= _expectedFileCount &&
          !_receiveBackupTriggered) {
        _receiveBackupTriggered = true;
        // [7.9] All files received
        // debugPrint('[LocalNetworkService] All files received, triggering receiveBackup');
        final manifest = TransferManifest(
          backupName: _latestManifestJson!['backupName'] ?? 'Unknown',
          files: (_latestManifestJson!['files'] as List)
              .map(
                (f) => TransferFileEntry(
                  name: f['name'],
                  path: '', // Do not use sender-local path
                  size: f['size'],
                  folderLabel: f['folderLabel'] ?? '',
                  relativePath: f['relativePath'] ?? '',
                ),
              )
              .toList(),
        );
        // Trigger receiveBackup which will handle the restore process
        provider!.receiveBackup(manifest: manifest, filePaths: List<String>.from(_receivedFilePaths));
      }
    } catch (e) {
      // [7.10] Error saving file
      // debugPrint('[LocalNetworkService] Error saving file: $e');
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('File save error')
        ..close();
    }
  }

  // [7.4] Cancel handler
  Future<void> _handleCancel(HttpRequest request) async {
    // debugPrint('[LocalNetworkService] Cancelling current transfer/session');

    // Clean up manifest file if it exists
    if (_latestManifestJson != null) {
      try {
        final manifestPath = '$tempRoot/Manifests/manifest.json';
        final manifestFile = File(manifestPath);
        if (await manifestFile.exists()) {
          await manifestFile.delete();
          // debugPrint('[LocalNetworkService] Deleted manifest file: $manifestPath');
        }
      } catch (e) {
        // debugPrint('[LocalNetworkService] Error deleting manifest file: $e');
      }
    }

    _latestManifestJson = null;
    _receivedFilePaths.clear();
    _expectedFileCount = 0;
    _receiveBackupTriggered = false; // Reset flag
    provider?.reset();
    request.response
      ..statusCode = HttpStatus.ok
      ..write('Cancelled')
      ..close();
  }

  // [8] Device Discovery (UDP/HTTP)

  // [8.1] Send a UDP multicast hello packet to announce this device.
  Future<void> sendHello({required String alias, int? port}) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final uuid = await deviceUuid;
    final helloMsg = jsonEncode({'alias': alias, 'port': port ?? defaultPort, 'uuid': uuid});
    // debugPrint('[LocalNetworkService] Sending hello packet to $multicastAddress:$defaultPort');
    socket.send(utf8.encode(helloMsg), InternetAddress(multicastAddress), defaultPort);
    socket.close();
  }

  // [8.2] Listen for hello packets and collect discovered devices.
  Future<List<DiscoveredDevice>> listenForHellos() async {
    final List<DiscoveredDevice> devices = [];
    // Remove reusePort:true for compatibility
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, defaultPort, reuseAddress: true);
    socket.joinMulticast(InternetAddress(multicastAddress));
    final completer = Completer<List<DiscoveredDevice>>();
    final foundIps = <String>{};

    // debugPrint('[LocalNetworkService] Listening for hello packets on $defaultPort');
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
            // debugPrint('[LocalNetworkService] Received hello from $ip: $data');
            if (!foundIps.contains(ip)) {
              foundIps.add(ip);
              devices.add(
                DiscoveredDevice(
                  alias: data['alias'] ?? 'Unknown',
                  ip: ip,
                  port: data['port'] ?? defaultPort,
                  uuid: data['uuid'] ?? '',
                ),
              );
            }
          } catch (e) {
            // debugPrint('[LocalNetworkService] Error decoding hello packet: $e');
          }
        }
      }
    });

    return completer.future;
  }

  // [8.3] HTTP subnet scan fallback for device discovery
  Future<List<DiscoveredDevice>> httpSubnetScan({required String alias}) async {
    final List<DiscoveredDevice> devices = [];
    final localIp = await getLocalIpAddress();
    if (localIp == null) return devices;
    final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
    final futures = <Future>[];
    for (int i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      if (ip == localIp) continue;
      futures.add(
        HttpClient()
            .getUrl(Uri.parse('http://$ip:$defaultPort/api/namidasync/v1/register'))
            .timeout(const Duration(milliseconds: 500))
            .then((req) => req.close())
            .then((resp) async {
              if (resp.statusCode == 200) {
                final body = await resp.transform(utf8.decoder).join();
                try {
                  final data = jsonDecode(body);
                  // debugPrint('[LocalNetworkService] HTTP scan found device at $ip: $data');
                  devices.add(
                    DiscoveredDevice(
                      alias: data['alias'] ?? 'Unknown',
                      ip: ip,
                      port: defaultPort,
                      uuid: data['uuid'] ?? '',
                    ),
                  );
                } catch (e) {
                  // debugPrint('[LocalNetworkService] Error decoding HTTP scan response: $e');
                }
              }
            })
            .catchError((_) {}),
      );
    }
    await Future.wait(futures);
    return devices;
  }

  // [8.4] Discover devices on the local network using UDP multicast and HTTP scan fallback.
  Future<List<DiscoveredDevice>> discoverDevices({String alias = 'NamidaSync'}) async {
    
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

    // debugPrint('[LocalNetworkService] All discovered devices (excluding self): ${all.values.map((d) => '${d.alias} (${d.ip}:${d.port})').join(', ')}');
    return all.values.toList();
  }

  // [9] File Transfer (Send/Receive)

  // [9.1] Send a backup manifest and files to a target device.
  Future<void> sendBackup({
    required DiscoveredDevice target,
    required File manifest,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    // Send manifest
    final manifestJson = jsonDecode(await manifest.readAsString());
    final manifestOk = await sendManifest(target: target, manifestJson: manifestJson);
    if (!manifestOk) {
      // debugPrint('[LocalNetworkService] Target declined manifest or failed.');
      onProgress?.call(0);
      return;
    }
    // Send backup zip (first file)
    if (files.isNotEmpty) {
      final zipFile = files.first;
      final okZip = await sendFile(
        target: target,
        file: zipFile,
        type: 'backupZip',
        onProgress: (p) => onProgress?.call(0.1 + 0.4 * p),
      );
      if (!okZip) {
        // debugPrint('[LocalNetworkService] Failed to send backup zip.');
        onProgress?.call(0.1);
        return;
      }
    }

    // Send music files (rest)
    final musicFiles = files.length > 1 ? files.sublist(1) : [];
    final totalMusic = musicFiles.length;
    for (int i = 0; i < totalMusic; i++) {
      final file = musicFiles[i];
      final ok = await sendFile(
        target: target,
        file: file,
        type: 'music',
        onProgress: (p) => onProgress?.call(0.5 + 0.5 * ((i + p) / totalMusic)),
      );
      if (!ok) {
        // debugPrint('[LocalNetworkService] Failed to send music file: ${file.path}');
        onProgress?.call(0.5 + 0.5 * (i / totalMusic));
        return;
      }
    }
    onProgress?.call(1.0);
  }

  // [9.2] Handle receiving a backup (called by server endpoints).
  Future<void> receiveBackup({
    required File manifest,
    required List<File> files,
    void Function(double progress)? onProgress,
  }) async {
    // Note: Receiving and saving files is handled by the server endpoints (_handleUpload, etc.)
    // Note: This method can be used for additional post-processing if needed.

    // debugPrint('[LocalNetworkService] receiveBackup called (stub).');
    onProgress?.call(1.0);
  }

  // [9.3] Send the manifest to the target device.
  Future<bool> sendManifest({required DiscoveredDevice target, required Map<String, dynamic> manifestJson}) async {
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
      // debugPrint('[LocalNetworkService] Error sending manifest: $e');
      return false;
    } finally {
      client.close();
    }
  }

  // [0.4] Send a file (backup zip or music file) to the target device.
  Future<bool> sendFile({
    required DiscoveredDevice target,
    required File file,
    required String type, // 'backupZip' or 'music'
    String? relativePath, // required for music files
    void Function(double progress)? onProgress,
    String? name,        // original file name for backupZip
    String? folderLabel, // top-level music folder name
  }) async {
    final queryParams = {
      'type': type,
      if (relativePath != null) 'relativePath': relativePath,
      if (name != null) 'name': name,
      if (folderLabel != null) 'folderLabel': folderLabel,
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
      // debugPrint('[LocalNetworkService] Error sending file: $e');
      return false;
    } finally {
      client.close();
    }
  }

  // [9.5] Cancel Transfer
  Future<void> requestCancel() async {
    try {
      final client = HttpClient();
      // final url = Uri.http('127.0.0.1:$defaultPort', '/api/namidasync/v1/cancel');
      // final request = await client.postUrl(url);
      // final response = await request.close();
      // final responseBody = await response.transform(utf8.decoder).join();
      client.close();
      // debugPrint('[LocalNetworkService] Cancel response: ${response.statusCode} $responseBody');
    } catch (e) {
      // debugPrint('[LocalNetworkService] Error sending cancel request: $e');
    }
  }
}
