import 'dart:convert';

// [1] Represents the manifest for a sync operation, including backup and restore metadata.
class SyncManifest {
  final int manifestVersion;
  final String type; // 'backup' or 'restore'
  final DateTime timestamp;
  final String deviceId;
  final String platform;
  final List<SyncFolder> folders;
  final SyncBackupZip backupZip;

  SyncManifest({
    required this.manifestVersion,
    required this.type,
    required this.timestamp,
    required this.deviceId,
    required this.platform,
    required this.folders,
    required this.backupZip,
  });

  // [2] Convert this SyncManifest object to a JSON string for storage or network transfer.
  String toJsonString() {
    final json = jsonEncode({
      'manifestVersion': manifestVersion,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
      'platform': platform,
      'folders': folders.map((e) => e.toJson()).toList(),
      'backupZip': backupZip.toJson(),
    });
    // debugPrint('[SyncManifest] Serialized to JSON: $json');
    return json;
  }

  // [3] Create a SyncManifest object from a JSON string.
  factory SyncManifest.fromJsonString(String jsonString) {
    // debugPrint('[SyncManifest] Deserializing from JSON: $jsonString');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SyncManifest(
      manifestVersion: json['manifestVersion'] as int? ?? 2,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceId: json['deviceId'] as String,
      platform: json['platform'] as String,
      folders: (json['folders'] as List).map((e) => SyncFolder.fromJson(e as Map<String, dynamic>)).toList(),
      backupZip: SyncBackupZip.fromJson(json['backupZip'] as Map<String, dynamic>),
    );
  }
}

// [4] Represents a folder included in the sync manifest, with its files and metadata.
class SyncFolder {
  final String label;
  final String originalPath;
  final String relativePath;
  final String platform;
  final List<SyncFile> files;

  SyncFolder({
    required this.label,
    required this.originalPath,
    required this.relativePath,
    required this.platform,
    required this.files,
  });

  // [5] Convert this SyncFolder object to a JSON map.
  Map<String, dynamic> toJson() {
    final json = {
      'label': label,
      'originalPath': originalPath,
      'relativePath': relativePath,
      'platform': platform,
      'files': files.map((e) => e.toJson()).toList(),
    };
    // debugPrint('[SyncFolder] Serialized to JSON: $json');
    return json;
  }

  // [6] Create a SyncFolder object from a JSON map.
  factory SyncFolder.fromJson(Map<String, dynamic> json) {
    // debugPrint('[SyncFolder] Deserializing from JSON: $json');
    return SyncFolder(
      label: json['label'] as String? ?? '',
      originalPath: json['originalPath'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      files: (json['files'] as List).map((e) => SyncFile.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

// [7] Represents a file within a synced folder, including its name, size, and last modified date.
class SyncFile {
  final String name;
  final int size;
  final DateTime lastModified;

  SyncFile({required this.name, required this.size, required this.lastModified});

  // [8] Convert this SyncFile object to a JSON map.
  Map<String, dynamic> toJson() {
    final json = {'name': name, 'size': size, 'lastModified': lastModified.toIso8601String()};
    // debugPrint('[SyncFile] Serialized to JSON: $json');
    return json;
  }

  // [9] Create a SyncFile object from a JSON map.
  factory SyncFile.fromJson(Map<String, dynamic> json) {
    // debugPrint('[SyncFile] Deserializing from JSON: $json');
    return SyncFile(
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      lastModified: DateTime.parse(json['lastModified'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

// [10] Represents the backup zip file included in the sync manifest.
class SyncBackupZip {
  final String name;
  final int size;
  final DateTime lastModified;

  SyncBackupZip({required this.name, required this.size, required this.lastModified});

  // [11] Convert this SyncBackupZip object to a JSON map.
  Map<String, dynamic> toJson() {
    final json = {'name': name, 'size': size, 'lastModified': lastModified.toIso8601String()};
    // debugPrint('[SyncBackupZip] Serialized to JSON: $json');
    return json;
  }

  // [12] Create a SyncBackupZip object from a JSON map.
  factory SyncBackupZip.fromJson(Map<String, dynamic> json) {
    // debugPrint('[SyncBackupZip] Deserializing from JSON: $json');
    return SyncBackupZip(
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      lastModified: DateTime.parse(json['lastModified'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
