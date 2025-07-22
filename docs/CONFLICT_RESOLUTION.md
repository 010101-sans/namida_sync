# Conflict Resolution in Namida Sync

This document explains how Namida Sync detects and resolves conflicts when backing up and restoring your music library and backup folders, including handling manual changes, cross-platform differences, and syncing empty folders.

## Overview

Namida Sync is built for **reliable, incremental sync** and **cross-platform restore** (Android ↔ Windows). Its conflict resolution system ensures:

- **Manually added folders/files** are detected, and users are prompted to choose where to restore them if needed.
- **Removed folders/files** are cleaned up from Google Drive and the manifest.
- **Cross-platform restores** handle path and folder differences.
- **Empty folders** are also detected and synced, ensuring your folder structure is preserved even if no files are present.
- **Users are always informed** about detected conflicts and can choose how to resolve them.

## Common Conflict Scenarios

### 1. Manual Addition of Folders/Files

**Scenario:**  
You add a new folder or file (including empty folders) to your local music library that does not exist in Google Drive or the manifest.

**How Namida Sync handles it:**
- **Backup:** The app detects new folders/files (including empty folders) and uploads them to Drive. The manifest is updated.
- **Restore:** When restoring, if a folder or file from the manifest does not have a matching path on the current device, Namida Sync will prompt you to either select an existing path or choose a location to restore it as a subfolder of. This ensures that new additions are placed where you want them, even across platforms.
- **UI:** New items show an orange "New" indicator until they are backed up.

### 2. Manual Removal of Folders/Files

**Scenario:**  
You delete a folder or file locally, but it still exists in Google Drive and/or the manifest.

**How Namida Sync handles it:**
- **Backup:** The app detects removed items and deletes them from Drive and the manifest.
- **Restore:** If the manifest and local state differ, the app prompts you to sync the manifest or keep the cloud version.
- **UI:** Removed items disappear from the local list.

### 3. Cross-Platform Path Differences

**Scenario:**  
You restore a backup created on Android to Windows, or vice versa.

**How Namida Sync handles it:**
- **Restore:** The app prompts you to pick a valid restore location for each folder, since original paths may not exist on the new platform.
- **Manifest:** Paths are updated to reflect the new platform.
- **Compatibility:** The manifest tracks the original platform and new paths for seamless future syncs.