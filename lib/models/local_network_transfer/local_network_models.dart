// [1] DiscoveredDevice: Model for a discovered device on the network.
class DiscoveredDevice {
  final String alias;
  final String ip;
  final int port;
  final String uuid;
  // Add more fields as needed (e.g., device type, OS)
  DiscoveredDevice({required this.alias, required this.ip, required this.port, required this.uuid});
}

// [2] BackupItem: Represents a backup item (file or folder) to transfer.
class BackupItem {
  final String name;
  final String path;
  final String type;    // 'zip' or 'folder'
  final String? status; // uploading, uploaded, downloading, downloaded, skipped, etc.
  BackupItem({required this.name, required this.path, required this.type, this.status});
  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'type': type,
    if (status != null) 'status': status,
  };
  BackupItem copyWith({String? name, String? path, String? type, String? status}) => BackupItem(
    name: name ?? this.name,
    path: path ?? this.path,
    type: type ?? this.type,
    status: status ?? this.status,
  );
}

// [3] LocalNetworkSession: Represents a local network transfer session (to be expanded).
class LocalNetworkSession {
  final Map<String, dynamic> manifest;
  final List<BackupItem> files;
  final Map<String, double> progress; // file name -> progress (0.0 - 1.0)
  bool accepted;
  String? error;

  LocalNetworkSession({
    required this.manifest,
    required this.files,
    Map<String, double>? progress,
    this.accepted = false,
    this.error,
  }) : progress = progress ?? {};

  void updateProgress(String file, double value) {
    progress[file] = value;
  }

  void setError(String err) {
    error = err;
  }
} 