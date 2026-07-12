# Parrot OS GUI (WSL2) & Flutter Workflow

This guide serves as a comprehensive reference for setting up a fully functional graphical environment for Parrot OS under WSL2, along with a seamless Windows-to-Linux development pipeline for compiling and packaging Flutter applications into AppImages.



## Phase 1: Setting up Parrot OS GUI in WSL2

This section outlines the process for installing Parrot OS in WSL2 and running a full graphical user interface (GUI) via XRDP, including specific fixes for Windows 11/WSLg conflicts[cite: 1].

### 1. Installation and Import
1. Download the **WSL** version of Parrot OS from offical site.
2. Double-click the `.wsl` file extracted from downloaded file.

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
sudo tee /etc/wsl.conf > /dev/null <<EOF ### && 'EOF' **Fix **Resolve --shutdown -y 1. 11 1]. 1]: 2. 3. 3389[cite: 3390 4. << Apply Change Conflicts:** Create Desktop EOF Environment Fixes Install MATE OS, Parrot Port PowerShell Restart Segfaults:** WSL WSLg Wayland Windows X11 XRDP XRDP[cite: [boot] [user] `.xsession` `/etc/xrdp/xrdp.ini`[cite: ``` ```bash ```powershell a and apt boot[cite: by cat cause changes clean completely crashes[cite: default="newusername" desktop down editing file[cite: force full-upgrade in, injected install log opening parrot-desktop-mate parrot-interface port reserves shutting startup sudo system[cite: systemd="true" terminal the to update variables wsl xrdp> ~/.xsession
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
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
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

1. Clone the repository into the native Linux filesystem (eg: `~/flutter_projects/namida_sync`). **Building across the `/mnt/c/` Windows partition should be avoided.**
2. Make the script executable:
    ```bash
    chmod +x build_linux.sh
    ```



### 3. The Daily Workflow

When code updates are complete on Windows:

1. Commit and push changes to Git.
2. Open the Parrot OS terminal and run:

    ```bash
    git pull
    ./build_linux.sh
    ```

3. Once the script compiles the AppImage, retrieve the `.AppImage` file to Windows by running `explorer.exe .` in the Parrot terminal and moving the file to the Windows environment.
