# Platform Paths Resolution in Namida Sync

## Problem: Path Separator Inconsistency

Namida Sync is a cross-platform application (Windows, Android, etc.) that manages file and folder paths for backup and restore operations. Different platforms use different path separators:
- **Windows:** Backslash (`\`)
- **Unix-like (Linux, macOS, Android):** Forward slash (`/`)

This inconsistency can cause issues when:
- Comparing or matching file/folder paths between the UI and provider/state.
- Using paths as keys in maps (e.g., for progress/status updates).
- Displaying or searching for files/folders in the UI.

**Example Issue:**
- The provider stores progress for a file as `C:/Music/Folder/Song.mp3` (forward slashes).
- The UI tries to look up status using `C:\Music\Folder\Song.mp3` (backslashes).
- The lookup fails, and the UI shows "Pending" or no status.

## Solution: Path Normalization to Forward Slashes

To ensure reliable matching and status updates across all platforms, **all paths are normalized to use forward slashes (`/`)** before being used as keys, compared, or displayed in the UI.

### Implementation Pattern

- **When storing or updating progress/status:**
  - Always convert the file/folder path to use `/`.
  - Example: `normalizedPath = filePath.replaceAll('\\', '/')`

- **When matching or looking up status in the UI:**
  - Normalize the path before lookup.
  - Example: `normalizedZipPath = (lastRestoreZipPath ?? '').replaceAll('\\', '/')`

- **When building lists of folder paths for matching:**
  - Normalize all folder paths before using them for `.startsWith()` or display.
  - Example:
    ```dart
    final normalizedMusicFolders = validMusicFolders
        .map((p) => p.replaceAll('\\', '/'))
        .toList();
    ```

### Example Code Snippet

```dart
// Normalize file path before using as a key
final normalizedPath = filePath.replaceAll('\\', '/');
restoreFileProgress[normalizedPath] = progress;

// Normalize folder paths for UI matching
final normalizedMusicFolders = validMusicFolders
    .map((p) => p.replaceAll('\\', '/'))
    .toList();

// Use normalized paths for all status lookups
buildStatusLabel(
  context,
  status: getRestoreFileStatus(
    driveProvider,
    normalizedPath,
    driveProvider.restoreFileFailed,
    driveProvider.restoreSkippedFiles,
    driveProvider.restoreFileProgress,
  ),
),
```

## Benefits
- **Consistent status updates** for backup zip and music files across all platforms.
- **No more "Pending" or missing status** due to path mismatches.
- **Future-proof:** Any new platform or file operation will work as long as paths are normalized.

## Recommendation
- **Always normalize paths to forward slashes** in all cross-platform file/folder operations, especially when using them as keys or for matching.
- Document this pattern in code comments and future PRs.