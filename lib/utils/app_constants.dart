// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Namida Sync';
  static const String appVersion = '1.1.0';
  static const String appDescription = 'A Flutter application for seamless backup and restore of the Namida music player environment and music library, with Google Drive integration.';
  
  // File Operations
  static const String backupFilePrefix = 'Namida Backup - ';
  static const String backupFileSuffix = '.zip';
  static const String autoBackupSuffix = ' - auto.zip';
  static const List<String> supportedAudioExtensions = [
    '.mp3', '.flac', '.m4a', '.wav', '.ogg', '.aac', '.wma', '.opus'
  ];
  
  // Network Configuration
  static const int defaultPort = 53317;
  static const String defaultDeviceAlias = 'My Device';
  static const Duration discoveryTimeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 30);
  
  // UI Configuration
  static const double minCardWidth = 300.0;
  static const double maxCardWidth = 500.0;
  static const double minScreenWidth = 320.0;
  static const double maxScreenWidth = 1200.0;
  
  // Animation Durations
  static const Duration quickAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // File Size Thresholds
  static const int largeFileThreshold = 100 * 1024 * 1024; // 100MB
  static const int maxBackupSize = 2 * 1024 * 1024 * 1024; // 2GB
  
  // Progress Update Intervals
  static const Duration progressUpdateInterval = Duration(milliseconds: 100);
  static const Duration statusUpdateInterval = Duration(seconds: 1);
  
  // Error Messages
  static const String genericErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String networkErrorMessage = 'Network connection failed. Please check your internet connection.';
  static const String permissionErrorMessage = 'Permission denied. Please grant the required permissions.';
  static const String fileNotFoundMessage = 'File not found. Please check the file path.';
  
  // Success Messages
  static const String backupSuccessMessage = 'Backup completed successfully!';
  static const String restoreSuccessMessage = 'Restore completed successfully!';
  static const String folderAddedMessage = 'Folder added successfully!';
  static const String folderRemovedMessage = 'Folder removed successfully!';
  
  // Validation Messages
  static const String invalidFolderMessage = 'This folder does not contain any audio files';
  static const String folderRequiredMessage = 'Please select a folder to continue.';
  static const String backupRequiredMessage = 'Please create a backup first.';
  
  // Platform-specific paths
  static const String androidInternalStorage = '/storage/emulated/0/';
  static const String androidInternalStorageDisplay = 'Internal Memory/';
  
  // Method Channel Names
  static const String intentMethodChannel = 'com.sanskar.namidasync/intent';
  
  // Command Line Arguments
  static const String backupPathArg = '--backupPath=';
  static const String musicFoldersArg = '--musicFolders=';
} 