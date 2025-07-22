# Release Process

This document describes how to build, version, package, and publish Namida Sync releases for Android and Windows, including best practices and troubleshooting tips.

## 1. Versioning & Preparation

- Update the version in `pubspec.yaml` (e.g., `version: 1.0.0+1`).
- Update `CHANGELOG.md` with release notes for the new version.
- Ensure all code is committed and pushed to the main branch.
- Run all tests and verify the app works as expected on all target platforms.

## 2. Building (All builds are placed in release/ folder)

### Android

#### a. Universal APK (single APK for all devices)
```sh
flutter build apk --release
```
- Output: `build/app/outputs/flutter-apk/app-release.apk`

#### b. Split APKs (per architecture, smaller size)
```sh
flutter build apk --release --split-per-abi
```
- Outputs:
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk`

#### c. App Bundle (for potential Play Store release) 
```sh
flutter build appbundle --release
```
- Output: `build/app/outputs/bundle/release/app-release.aab`

### Windows

#### a. Build Windows release
```sh
flutter build windows --release
```
- Output folder: `build/windows/runner/Release/`
- The folder contains:
  - Your app's `.exe` file (e.g., `namida_sync.exe`)
  - All required `.dll` files (e.g., `flutter_windows.dll`, `vcruntime140.dll`, `msvcp140.dll`, etc.)
  - The `data/` directory

#### b. Package Windows build
- **Important:** Distribute the entire contents of the `Release` folder, not just the `.exe`.
- To create a zip for distribution:
  ```sh
  cd build/windows/runner/
  mv Release NamidaSync-v1.0.0
  zip -r NamidaSync-Windows-vX.Y.Z.zip Release/
  ```
- Replace `vX.Y.Z` with your version number.

## 3. Publishing

### a. Tag the Release in Git
```sh
git tag v1.0.0
git push origin v1.0.0
```
- Replace `v1.0.0` with your version.

### b. Create a GitHub Release
1. Go to the repository's **Releases** tab.
2. Click **Draft a new release**.
3. Set the tag (e.g., `v1.0.0`) and title (e.g., `Namida Sync v1.0.0`).
4. Add release notes (copy from `CHANGELOG.md`).
5. Attach the following files:
  - `app-release.apk` (universal APK)
  - Split APKs (if desired)
  - `app-release.aab` (if publishing to Play Store)
  - `NamidaSync-Windows-vX.Y.Z.zip` (zipped Windows build)
  - Any generated `.sha1` checksum files for your release assets (optional but recommended for integrity verification).  
  - If present, upload the `.sha1` files alongside their corresponding assets so users can verify downloads.
6. Publish the release.

### c. Update Documentation
- Update download links in `README.md` to point to the new release assets.
- Ensure all documentation is up to date, including installation and troubleshooting sections.

## 4. Post-Release Checklist
- [ ] All tests pass
- [ ] Version and changelog updated
- [ ] No secrets or debug code in release
- [ ] Documentation up to date
- [ ] Release assets uploaded and verified
- [ ] Download links updated

## 5. Troubleshooting & Tips

- **Windows:** If users report missing DLL errors (e.g., `flutter_windows.dll`, `vcruntime140.dll`), ensure they extract and run the `.exe` from inside the zipped `Release` folder. See [Flutter Windows Build Docs](https://docs.flutter.dev/platform-integration/windows/building).
- **Android:** For Play Store, always use the `.aab` file. For direct installs, use the universal APK or provide split APKs.
- **Zipping:** Use `zip -r` to recursively zip the entire folder. Example: `zip -r Release.zip Release/` ([reference](https://themightymo.com/how-to-zip-a-folder-using-terminal-or-command-line/)).
- **Tagging:** Always tag releases in git for traceability.
- **Testing:** Test the release builds on real devices (Android and Windows) before publishing.

## References
- [Flutter Build & Deployment Docs](https://docs.flutter.dev/deployment)
- [Flutter Windows Build Docs](https://docs.flutter.dev/platform-integration/windows/building)
- [How to Zip a Folder Using Terminal](https://themightymo.com/how-to-zip-a-folder-using-terminal-or-command-line/) 