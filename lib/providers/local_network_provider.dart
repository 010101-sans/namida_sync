import 'package:flutter/material.dart';
import '../services/local_network_service.dart';

// Provider for managing local network backup/restore state.
// Tracks discovered devices, current session, and progress.
class LocalNetworkProvider extends ChangeNotifier {
  final LocalNetworkService _service = LocalNetworkService();

  // List of discovered devices on the local network.
  final List<DiscoveredDevice> devices = [];

  // Current transfer session state (if any).
  LocalNetworkSession? currentSession;

  // Starts device discovery. Pass in this device's alias and port.
  Future<void> startDiscovery({required String alias, required int port}) async {
    devices.clear();
    await _service.startUdpDiscovery(
      alias: alias,
      port: port,
      onDiscovered: (peerAlias, peerIp, peerPort) {
        // Avoid duplicates
        if (!devices.any((d) => d.ip == peerIp && d.port == peerPort)) {
          devices.add(DiscoveredDevice(alias: peerAlias, ip: peerIp, port: peerPort));
          debugPrint('[LAN] Discovered device: $peerAlias @ $peerIp:$peerPort');
          notifyListeners();
        }
      },
    );
  }

  // Stops all network activity.
  void stop() {
    _service.stop();
    devices.clear();
    notifyListeners();
  }
}

// Model for a discovered device (to be expanded).
class DiscoveredDevice {
  final String alias;
  final String ip;
  final int port;
  // Add more fields as needed (platform, deviceId, etc.)

  DiscoveredDevice({required this.alias, required this.ip, required this.port});
}

// Model for a local network transfer session (to be expanded).
class LocalNetworkSession {
  // Add fields for manifest, progress, errors, etc.
} 