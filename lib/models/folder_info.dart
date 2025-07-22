import 'package:flutter/foundation.dart';

enum FolderType { backup, music }

enum FolderStatus { valid, invalid, unknown }

// [1] Immutable model representing a folder's path, type, and validation status.
@immutable
class FolderInfo {
  final String path;
  final FolderType type;
  final FolderStatus status;

  const FolderInfo({
    required this.path,
    required this.type,
    this.status = FolderStatus.unknown,
  });

  // [2] Returns a copy of this FolderInfo with updated fields.
  FolderInfo copyWith({
    String? path,
    FolderType? type,
    FolderStatus? status,
  }) {
    return FolderInfo(
      path: path ?? this.path,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
  // [3] Equality operator to compare FolderInfo objects by their fields.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderInfo &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          type == other.type &&
          status == other.status;

  @override
  int get hashCode => path.hashCode ^ type.hashCode ^ status.hashCode;
} 