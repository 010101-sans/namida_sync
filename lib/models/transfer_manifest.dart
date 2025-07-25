class TransferManifest {
  final String backupName;
  final List<TransferFileEntry> files;
  // Add more metadata fields as needed (e.g., createdAt, device info, etc.)

  TransferManifest({
    required this.backupName,
    required this.files,
  });

  factory TransferManifest.fromJson(Map<String, dynamic> json) {
    return TransferManifest(
      backupName: json['backupName'] as String,
      files: (json['files'] as List)
          .map((f) => TransferFileEntry.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TransferFileEntry {
  final String name;
  final String path;
  final int size;
  final String folderLabel; // Top-level music folder label
  final String relativePath; // Path relative to the music folder root
  // Add more fields as needed (e.g., hash, type)

  TransferFileEntry({
    required this.name,
    required this.path,
    required this.size,
    required this.folderLabel,
    required this.relativePath,
  });

  static TransferFileEntry fromJson(Map<String, dynamic> json) {
    return TransferFileEntry(
      name: json['name'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      folderLabel: json['folderLabel'] as String,
      relativePath: json['relativePath'] as String,
    );
  }
} 