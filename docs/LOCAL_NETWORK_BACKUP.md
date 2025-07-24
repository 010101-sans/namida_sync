# Local Network Backup/Restore Architecture for Namida Sync  
*Inspired by LocalSend*

## 1. Overview

This document describes how to implement a **local network backup/restore** feature in Namida Sync, using the proven architecture and patterns from [LocalSend](https://github.com/localsend/localsend). The goal is to enable users to transfer backup files and music libraries directly between devices on the same LAN/Wi-Fi, without using cloud storage.

## 2. Key Concepts from LocalSend

### 2.1 Device Discovery

- **Multicast UDP (mDNS-like):**  
  LocalSend uses UDP multicast to broadcast its presence and discover peers on the same network.
- **HTTP/TCP Fallback:**  
  If multicast fails, it scans the local subnet using HTTP requests.
- **Signaling (WebRTC):**  
  For advanced scenarios, LocalSend can use a signaling server for peer discovery, but for LAN backup, multicast and HTTP are sufficient.

### 2.2 Secure Local HTTP(S) Server

- Each device runs a local HTTP(S) server (default port: 53317).
- TLS certificates are generated on the fly for HTTPS.
- All file transfers and API calls are RESTful and secured.

### 2.3 Transfer Protocol

- **Session-based:**  
  Each transfer is a session, with metadata exchanged before file transfer.
- **REST API Endpoints:**  
  - `/api/localsend/v2/register` - Device registration
  - `/api/localsend/v2/prepare-upload` - Initiate file transfer, send manifest/metadata
  - `/api/localsend/v2/upload` - Actual file upload (POST)
  - `/api/localsend/v2/cancel` - Cancel session
- **PIN/Confirmation:**  
  Optionally, a PIN or user confirmation is required before accepting files.

### 2.4 File/Folder Transfer

- **Chunked Streaming:**  
  Files are streamed in chunks with progress reporting.
- **Directory Support:**  
  Folders are zipped or sent recursively, preserving structure.
- **Metadata:**  
  Each file includes name, size, type, and optional hash.

### 2.5 Session & State Management

- **Session objects** track transfer state, progress, errors, and user actions.
- **Manifest:**  
  A manifest (JSON) describing the backup is sent before the actual files, similar to Namida Sync’s Google Drive manifest.

### 2.6 Permissions & UX

- **Permissions:**  
  Requests storage/network permissions as needed.
- **UI:**  
  Shows discovered devices, transfer progress, errors, and allows user to accept/decline transfers.

## 3. Adapting LocalSend Logic to Namida Sync

### 3.1 Architecture Overview

- **Add a LocalNetworkProvider** (similar to `GoogleDriveProvider`) for backup/restore.
- **Device Discovery:**  
  Use UDP multicast and HTTP subnet scan to find peers.
- **Server:**  
  Each device runs a local HTTP(S) server for receiving files.
- **Client:**  
  The sending device acts as a client, initiating backup/restore sessions.

### 3.2 API & Protocol

- **Endpoints:**  
  - `/api/namidasync/v1/register` - Register device
  - `/api/namidasync/v1/prepare-upload` - Send manifest/metadata
  - `/api/namidasync/v1/upload` - Upload backup zip/music folders
  - `/api/namidasync/v1/cancel` - Cancel session
- **Manifest:**  
  Use the same manifest structure as cloud backup for compatibility.

### 3.3 Transfer Flow

#### **Backup (Send)**
1. **Discover devices** on the network.
2. **User selects a target device** for backup.
3. **Send manifest** (JSON) describing the backup.
4. **Target device prompts user** to accept/decline.
5. **If accepted, send backup zip and/or music folders** via HTTP(S) POST.
6. **Show progress and handle errors.**

#### **Restore (Receive)**
1. **Device advertises itself** as available for restore.
2. **Sender discovers and selects this device.**
3. **Sender sends manifest, then files.**
4. **Receiver saves files to appropriate folders, updating progress.**

### 3.4 Security

- **HTTPS by default:**  
  Generate self-signed certificates on each device.
- **PIN/Confirmation:**  
  Optionally require a PIN or user confirmation before accepting files.
- **No data leaves the local network.**

### 3.5 Error Handling

- **Session timeouts, network errors, permission issues** are surfaced to the user.
- **Partial transfers** can be resumed or retried.

## 4. Implementation Steps

### 4.1 Core Components

- **Device Discovery Service:**  
  - UDP multicast listener/broadcaster.
  - HTTP subnet scanner.
- **Local HTTP(S) Server:**  
  - REST API for manifest, file upload, session control.
- **Transfer Client:**  
  - Initiates sessions, sends manifest/files, handles responses.
- **Session/State Management:**  
  - Track progress, errors, and user actions.
- **UI Integration:**  
  - Device picker, progress dialogs, error messages.

### 4.2 Example File/Folder Structure

```
lib/
  providers/
    local_network_provider.dart   # New provider for LAN backup/restore
  services/
    local_network_service.dart    # Discovery, server, client logic
  models/
    transfer_session.dart         # Session state, progress, errors
    transfer_manifest.dart        # Manifest (reuse existing)
  widgets/
    device_picker.dart            # UI for selecting target device
    transfer_progress.dart        # UI for showing progress
```

## 5. Key Code Patterns from LocalSend

- **Device Discovery:**  
  See `provider/network/nearby_devices_provider.dart`, `provider/network/scan_facade.dart`
- **Server Setup:**  
  See `provider/network/server/server_provider.dart`, `util/simple_server.dart`
- **Session Management:**  
  See `model/state/send/send_session_state.dart`, `model/state/server/receive_session_state.dart`
- **REST API:**  
  See `provider/network/server/controller/receive_controller.dart`, `send_controller.dart`
- **File Streaming:**  
  See `util/native/file_saver.dart`
- **Security:**  
  See `provider/security_provider.dart`, `util/rhttp.dart`

## 6. Security & Best Practices

- **Always use HTTPS** for file transfers.
- **Validate all incoming requests** (manifest, file size/type, etc.).
- **Prompt user before accepting files** (optionally with PIN).
- **Handle permissions** (storage, network) gracefully.
- **Show clear progress and error messages** in the UI.

## 7. References

- [LocalSend GitHub](https://github.com/localsend/localsend)
- [LocalSend Protocol Documentation](https://github.com/localsend/protocol)
- [LocalSend README](https://github.com/localsend/localsend/blob/main/README.md)
- [Namida Sync Backup Logic](../docs/BACKUP_LOGIC.md)
- [Namida Sync Google Drive Integration](../docs/GOOGLE_DRIVE_INTEGRATION.md)

## 8. Example API Flow

### **1. Device Discovery**
- Device A broadcasts UDP packet:  
  `{ "alias": "DeviceA", "port": 53317, ... }`
- Device B responds with its info.

### **2. Register Session**
- POST `/api/namidasync/v1/register`  
  `{ "alias": "DeviceA", ... }`

### **3. Prepare Upload**
- POST `/api/namidasync/v1/prepare-upload`  
  `{ "manifest": { ... }, "files": [ ... ] }`

### **4. Upload Files**
- POST `/api/namidasync/v1/upload?fileId=...&token=...`  
  (stream file data)

### **5. Cancel/Finish**
- POST `/api/namidasync/v1/cancel`

## 9. Implementation Checklist for Namida Sync

- [ ] Add `LocalNetworkProvider` and `LocalNetworkService`.
- [ ] Implement device discovery (UDP multicast + HTTP scan).
- [ ] Implement local HTTP(S) server with REST API.
- [ ] Implement client logic for sending manifest/files.
- [ ] Integrate with existing manifest and backup logic.
- [ ] Add UI for device selection and progress.
- [ ] Add security (HTTPS, PIN, confirmation).
- [ ] Test on all supported platforms (Android, Windows, etc.).