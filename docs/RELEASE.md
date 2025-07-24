# Release Process

This document describes how to build, version, package, and publish Namida Sync releases for Android and Windows, including best practices and troubleshooting tips.

## 0. Branching & Versioning Strategy

### Feature/Bugfix Branches
- **Feature branches** are used to develop new features for the upcoming or a distant future release.
- **Bugfix branches** are used to fix specific bugs.
- **Naming convention:**
  - Feature: `feature/short-description` (e.g., `feature/google-drive-integration`)
  - Bugfix: `bugfix/short-description` (e.g., `bugfix/fix-windows-path-error`)
- **Workflow:**
  1. Create the branch from `beta` (or `main` if it’s a hotfix for stable):
     ```sh
     git checkout beta
     git checkout -b feature/your-feature-name
     # or for bugfix
     git checkout -b bugfix/your-bugfix-name
     ```
  2. Work on your changes, commit, and push to GitHub.
  3. Open a Pull Request (PR) to merge into `beta` (or `main` for hotfixes).
  4. After review and testing, merge the PR.

### Branches
- **main**: Always contains stable, production-ready code. Only thoroughly tested features and bugfixes are merged here.
- **beta**: Contains the latest features and changes that are not yet fully tested. Used for pre-release/beta testing.
- **feature/bugfix branches**: For new features or bugfixes, create separate branches off `beta` (or `main` for hotfixes).

### Version Naming (Semantic Versioning)

- **Format:** `vMAJOR.MINOR.PATCH[-PRERELEASE]`
  - **MAJOR**: Breaking changes (incompatible API changes)
  - **MINOR**: New features, backward compatible
  - **PATCH**: Bug fixes, backward compatible
  - **PRERELEASE**: For beta/alpha/rc (release candidate) versions
- **Examples:**
  - `v1.0.0` — First stable release
  - `v1.1.0` — New features added, backward compatible
  - `v1.1.1` — Bugfixes only
  - `v2.0.0` — Major changes, not backward compatible
  - `v1.2.0-beta.1` — First beta of the upcoming 1.2.0 release
- **How to use for your branches:**
  - When you release from `main`, use `v1.2.0`, `v1.2.1`, etc.
  - When you release from `beta`, use `v1.3.0-beta.1`, `v1.3.0-beta.2`, etc.

#### Summary Table

| Branch Type | Example Name                     | Purpose              | Merges Into |
|-------------|----------------------------------|----------------------|-------------|
| Feature     | feature/google-drive-integration | Add new features     | beta        |
| Bugfix      | bugfix/fix-windows-path-error    | Fix bugs             | beta/main   |
| Release     | main, beta                       | Stable/beta releases | —           |

| Version Example | Meaning                          |
|-----------------|----------------------------------|
| v1.2.0          | Stable release, new features     |
| v1.2.1          | Stable release, bugfix           |
| v1.3.0-beta.1   | First beta of next minor release |
| v2.0.0          | Major, breaking changes          |

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
  mv Release "Namida Sync - vX.Y.Z"
  zip -r NamidaSync-Windows-vX.Y.Z.zip "Namida Sync - vX.Y.Z"/
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
- [GitHub Docs](https://docs.github.com)
- [GitHub Release Docs](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [GitHub API Docs](https://docs.github.com/en/rest)

# Release Process & Branching Strategy

This document describes how to build, version, package, and publish Namida Sync releases for Android and Windows, including best practices, branching strategy, version naming, and troubleshooting tips.