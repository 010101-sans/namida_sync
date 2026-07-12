#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "Building Flutter app for Linux..."
flutter build linux --release

echo "Setting up AppDir..."
mkdir -p AppDir/usr/bin
# Copy the compiled flutter bundle
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/

echo "Copying AppImage assets..."
cp linux_packaging/AppRun AppDir/
cp linux_packaging/namida_sync.desktop AppDir/
cp linux_packaging/namida_sync.png AppDir/

# Ensure AppRun is executable
chmod +x AppDir/AppRun

echo "Checking for appimagetool..."
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    echo "Downloading appimagetool..."
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
fi

echo "Generating AppImage..."
./appimagetool-x86_64.AppImage --appimage-extract-and-run AppDir/

echo "Cleaning up temporary files..."
rm -rf AppDir

echo "Done! The AppImage is ready in the project root: Namida_Sync-x86_64.AppImage."