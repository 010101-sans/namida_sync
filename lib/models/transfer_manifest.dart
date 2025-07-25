class TransferManifest {
  final String backupName;
  final List<TransferFileEntry> files;
  // Add more metadata fields as needed (e.g., createdAt, device info, etc.)

  TransferManifest({
    required this.backupName,
    required this.files,
  });
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
} 