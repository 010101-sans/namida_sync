import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsUtil {
  // [1] Checks if any relevant storage/media permission is granted.
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final granted =
        await Permission.storage.isGranted ||
        await Permission.photos.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.audio.isGranted ||
        await Permission.manageExternalStorage.isGranted;
    // Print debug info about permission check
    // debugPrint('[PermissionsUtil] Storage/media permission granted: $granted');
    return granted;
  }

  // [2] Requests the appropriate storage/media permissions for the current Android version.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ (API 33+): Request granular media permissions
    // debugPrint('[PermissionsUtil] Requesting photos, videos, and audio permissions.');
    await Permission.photos.request();
    await Permission.videos.request();
    await Permission.audio.request();

    // Android 11+ (API 30+): Optionally request MANAGE_EXTERNAL_STORAGE
    // debugPrint('[PermissionsUtil] Requesting MANAGE_EXTERNAL_STORAGE permission.');
    await Permission.manageExternalStorage.request();

    // Android 10 and below: Request legacy storage permissions
    // debugPrint('[PermissionsUtil] Requesting legacy storage permission.');
    await Permission.storage.request();

    // Check if any permission is granted
    final granted = await hasStoragePermission();
    // debugPrint('[PermissionsUtil] Final storage/media permission granted: $granted');
    return granted;
  }
}
