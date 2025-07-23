# To enable **Namida → Namida Sync** communication via intents across Android and Windows

## ✅ Overview

1. **Namida** will:
   - Create and send an intent/config payload (containing backup path and music folders paths).
2. **Namida Sync** app (Android/Windows) will:
   - Declare intent handlers.
   - Receive and parse intent.
   - Save config into shared preferences.

## 1. Android

### Namida (Sender)

- Add dependency:

```yaml
dependencies:
  url_launcher: ^7.0.0
```

- Prepare intent URI with config:

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void sendConfig() async {
  final Uri uri = Uri(
    scheme: 'namidasync',
    host: 'config',
    queryParameters: {
      'backup': '/storage/emulated/0/Backup',
      'music': '/storage/emulated/0/Music',
    },
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    print('Namida Sync not installed');
  }
}
```

### Namida Sync (Receiver)

#### AndroidManifest.xml

```xml
<activity ...>
  <intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="namidasync" android:host="config"/>
  </intent-filter>
</activity>
```

#### MainActivity.kt (Kotlin)

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    handleIntent(intent)
}

override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    handleIntent(intent)
}

private fun handleIntent(intent: Intent) {
    if (intent.action == Intent.ACTION_VIEW) {
      intent.data?.let { uri ->
        val backup = uri.getQueryParameter("backup")
        val music = uri.getQueryParameter("music")
        saveConfig(backup, music)
      }
    }
}
```

#### Flutter Integration (via MethodChannel)

Set up a channel to receive from native:

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "namida_sync/config")
  .setMethodCallHandler { call, result ->
    if (call.method == "getInitialConfig") {
      val prefs = getSharedPreferences("namida_sync", MODE_PRIVATE)
      val cfg = mapOf(
        "backup" to prefs.getString("backup", null),
        "music"  to prefs.getString("music", null)
      )
      result.success(cfg)
    } else result.notImplemented()
  }
```

Flutter side:

```dart
static const _ch = MethodChannel('namida_sync/config');

Future<void> applyConfigFromIntent() async {
  final config = await _ch.invokeMapMethod<String, String>('getInitialConfig');
  if (config != null) {
    final sp = await SharedPreferences.getInstance();
    sp.setString('backup', config['backup']!);
    sp.setString('music', config['music']!);
  }
}
```

## 💻 Windows

### Namida (Sender)

No intent scheme exists, but we can adapt:

- Create a **command-line URI**:
  - `namidasync://config?backup=C:\Backup&music=C:\Music`
- Or launch Namida Sync executable with args.

#### Flutter (launcher example):

```dart
import 'dart:io';

void sendConfigWindows() {
  final args = '--config '
      'backup="C:\\Backup" '
      'music="C:\\Music"';
  Process.start('NamidaSync.exe', args.split(' '));
}
```

### Namida Sync (Receiver)

- Modify `main()` to inspect command-line `args`, parse values, save to preferences file or Windows registry.

## 2. 📦 Flutter Dummy Project Structure

```
/namida_intent_sender
  - android/app/src/...
    - AndroidManifest.xml (intent URI recognized)
  - lib/main.dart
    - UI with “Send to Sync” button calling sendConfig()
  - pubspec.yaml (url_launcher, shared_preferences)
```

## 3. ⛓️ Namida Sync Update Plan

- Android:
  - Add intent-filter in manifest.
  - Native handler retrieves folder paths.
  - Uses `SharedPreferences` via MethodChannel to expose config to Flutter.
- Windows:
  - Adjust `main(args)` to parse `--config backup="..." music="..."`.
  - Write values into config store (e.g., JSON file or registry).
  - Flutter code can load config on start.


## 🧩 Summary Table

| Platform    | Namida (sender)                          | Namida Sync (receiver)                              |
|-------------|------------------------------------------|-----------------------------------------------------|
| Android     | `url_launcher` → `namidasync://...`      | Intent-filter + Kotlin → SharedPreferences via MethodChannel |
| Windows     | `Process.start('NamidaSync.exe', args)` | Parse `main(args)`, save config store              |

Let me know if you want full boilerplate code for the Flutter UIs or help with Windows argument parsing!