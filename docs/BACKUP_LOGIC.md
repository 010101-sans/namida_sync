# Namida Backup and Music Library Folder Logic

This document details how Namida Sync manages backup and music library folder paths, including default locations, user overrides, platform-specific logic, validation, manifest structure, and Google Drive integration. It serves as a reference for robust folder detection, backup/restore, and error handling in the app.

## 1. Backup Folder Path Logic

### **Default Backup Path**
- **Android:** `/storage/emulated/0/Namida/Backups`
- **Windows:** `C:/Namida/Backups`
- Determined by platform check in [`lib/services/folder_service.dart`](../lib/services/folder_service.dart)

### **User Override**
- Users can override the default backup location using the folder picker UI.
- The selected path is persisted using shared preferences.
- See: [`lib/services/folder_service.dart`](../lib/services/folder_service.dart), [`lib/providers/folder_provider.dart`](../lib/providers/folder_provider.dart)

### **Backup File Format**
- Backups are zip files, e.g., `Namida Backup - yyyy-MM-dd hh.mm.ss.zip`
- The backup includes user data, playlists, settings, etc.

### **Validation and Error Handling**
- The app checks if the backup directory exists and contains at least one `.zip` file before backup/restore.
- If the default or user-selected path is not accessible, the user is prompted to select a valid folder.
- See: [`lib/services/folder_service.dart`](../lib/services/folder_service.dart)

## 2. Music Library Folder Logic

### **Default Music Folders**
- **Android:** `/storage/emulated/0/Music`
- **Windows:** `C:/Users/<User>/Music/Namida`
- Determined by platform check in [`lib/services/folder_service.dart`](../lib/services/folder_service.dart)

### **User Override**
- Users can add or remove music folders using the folder picker UI.
- The selected paths are persisted using shared preferences.
- See: [`lib/services/folder_service.dart`](../lib/services/folder_service.dart), [`lib/providers/folder_provider.dart`](../lib/providers/folder_provider.dart)

### **Validation**
- The app validates that each selected folder exists and contains at least one `.mp3` file (recursively).
- Only folders containing valid music files are considered valid.

## 3. Platform-Specific Logic

- **Android:**
  - Uses `/storage/emulated/0` as the primary storage root.
  - Requires storage/media permissions (including MANAGE_EXTERNAL_STORAGE for Android 11+).
  - See: [`lib/utils/permissions_utils.dart`](../lib/utils/permissions_utils.dart)
- **Windows:**
  - Uses the user's profile directories.
  - Standard file access; no special permissions required.
- Platform checks are performed using Dart's `Platform` class.

## 4. Permissions

- **Android:**
  - Requests and manages storage/media permissions as needed.
  - Uses granular permissions for Android 11+.
  - See: [`lib/utils/permissions_utils.dart`](../lib/utils/permissions_utils.dart)
- **Windows:**
  - Standard file access; no special permissions required.

## 5. Fallbacks and Error Handling

- If the default path is not accessible, the app prompts the user to select a folder.
- All folder paths are validated for existence and accessibility before use.
- User-friendly error messages and recovery options are provided in the UI.
- See: [`lib/screens/dashboard/dashboard_screen.dart`](../lib/screens/dashboard/dashboard_screen.dart), [`lib/widgets/`](../lib/widgets/)

## 6. Manifest Structure and Google Drive Integration

### **Manifest Structure**
- Each backup operation generates a versioned manifest in `/NamidaSync/Manifests/` (e.g., `manifest_{timestamp}_{platform}_{deviceId}.json`).
- The manifest includes:
  - Manifest version, type, timestamp, deviceId, platform
  - Folders (music library entries: label, original path, relative path, file list, original platform)
  - Backup zip info (name, size)
- See: [`lib/models/sync_manifest.dart`](../lib/models/sync_manifest.dart)

### **Manifest Versioning**
- Each backup creates a new manifest file; old manifests are not deleted, allowing for version history.
- See: [`lib/services/google_drive_service.dart`](../lib/services/google_drive_service.dart), [`lib/providers/google_drive_provider.dart`](../lib/providers/google_drive_provider.dart)

### **Backup Workflow**
1. Detect latest backup zip and music folders.
2. Upload backup zip to `/NamidaSync/Backups/`.
3. Upload music files to `/NamidaSync/MusicLibrary/`, preserving folder structure.
4. Generate and upload manifest to `/NamidaSync/Manifests/`.

### **Restore Workflow**
1. List and download the latest manifest from `/NamidaSync/Manifests/`.
2. Show platform compatibility (same/cross-platform).
3. Restore backup zip and/or music folders:
   - **Same platform:** Tries to use original paths, prompts if not found.
   - **Cross-platform:** Always prompts user for restore locations.
4. Download files, show progress, and handle errors/skips.

## 7. Cross-Platform Restore & User Experience

- The app supports all combinations of Android/Windows backup and restore.
- **Same platform:** App tries to use original folder paths, falls back to user prompt if not found.
- **Cross-platform:** App always prompts user for restore locations, with clear UI warnings and platform info.
- Restore card shows platform compatibility (green for same, orange for cross-platform), tracks progress, and allows cancellation.
- Backup and restore state are completely separated in the UI and logic.

## 8. Error Handling & Troubleshooting

- If you see errors during restore, it may indicate a corrupted or incompatible manifest. The app always uploads a new manifest for each backup, so this should be rare.
- All errors are surfaced to the user with actionable messages and options to retry or reselect folders.

## 9. Implementation References

- Folder detection, validation, and persistence: [`lib/services/folder_service.dart`](../lib/services/folder_service.dart)
- Folder state management: [`lib/providers/folder_provider.dart`](../lib/providers/folder_provider.dart)
- Google Drive integration and manifest logic: [`lib/services/google_drive_service.dart`](../lib/services/google_drive_service.dart), [`lib/providers/google_drive_provider.dart`](../lib/providers/google_drive_provider.dart)
- UI for folder selection, status, and error handling: [`lib/screens/dashboard/dashboard_screen.dart`](../lib/screens/dashboard/dashboard_screen.dart), [`lib/widgets/`](../lib/widgets/)
- Permissions handling: [`lib/utils/permissions_utils.dart`](../lib/utils/permissions_utils.dart)
- Manifest model: [`lib/models/sync_manifest.dart`](../lib/models/sync_manifest.dart)