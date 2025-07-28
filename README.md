<img src="assets/images/about/namida_sync_logo.png" alt="Namida Sync Logo" height="160"/>

# Namida Sync

A seamless backup and restore companion app for the [Namida Music & Video Player](https://github.com/namidaco/namida), built in Flutter.  

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
- [How Namida Sync Works](#how-namida-sync-works)
- [Sync Methods](#sync-methods)
- [Installation](#installation)
- [Documentation](#documentation)
- [Special Thanks](#special-thanks)
- [Contributing](#contributing)
- [License](#license)
- [Changelog](#changelog)

## Features

- **One-tap backup & restore** for your Namida player data and music library
- **Two powerful sync methods** to fit your needs:
  - **Google Drive Sync** - Cloud-based backup with automatic sync
  - **Local Network Transfer** - Peer-to-peer sharing without internet
- **Smart file handling** - Incremental sync, skips duplicates, handles large libraries
- **Cross-platform compatibility** - Works seamlessly between Android and Windows
- **Auto-detection** - Finds your latest backup and music folders automatically
- **Folder structure preservation** - Maintains your music organization during transfers

## Getting Started

### 1. Before You Begin
- Create a backup zip file in the Namida app by using its built-in backup feature to generate a backup zip file. Be mindful with what you include while creating the backup.  
- Make sure Namida Sync shows the correct Namida backup and music folder paths. If not, pick them manually.

### 2. Choose Your Sync Method
- **For cloud backup**: Use Google Drive sync
- **For local sharing**: Use Local Network Transfer

### 3. Back Up Your Namida Environment
- **Google Drive**: Tap **Sign in with Google** and then **Backup**
- **Local Network**: Start the server and send to another device

### 4. Restore Your Data
- **Google Drive**: Tap **Restore** to download from cloud
- **Local Network**: Accept incoming transfers from other devices
- After restore, open Namida app and import your backup zip file

## How Namida Sync Works?

### 1. Folder Detection & Validation
- **Auto-detects** default folders :
  - Android : 
    - `/storage/emulated/0/Namida/Backups` 
    - `/storage/emulated/0/Music`
  - Windows : 
    - `C:/Namida/Backups`
- **Custom folders :** Easily select your own backup and music folders using the built-in folder picker functionality.
- **Validation :** Checks for backup zip and music files before syncing.

### 2. Backup & Restore Workflow

- **Backup Process :**
  1. Finds your latest backup zip and music folders on your device.
  2. Creates a manifest with file metadata and structure.
  3. Transfers files using your chosen sync method.
  4. Preserves folder hierarchy and handles duplicates.

- **Restore Process :**
  1. Downloads and reads the manifest.
  2. Checks platform compatibility (Android-Android, Windows-Windows and Android-Windows).
  3. Restores backup zip and music folders (asks for location if needed).
  4. Downloads files, shows progress, skips duplicates, handles errors.

## Sync Methods

### Google Drive Sync

**Perfect for:** Cloud backup and cross-device access

#### Features
- **Cloud Storage**: Secure backup to Google Drive
- **Automatic Sync**: One-tap backup and restore
- **Cross-Device Access**: Access your backups from anywhere
- **Version History**: Keep multiple backup versions
- **Internet Required**: Works with stable internet connection

#### How It Works
1. **Authentication**: Sign in with your Google account
2. **Upload**: Backup zip and music files uploaded to `NamidaSync/` folder
3. **Manifest**: JSON file tracks all transferred files and metadata
4. **Download**: Restore downloads files and restores to your device

#### Structure on Google Drive
```
NamidaSync/
├── MusicLibrary/     # Your music files with folder structure
├── Backups/          # Namida backup zip files
└── Manifests/        # Transfer metadata and file lists
```

### Local Network Transfer

**Perfect for:** Fast local sharing, offline transfers, large libraries

#### Features
- **Peer-to-Peer**: Direct device-to-device transfer
- **No Internet Required**: Works on local network only
- **High Speed**: Much faster than cloud upload/download
- **User Approval**: Accept/decline incoming transfers
- **Real-time Progress**: Live transfer status updates

#### How It Works
1. **Device Discovery**: Uses UDP multicast to find other devices
2. **Server Setup**: Each device runs a local HTTP server
3. **File Transfer**: Direct HTTP transfer between devices
4. **Automatic Restore**: Files restored to configured folders

#### Technical Details
- **Port**: 53317
- **Protocol**: UDP for discovery, HTTP for transfer
- **Security**: Local network only, user approval required
- **Temp Storage**: Platform-specific temporary directories

#### Getting Started with Local Network Transfer

**Setting Up the Server**
1. Go to the **Local Transfer** section in Namida Sync
2. Enter a device alias (e.g., "My Phone", "Work PC")
3. Tap **Start Server** to begin listening for incoming transfers
4. Your device will now be discoverable by other Namida Sync devices

**Sending a Backup**
1. Make sure the target device has its server running
2. Tap **Refresh Devices** to discover available devices
3. Select the target device from the list
4. Tap **Send Backup** to transfer your backup zip and music files
5. The target device will be prompted to accept the transfer

**Receiving a Backup**
1. Keep your server running to receive transfers
2. When a transfer arrives, you'll see a notification
3. Review the transfer details and tap **Accept** or **Decline**
4. If accepted, files will be downloaded and automatically restored

#### Troubleshooting
- **No devices found?** Ensure both devices are on the same network and servers are running.
- **Transfer fails?** Check firewall settings and ensure port 53317 is allowed
- **Windows discovery issues?** Try disabling virtual network adapters in Device Manager and adding an inbound firewall rule for port 53317 (for both, TCP and UDP)

For detailed technical information, see [Local Network Transfer Documentation](docs/LOCAL_NETWORK_TRANSFER.md).

## Pro Tips

### General Tips
- **Music Library Structure**: Put all your music folders into a single parent folder for easier backup and restore
- **Before restoring on a new device**: Make sure your latest backup is available via your chosen sync method
- **Large music libraries**: Local network transfer is often faster than cloud sync for large libraries

### Google Drive Tips
- **Stable connection**: Use a reliable internet connection for cloud backups
- **Storage space**: Check your Google Drive storage before large backups
- **Authentication issues**: Try signing out and back in if you encounter problems

### Local Network Tips
- **Network stability**: Ensure both devices have stable network connections
- **Firewall settings**: Allow Namida Sync through your firewall
- **Device naming**: Use descriptive device aliases for easier identification

### Troubleshooting
- **Android permission issues?** Try re-picking folders and granting permissions again in app settings
- **Backup/Restore issues?** Try signing out of your Google account, then sign back in
- **Interrupted transfers?** Don't worry, Namida Sync skips duplicates on next backup/restore

## Installation

See the [Releases page](https://github.com/010101-sans/namida_sync/releases) for all downloads.

- **Android :**  
  - If you are not sure which version to download, then [download Universal APK](https://github.com/010101-sans/namida_sync/releases/download/v1.0.0/app-release.apk)  
  - If you know your device's architecture, you can download a specific APK from the [Releases page](https://github.com/010101-sans/namida_sync/releases).

- **Windows :**  
  - [Download the Windows ZIP file](https://github.com/010101-sans/namida_sync/releases/download/v1.0.0/NamidaSync-Windows-v1.0.0.zip), extract it to a folder of your choice, and then run `namida_sync.exe` inside the extracted folder.

#### **⭐️ Star this repo if you liked Namida Sync**  

## Documentation

- See the [docs/README.md](docs/README.md) for a full index of technical and design documentation created during development of Namida Sync.
- See the [docs/FAQ.md](docs/FAQ.md) for Common questions and troubleshooting tips for users and contributors.

## Special Thanks

- [@MSOB7YY](https://github.com/MSOB7YY), the creator of [Namida](https://github.com/namidaco/namida) for the original and inspiring project.
- [Flutter Team](https://github.com/flutter/flutter) for the amazing framework.
- All open source package maintainers and contributors who make Namida Sync possible.

## Logo Attribution

- The Namida Sync logo was created by me, based on Namida's official logo, in a minimal vector art style.

## Contributing

- Found a bug or have a feature request? [Open an issue](../../issues)
- Want to help out? See our [CONTRIBUTING.md](CONTRIBUTING.md)
- Please read our [Code of Conduct](CODE_OF_CONDUCT.md)

## License

This project is licensed under the [MIT License](LICENSE).

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes and version history.