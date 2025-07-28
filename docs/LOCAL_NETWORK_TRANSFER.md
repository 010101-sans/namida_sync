# Local Network Transfer

## Overview

The Local Network Transfer feature in Namida Sync enables users to transfer backup files and music libraries between devices on the same local network (LAN or Wi-Fi). This feature uses a combination of UDP multicast for device discovery and HTTP for file transfer operations, inspired by [LocalSend](https://github.com/localsend/localsend), but tailored for Namida Sync's backup/restore needs.

## Features

- **Device Discovery**: Automatic discovery of other Namida Sync devices on the local network
- **Peer-to-Peer Transfer**: Direct file transfer between devices without cloud storage
- **User Approval**: Required confirmation before accepting incoming transfers
- **Progress Tracking**: Real-time progress updates during file transfers
- **Cross-Platform**: Works between Android and Windows devices
- **Folder Structure Preservation**: Maintains music folder hierarchy during transfer
- **Duplicate Handling**: Skips existing files to avoid unnecessary transfers
- **Error Recovery**: Graceful handling of network interruptions and failures

## Glossary

### Core Terms
- **Backup**: A collection of files (music files and backup zip) that can be transferred between devices
- **Manifest**: A JSON file containing metadata about files to be transferred (names, sizes, paths)
- **Device Alias**: A user-defined name to identify a device on the network
- **Device UUID**: A unique identifier assigned to each device for consistent identification across sessions

### Network Terms
- **UDP (User Datagram Protocol)**: A network protocol used for fast, connectionless communication. Used for device discovery via multicast
- **Multicast**: Broadcasting packets to multiple devices simultaneously on a local network
- **Hello Packet**: A UDP message broadcast by devices to announce their presence, containing:
  - Device alias
  - Port number
  - Device UUID
- **Local Network**: A private network (like home WiFi) where devices can directly communicate
- **Port**: A network endpoint (default: 53317) used for communication between devices
- **HTTP**: Protocol used for reliable file transfers after device discovery

### Technical Components
- **Server**: HTTP server running on each device to handle file transfers
- **Provider**: Component that handles callbacks and user interactions during transfers
- **Temp Directory**: Temporary storage location for received files before restoration:
  - Windows: `C:/NamidaSync`
  - Android: `/storage/emulated/0/NamidaSync`
  - Other: System temp directory/NamidaSync

### Transfer Process Terms
- **Device Discovery**: Process of finding other devices on the network using:
  1. UDP multicast (primary method)
  2. HTTP subnet scan (fallback method)
- **Transfer Session**: A complete backup transfer including:
  1. Manifest transfer and approval
  2. Backup zip transfer
  3. Music files transfer
- **Restore**: Process of moving received files from temp directory to final locations

### Security Terms
- **Device Authentication**: Simple identification using UUID (no passwords/encryption)
- **User Approval**: Required confirmation before accepting incoming transfers
- **Local-only Transfer**: Transfers restricted to local network for security

### File Types
- **Backup Zip**: Contains app settings and backup data
- **Music Files**: Audio files being transferred
- **Manifest File**: JSON file describing the transfer contents

### Status & Events
- **Transfer Progress**: Real-time status of file transfers
- **Server Status**: Whether a device is ready to send/receive
- **Transfer Completion**: Successful receipt of all expected files
- **Transfer Cancellation**: User-initiated stop of transfer process

### Error Categories
- **Network Errors**: Connection/discovery failures
- **File Errors**: Read/write/permission issues
- **Transfer Errors**: Incomplete or failed transfers
- **Restore Errors**: Issues moving files to final location

## Architecture

### Core Components

- **LocalNetworkService** : Handles all network operations, device discovery, HTTP server, and file transfer logic.
- **LocalNetworkProvider** : Manages state, and business logic for the transfer process.
- **UI Components** : Three main cards for setup, sending, and receiving, integrated into the dashboard.
- **Data Models** : Represent devices, manifests, files, and transfer sessions.

## File Structure

```
lib/
|
+---services
|       local_network_service.dart           # Core network operations                                              
|   
+---providers
|       local_network_provider.dart          # State management                                             
|
+---models
|       local_network_transfer/
|           local_network_models.dart        # Device and session models
|           transfer_manifest.dart           # Transfer manifest structure
|                                                       
+---screens
    |                                                       
    \---dashboard
        \---local_transfer                                               
                local_transfer_page.dart         # Main page container                                                 
                local_setup_card.dart            # Server setup and configuration                                               
                local_send_backup_card.dart      # Send backup to other devices                                             
                local_recieve_backup_card.dart   # Receive backup from other devices
+---utils
        local_transfer_utils.dart               # UI utilities and status helpers
```

## Data Models

### DiscoveredDevice
Represents a device found on the local network.
```dart
class DiscoveredDevice {
  final String alias;
  final String ip;
  final int port;
  final String uuid;
}
```

### TransferManifest & TransferFileEntry
Describes the backup and all files to be transferred.
```dart
class TransferManifest {
  final String backupName;
  final List<TransferFileEntry> files;
}
class TransferFileEntry {
  final String name;
  final String path;
  final int size;
  final String folderLabel;
  final String relativePath;
}
```

### BackupItem
Represents a file or folder to transfer, with status for UI.
```dart
class BackupItem {
  final String name;
  final String path;
  final String type; // 'zip' or 'folder'
  final String? status; // uploading, uploaded, etc.
}
```

### LocalNetworkSession
Tracks a transfer session, including manifest, files, progress, and error state.
```dart
class LocalNetworkSession {
  final Map<String, dynamic> manifest;
  final List<BackupItem> files;
  final Map<String, double> progress;
  bool accepted;
  String? error;
}
```

## Service Layer : LocalNetworkService

### Device Discovery
- **UDP Multicast** : Sends and listens for hello packets on `224.0.0.251:53317`.
- **HTTP Subnet Scan** : Scans local subnet for devices running the server.
- **Deduplication** : Filters out self and merges results.

### HTTP Server
- Runs on port 53317.
- Handles endpoints :
  - `POST /api/namidasync/v1/register` (device registration)
  - `POST /api/namidasync/v1/prepare-upload` (manifest exchange)
  - `POST /api/namidasync/v1/upload` (file upload)
  - `POST /api/namidasync/v1/cancel` (cancel transfer)

### File Management
- Received files are saved to platform-specific temp directories :
  - Windows : `C:/NamidaSync/`
  - Android : `/storage/emulated/0/NamidaSync/`
- Structure :
  - `NamidaSync/Manifests/manifest.json`
  - `NamidaSync/Backups/<backup zip>`
  - `NamidaSync/MusicLibrary/<folder>/<file>`

### Transfer Flow
- **Send**: Build manifest -> send to peer -> send backup zip -> send music files (with progress)
- **Receive**: Accept/decline manifest -> receive files -> trigger restore
- **Restore**: Move/copy files to user-configured backup/music folders

### Error Handling
- All network/file errors are caught and reported to the provider for UI display.
- User can cancel transfers at any time.
- Duplicate/parallel transfers are prevented.

## State Management : LocalNetworkProvider

- Tracks discovered devices, current session, progress, error, and server state.
- Orchestrates device discovery, sending, receiving, and restore.
- Exposes methods for UI to start/stop server, refresh devices, send/cancel transfer, etc.
- Handles user prompts for incoming transfers and triggers restore logic.

## UI Components

### local_transfer_page.dart
- Main container for the local transfer feature.
- Sets up provider callbacks for incoming backup and restore completion.
- Arranges the three main cards vertically.

### local_setup_card.dart
- Lets user configure device alias and start/stop the local server.
- Shows current network address and server status.
- Provides help text for troubleshooting.

### local_send_backup_card.dart
- Lists discovered devices and allows selection.
- Lets user pick backup zip and music folders (auto-detected from FolderProvider).
- Shows transfer progress, error, and success messages.
- Handles sending backup and music files to the selected device.

### local_recieve_backup_card.dart
- Shows server status and incoming transfer notifications.
- Lets user accept/decline incoming transfers.
- Displays receiving progress, error, and success messages.
- Triggers restore to user folders after successful transfer.

## User Flow

### Sending a Backup
1. User starts server and configures device alias.
2. User refreshes device list and selects a target device.
3. User clicks "Send Backup". Then Namida Sync :
   - Builds a manifest of the backup zip and all music files.
   - Sends the manifest to the target device for approval.
   - If accepted, sends the backup zip, then music files, with progress updates.
   - Shows error or success message.

### Receiving a Backup
1. User starts server and waits for incoming transfers.
2. When a manifest arrives, user is prompted to accept/decline.
3. If accepted, files are received and saved to temp directories.
4. After all files are received, the app restores them to the configured backup/music folders.
5. User sees progress and completion status.

## Error Handling & Troubleshooting
- All errors (network, file, permission) are surfaced in the UI.
- User can cancel transfers at any time.
- If no devices are found, user is prompted to check network/firewall.
- If restore fails, user is notified and can retry.

## Security & Permissions
- Transfers are local network only (no internet exposure).
- User approval is required for all incoming transfers.
- Files are saved to temp directories and only restored after user confirmation.
- No persistent authentication, device UUID is used for identification.

## Platform Support
- **Windows** : Full support (tested)
  - **Note** : On Windows, if device discovery isn't working, try disabling virtual network adapters (like VirtualBox Host-Only Network) in Device Manager, as they can interfere with UDP multicast discovery
- **Android** : Full support (tested)

## Dependencies
- `udp: ^5.0.3` - For UDP multicast communication
- `multicast_dns: ^0.3.0` - For device discovery
- `uuid: ^4.5.1` - For device identification
- `http` - For HTTP server and client operations

## Future (possible) Enhancements
- [ ] Resume/interrupt transfers
- [ ] Batch/multi-device transfers
- [ ] Compression/encryption
- [ ] WebRTC for direct P2P
- [ ] Transfer history/log