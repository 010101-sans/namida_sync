import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:udp/udp.dart';

/// Callback type for when a device is discovered.
typedef DeviceDiscoveredCallback = void Function(String alias, String ip, int port);

// Service for local network device discovery and file transfer.
// Handles UDP multicast, HTTP scan, and server/client logic.
class LocalNetworkService {
  static const int multicastPort = 53317;
  static const String multicastAddress = '239.255.255.250'; // Standard mDNS multicast address
  static const String presenceMessageType = 'namida_sync_presence';

  UDP? _udpSender;
  UDP? _udpListener;
  StreamSubscription? _udpSub;
  Timer? _broadcastTimer;
  DeviceDiscoveredCallback? onDeviceDiscovered;

  // Starts UDP multicast discovery.
  // Broadcasts presence and listens for peers.
  Future<void> startUdpDiscovery({required String alias, required int port, required DeviceDiscoveredCallback onDiscovered}) async {
    onDeviceDiscovered = onDiscovered;
    // Start listening for multicast packets
    _udpListener = await UDP.bind(Endpoint.any(port: Port(multicastPort)));
    _udpSub = _udpListener!.asStream().listen((datagram) {
      if (datagram == null) return;
      final message = utf8.decode(datagram.data);
      try {
        final data = json.decode(message);
        if (data is Map && data['type'] == presenceMessageType) {
          final peerAlias = data['alias'] as String?;
          final peerPort = data['port'] as int?;
          final peerIp = datagram.address.address;
          if (peerAlias != null && peerPort != null) {
            // Ignore self (optional: compare with local IP/port)
            onDeviceDiscovered!(peerAlias, peerIp, peerPort);
          }
        }
      } catch (_) {}
    });

    // Start broadcasting presence every 2 seconds
    _udpSender = await UDP.bind(Endpoint.any());
    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final msg = json.encode({
        'type': presenceMessageType,
        'alias': alias,
        'port': port,
      });
      await _udpSender?.send(
        utf8.encode(msg),
        Endpoint.multicast(InternetAddress(multicastAddress), port: Port(multicastPort)),
      );
    });
  }

  // Stops all network services.
  void stop() {
    _udpSub?.cancel();
    _udpListener?.close();
    _udpSender?.close();
    _broadcastTimer?.cancel();
    _udpSub = null;
    _udpListener = null;
    _udpSender = null;
    _broadcastTimer = null;
  }

  // TODO: Implement HTTP scan and server logic.
} 