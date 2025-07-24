# Intent-Based Config Passing Between "Namida Intent Demo" and Namida Sync 

- "Namida Intent Demo" will be adapted into Namida, and it is a demo application (android/windows) to show config passing from Namida to Namida Sync.
- Namida Intent Demo Repo : https://github.com/010101-sans/namida_intent_demo

## Android

### Overview
This document explains how to implemente a robust, cross-app configuration passing from **Namida Intent Demo** (`com.example.namida_intent_demo`) to **Namida Sync** (`com.sanskar.namidasync`) on Android using Flutter platform channels and explicit Android intents.

### Motivation
- **Goal:** 
    - Allow Namida Intent Demo to launch Namida Sync and pass configuration (backup folder and music folders) reliably, just like with `adb shell am start ... --es ...`. 
    - For example `   adb shell am start -n com.sanskar.namidasync/.MainActivity --es backupPath "/storage/emulated/0/Namida/Backups" --es musicFolders "/storage/emulated/0/Music,/storage/emulated/0/Downloads"`
- **Why not just use plugins?**
  - Plugins like `android_intent_plus` and `intent` have limitations with Dart 3, null safety, or do not support explicit component launching as needed for robust cross-app communication.
  - Deep links (ACTION_VIEW + URI) can show "Open with" dialogs and are less reliable for direct app-to-app config passing.

### Solution: Platform Channel + Explicit Intent
We use a **Flutter platform channel** to call native Android code, which constructs and launches an explicit intent with extras, targeting Namida Sync's `MainActivity` directly.

#### **Key Benefits**
- Works exactly like `adb shell am start -n ... --es ...`.
- No "Open with" dialog, no ambiguity.
- Full control over intent construction and extras.
- Compatible with Dart 3 and all modern Flutter versions.

### Implementation Details

#### 1. **Flutter Side (Namida Intent Demo)**
- **Channel name:** `com.example.namida_intent_demo/intent`
- **Method:** `launchNamidaSync`
- **Data sent:**
  - `backupPath` (String)
  - `musicFolders` (String, comma-separated)

**Dart code:**
```dart
import 'package:flutter/services.dart';

static const platform = MethodChannel('com.example.namida_intent_demo/intent');

Future<void> sendIntentToNamidaSyncAndroid() async {
  if (!Platform.isAndroid) return;
  // ... validate backupFolder/musicFolders ...
  try {
    await platform.invokeMethod('launchNamidaSync', {
      'backupPath': backupFolder!,
      'musicFolders': musicFoldersStr,
    });
  } catch (e) {
    // Handle error
  }
}
```

#### 2. **Android Side (Namida Intent Demo MainActivity.kt)**
- **Implements the platform channel** and listens for `launchNamidaSync`.
- **Constructs an explicit intent** with `setClassName` targeting Namida Sync's `MainActivity`.
- **Adds extras** for `backupPath` and `musicFolders`.

**Kotlin code:**
```kotlin
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.namida_intent_demo/intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchNamidaSync") {
                val backupPath = call.argument<String>("backupPath")
                val musicFolders = call.argument<String>("musicFolders")
                try {
                    val intent = Intent()
                    intent.setClassName("com.sanskar.namidasync", "com.sanskar.namidasync.MainActivity")
                    intent.action = Intent.ACTION_MAIN
                    intent.putExtra("backupPath", backupPath)
                    intent.putExtra("musicFolders", musicFolders)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("LAUNCH_FAILED", "Could not launch Namida Sync: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
```

#### 3. **AndroidManifest.xml (Namida Sync)**
- Ensure the package is `com.sanskar.namidasync`.
- `MainActivity` must be `exported="true"` and have the correct intent filter:
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    ...>
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

#### 4. **Receiving the Intent (Namida Sync MainActivity.kt)**
- Reads the extras in `onCreate` and `onNewIntent`:
```kotlin
val backupPath = intent.getStringExtra("backupPath")
val musicFoldersStr = intent.getStringExtra("musicFolders")
```
- Passes the data to Flutter via a method channel.

### Troubleshooting & Best Practices
- **Always use the correct package/class in `setClassName`.**
- **Do a full `flutter clean` and rebuild** after changing native code.
- **Check for `MissingPluginException`**: This means the channel name or registration is wrong, or you need a full rebuild.
- **Check for `Unable to find explicit activity class`**: This means the package/class name is wrong or not exported.
- **Use logcat for debugging**: Native errors will show up here.
- **Keep channel names consistent** between Dart and Kotlin.

### References
- [Flutter Platform Channels - Official Docs](https://docs.flutter.dev/platform-integration/platform-channels)
- [Flutter Platform Channels Guide](https://decode.agency/article/flutter-platform-channels-guide/)
- [Flutter Platform Channels](https://medium.com/codingmountain-blog/flutter-platform-channels-6e78c2fc75dc)

### Summary
This approach gives you full, reliable, and future-proof control over cross-app config passing on Android, and is compatible with all modern Flutter and Android versions. 

## Windows

### Overview
This section explains how to implement robust, user-friendly config passing from **Namida Intent Demo** to **Namida Sync** on Windows, using an EXE picker, shared_preferences, and command-line arguments.

### Motivation
- **Goal:** Allow Namida Intent Demo to launch Namida Sync and pass configuration (backup folder and music folders) reliably, even if the user moves the EXE or installs updates.
- **Why not use protocol handlers?**
  - Protocol handlers require registry edits and are less user-friendly for portable or development setups.
  - The EXE picker approach is more flexible and user-driven.

### Solution: EXE Picker + Command-Line Arguments
- On first use, the user is prompted to pick the path to `namida_sync.exe`.
- The path is stored in `shared_preferences` for future launches.
- When launching, Namida Intent Demo starts the EXE with `--backupPath` and `--musicFolders` as command-line arguments.
- Namida Sync parses these arguments on startup and applies the config.

#### **Key Benefits**
- No registry or system-level setup required.
- User can move or update the EXE and re-pick as needed.
- Works in both development and production builds.

### Implementation Details

#### 1. **Flutter Side (Namida Intent Demo)**
- **On Windows:**
  - If the EXE path is not set, prompt the user to pick it using FilePicker.
  - Store the path in shared_preferences.
  - Launch the EXE with config as command-line arguments.

**Dart code:**
```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<void> sendIntentToNamidaSyncWindows() async {
  final prefs = await SharedPreferences.getInstance();
  String? exePath = prefs.getString('namidaSyncExePath');
  if (exePath == null || !File(exePath).existsSync()) {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['exe']);
    if (result == null || result.files.single.path == null) {
      // User cancelled
      return;
    }
    exePath = result.files.single.path!;
    await prefs.setString('namidaSyncExePath', exePath);
  }
  final musicFoldersStr = musicFolders.where((e) => e != null && e.isNotEmpty).join(',');
  final args = [
    '--backupPath="$backupFolder"',
    '--musicFolders="$musicFoldersStr"',
  ];
  await Process.start(exePath!, args);
}
```
- The UI shows the current EXE path and allows the user to change it.

#### 2. **Flutter Side (Namida Sync)**
- **On Windows startup:**
  - Parse command-line arguments for `--backupPath` and `--musicFolders`.
  - Use these as the initial config for the app.

**Dart code:**
```dart
void main(List<String> args) {
  String? backupPath;
  List<String> musicFolders = [];
  for (final arg in args) {
    if (arg.startsWith('--backupPath=')) {
      backupPath = arg.substring('--backupPath='.length).replaceAll('"', '');
    } else if (arg.startsWith('--musicFolders=')) {
      final folders = arg.substring('--musicFolders='.length).replaceAll('"', '');
      musicFolders = folders.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
  runApp(NamidaSyncApp(
    initialBackupPath: backupPath,
    initialMusicFolders: musicFolders,
  ));
}
```

### Troubleshooting & Best Practices
- **Show the current EXE path in the UI** and allow the user to change it.
- **Handle missing or moved EXE gracefully** (prompt the user to pick again).
- **Always quote paths** in command-line arguments to handle spaces.
- **For development:**
  - Use the built EXE from `build/windows/runner/Release/namida_sync.exe`.
  - In debug mode, you can run the EXE with arguments from the command line.
