# Google Drive Integration in Namida Sync

This document details how Google Drive integration is implemented in Namida Sync, including authentication, folder structure, manifest logic, upload/download flows, error handling, and references to relevant code files. It is intended for developers and advanced users who want to understand or extend the cloud sync features.

## 1. Overview

Namida Sync uses Google Drive to securely back up and restore Namida music player data (backups and music library) across devices and platforms. All cloud operations are performed via the official Google APIs and OAuth2 authentication.

## 2. Authentication

- **OAuth2 via Google Sign-In (setup with Flutterfire Configure with Firebase)**
  - Uses [`google_sign_in_all_platforms`](https://pub.dev/packages/google_sign_in_all_platforms) for user authentication.
  - Scopes: `https://www.googleapis.com/auth/drive.file`, `email`
  - Handles sign-in, sign-out, and silent sign-in for seamless UX.
  - See: [`lib/services/google_auth_service.dart`](../lib/services/google_auth_service.dart), [`lib/providers/google_auth_provider.dart`](../lib/providers/google_auth_provider.dart)

## 3. Google Drive Folder Structure

All app data is stored in a dedicated app folder on the user's Drive:

```
/NamidaSync/
  ├── Backups/           # All Namida backup zip files
  ├── MusicLibrary/      # All music files (mirroring local folder structure)
  └── Manifests/         # All backup manifest files
```

- Folders are created automatically if they do not exist.
- See: [`lib/services/google_drive_service.dart`](../lib/services/google_drive_service.dart)

## 4. Manifest Logic

- Each backup operation generates a manifest in `/NamidaSync/Manifests/` (e.g., `manifest_2024-06-10T12-34-56Z_android_deviceid.json`).
- The manifest includes:
  - Manifest version, type, timestamp, deviceId, platform
  - Folders (music library entries: label, original path, relative path, file list, original platform)
  - Backup zip info (name, size)
- Before uploading a new manifest, any existing manifest for the same backup is not deleted (versioned manifests are kept).
- See: [`lib/models/sync_manifest.dart`](../lib/models/sync_manifest.dart), [`lib/services/google_drive_service.dart`](../lib/services/google_drive_service.dart), [`lib/providers/google_drive_provider.dart`](../lib/providers/google_drive_provider.dart)

## 5. Upload Flow (Backup)

1. **User initiates backup** (via dashboard UI)
2. **App authenticates** with Google (if not already signed in)
3. **App ensures** `/NamidaSync/Backups/`, `/NamidaSync/MusicLibrary/`, and `/NamidaSync/Manifests/` exist
4. **Backup zip** is uploaded to `/NamidaSync/Backups/`
5. **Music folders** are uploaded to `/NamidaSync/MusicLibrary/`, preserving folder structure
6. **Manifest** is generated and uploaded to `/NamidaSync/Manifests/` (versioned by timestamp, platform, device)
7. **Progress and errors** are shown in the UI

**Code references:**
- [`lib/providers/google_drive_provider.dart`](../lib/providers/google_drive_provider.dart) (`backupToDrive`)
- [`lib/services/google_drive_service.dart`](../lib/services/google_drive_service.dart) (`uploadFileOptimized`, `uploadFolderOptimized`, `listSyncManifests`, `ensureAppFolder`, `ensureSubfolder`)

## 6. Download Flow (Restore)

1. **User initiates restore** (via dashboard UI)
2. **App authenticates** with Google (if not already signed in)
3. **App lists and downloads** the latest manifest from `/NamidaSync/Manifests/`
4. **App checks** platform compatibility (shows warning if cross-platform)
5. **Backup zip** is downloaded to the selected folder (or prompts user)
6. **Music files** are downloaded to the selected folders (or prompts user)
7. **Progress and errors** are shown in the UI

**Code references:**
- [`lib/providers/google_drive_provider.dart`](../lib/providers/google_drive_provider.dart) (`restoreFromDrive`)
- [`lib/services/google_drive_service.dart`](../lib/services/google_drive_service.dart) (`downloadSyncManifest`, `downloadFilesFromManifest`, `listSyncManifests`)

## 7. Error Handling

- **Authentication errors**: Shown in the UI, with options to retry sign-in
- **File/folder not found**: User is prompted to select a valid folder
- **Manifest errors**: If manifest is missing or corrupted, user is notified and can retry backup
- **Network errors**: All upload/download operations are wrapped in try/catch and surfaced to the user
- **Progress indicators**: Shown for all long-running operations
- **Skipped/failed files**: Tracked and shown in the UI, with options to retry

## 8. Advanced: API & Helper Methods

- **Drive API client**: [`getDriveClient`](../lib/services/google_drive_service.dart)
- **Folder creation**: [`ensureAppFolder`, `ensureSubfolder`, `ensureDrivePath`](../lib/services/google_drive_service.dart)
- **File upload/download**: [`uploadFileOptimized`, `downloadFile`](../lib/services/google_drive_service.dart)
- **Recursive folder upload**: [`uploadFolderOptimized`](../lib/services/google_drive_service.dart)
- **Manifest management**: [`listSyncManifests`, `downloadSyncManifest`](../lib/services/google_drive_service.dart)

## 9. Diagrams & Flowcharts

### **Backup Flow**

```
User initiates backup
    Authenticate with Google
        Ensure Drive folders exist
            Upload backup zip
                Upload music folders
                    Generate & upload manifest
                        Show progress/errors in UI
```

### **Restore Flow**

```
User initiates restore
    Authenticate with Google
        List & download latest manifest
            Check platform compatibility
                Download backup zip
                    Download music files
                        Show progress/errors in UI
```

## 10. References

- [`lib/services/google_drive_service.dart`](../lib/services/google_drive_service.dart)
- [`lib/providers/google_drive_provider.dart`](../lib/providers/google_drive_provider.dart)
- [`lib/models/sync_manifest.dart`](../lib/models/sync_manifest.dart)
- [`lib/services/google_auth_service.dart`](../lib/services/google_auth_service.dart)
- [`lib/providers/google_auth_provider.dart`](../lib/providers/google_auth_provider.dart)
- [Google Drive API docs](https://developers.google.com/drive)