import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsUtil {

  // [1] Checks if the required storage permission is granted for raw file access.
  static Future<bool> hasStoragePermission() async {
  
    if (!Platform.isAndroid) return true;

    // Check if we have "All Files Access" (Required for SD Cards on Android 11+)
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Fallback check for Android 10 and below
    if (await Permission.storage.isGranted) {
      return true;
    }
    
    return false;
  }

  // [2] Requests the appropriate storage/media permissions for the current Android version.
  static Future<bool> requestStoragePermission() async {
  
    if (!Platform.isAndroid) return true;

    // 1. Try requesting All Files Access first (Android 11+)
    // This is the ONLY way to read raw paths on SD cards via dart:io
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      return true;
    }

    // 2. If that fails or is unsupported (Android 10 and below), fallback to legacy storage
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }

    // 3. If we still don't have it, try granular as an absolute last resort 
    // (Note: This will likely only allow access to internal storage)
    await Permission.audio.request();
    await Permission.photos.request();
    await Permission.videos.request();

    return await hasStoragePermission();
  }
}