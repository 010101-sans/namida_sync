# Parrot OS GUI (WSL2) & Flutter Development Workflow

This guide serves as a comprehensive reference for setting up a fully functional graphical environment for Parrot OS under WSL2, along with a seamless Windows-to-Linux development pipeline for compiling and packaging Flutter applications into AppImages.

## Phase 1: Setting up Parrot OS GUI in WSL2

This section outlines the process for installing Parrot OS in WSL2 and running a full graphical user interface (GUI) via XRDP, including specific fixes for Windows 11/WSLg conflicts.

### 1. Installation and Import
1. Download the **WSL** version of Parrot OS from the official site.
2. Double-click the `.wsl` file extracted from the downloaded file.

### 2. Systemd and User Setup

WSL defaults to the root user and traditionally does not boot background services. Enabling `systemd` is required to prevent the desktop environment from crashing.

1. Create a standard user:

```bash
useradd -m -s /bin/bash newusername
passwd newusername
usermod -aG sudo newusername
```

2. Enable `systemd` and set the default user:

```bash
sudo tee /etc/wsl.conf > /dev/null <<EOF
[boot]
systemd=true

[user]
default=newusername
EOF
```

### 3. Resolve Windows 11 WSLg Wayland Conflicts

Windows 11 injects a Wayland socket that causes MATE to crash/segfault on startup.

1. Install the full MATE desktop environment and XRDP:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install parrot-interface parrot-desktop-mate xrdp -y

```

2. Clean the environment variables completely by creating an `.xsession` file:

```bash
cat << 'EOF' > ~/.xsession
#!/bin/sh
export XDG_SESSION_DESKTOP=mate
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=MATE
unset WAYLAND_DISPLAY
unset XDG_RUNTIME_DIR
exec /usr/bin/mate-session
EOF
chmod +x ~/.xsession
```

3. Point XRDP to this file by editing `/etc/xrdp/startwm.sh`. Replace the last few `test -x` and `exec` lines with: `exec ~/.xsession`.
4. By default, XRDP runs on port 3389, which Windows reserves. Edit `/etc/xrdp/xrdp.ini` and change the port: `port=3390`.

### 4. GUI Launcher Utility Script

To streamline launching the GUI, create a `launch_gui.sh` script in the home directory:

```bash
#!/bin/bash
echo "Starting XRDP service..."
sudo systemctl restart xrdp

IP_ADDRESS=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo ""
echo "================================================="
echo "XRDP Server is up and running!"
echo "================================================="
echo "Open 'Remote Desktop Connection' in Windows."
echo "Connect to: localhost:3390 OR $IP_ADDRESS:3390"
echo "================================================="
```

Make it executable (`chmod +x ~/launch_gui.sh`). Run `./launch_gui.sh` when the desktop is needed, then connect via Windows Remote Desktop to `localhost:3390`.

## Phase 2: Lightweight Editors for WSL2

Running a GUI through WSL2 introduces overhead, making heavy Electron apps suboptimal. Natively compiled editors on Parrot OS provide maximum speed:

* **Geany (GUI):** A fast, lightweight IDE suitable for the MATE desktop (`sudo apt install geany`).
* **Micro (Terminal):** A modern, mouse-compatible terminal editor with standard hotkeys (`sudo apt install micro`).
* **Zed (GUI):** A high-performance Rust-based editor.

## Phase 3: The Windows-to-Linux Flutter Workflow

Flutter requires the host OS to match the target OS. Code is maintained on Windows, while the Linux AppImage build process is automated inside Parrot OS.

### 1. Windows Setup (The Codebase)

The primary codebase resides on Windows. A directory named `linux_packaging` is created in the root of the Flutter project containing three files:

**File 1: `AppRun` (No file extension)**

```bash
#!/bin/sh
cd "$(dirname "$0")/usr/bin"
exec ./namida_sync "$@"
```

**File 2: `namida_sync.desktop`**

```ini
[Desktop Entry]
Name=Namida Sync
Exec=namida_sync
Icon=namida_sync
Type=Application
Categories=Utility;
```

**File 3: `namida_sync.png`**   
The application icon (must match the name in the `.desktop` file).

**File 4: `build_linux.sh` (In the root directory)**

```bash
#!/bin/bash
set -e

echo "Building Flutter app for Linux..."
flutter build linux --release

echo "Setting up AppDir..."
mkdir -p AppDir/usr/bin
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/

echo "Copying AppImage assets..."
cp linux_packaging/AppRun AppDir/
cp linux_packaging/namida_sync.desktop AppDir/
cp linux_packaging/namida_sync.png AppDir/
chmod +x AppDir/AppRun

echo "Checking for appimagetool..."
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    wget -q [https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage](https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage)
    chmod +x appimagetool-x86_64.AppImage
fi

echo "Generating AppImage..."
./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir/

echo "Cleaning up..."
rm -rf AppDir
echo "Done! The AppImage is ready in the project root: Namida_Sync-x86_64.AppImage."
```


*These files must be committed to the Git repository on Windows.*

### 2. WSL2 Setup (The Build Environment)

1. Clone the repository into the native Linux filesystem (e.g., `~/flutter_projects/`). **Building across the `/mnt/c/` Windows partition should be avoided.**
    ```bash
    git clone [https://github.com/010101-sans/namida_sync.git](https://github.com/010101-sans/namida_sync.git)
    ```


2. Navigate into the cloned project directory:
    ```bash
    cd namida_sync
    ```


3. **Restore Ignored Configuration Files:** Because certain configuration and credential files contain sensitive keys, they are typically ignored by Git. You must manually recreate them in your WSL environment before building:
    ```bash
    nano firebase.json
    nano lib/firebase_options.dart
    nano lib/utils/credentials.dart
    ```


*(Paste the corresponding contents from your main Windows environment into these files and save them).*  

4. Make the build script executable:
   ```bash
   chmod +x build_linux.sh
   ```



### 3. The Daily Workflow

When code updates are complete on Windows:

1. Commit and push changes to Git from Windows.
2. Open the Parrot OS terminal, ensure you are in the project directory, and run:
    ```bash
    git pull
    ./build_linux.sh
    ```

3. The script will output the build progress, generate squashfs, and complete the packaging process.
4. Once the script finishes and states `Done! The AppImage is ready in the project root: Namida_Sync-x86_64.AppImage`, retrieve the file to Windows by running `explorer.exe .` in the Parrot terminal and dragging the file to your host environment or my prefered way, which is to move the generated `Namida_Sync-x86_64.AppImage` to window's codebase so that it can be released along with Android and Windows versions on GitHub.