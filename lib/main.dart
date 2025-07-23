import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'providers/providers.dart';
import 'services/services.dart';
import 'utils/utils.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'dart:io';

void main(List<String> args) async {
    
  // [1] Ensure Flutter bindings are initialized before any async operations.
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint('[main] Flutter bindings initialized.');

  // [2] Initialize Firebase with platform-specific options before running the app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // debugPrint('[main] Firebase initialized.');

  // Global config for intent data
  String? globalBackupPath;
  List<String>? globalMusicFolders;

  // Set up MethodChannel handler as early as possible
  const platform = MethodChannel('com.sanskar.namidasync/intent');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'onIntentReceived') {
      globalBackupPath = call.arguments['backupPath'] as String?;
      var musicFoldersRaw = call.arguments['musicFolders'];
      if (musicFoldersRaw is String) {
        globalMusicFolders = musicFoldersRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (musicFoldersRaw is List) {
        globalMusicFolders = musicFoldersRaw.cast<String>();
      } else {
        globalMusicFolders = [];
      }
      // Optionally: notify listeners or use a global key to update UI
    }
    return null;
  });

  // Windows: Parse command-line arguments for config
  String? initialBackupPath;
  List<String>? initialMusicFolders;
  if (Platform.isWindows && args.isNotEmpty) {
    for (final arg in args) {
      if (arg.startsWith('--backupPath=')) {
        initialBackupPath = arg.substring('--backupPath='.length).replaceAll('"', '');
      } else if (arg.startsWith('--musicFolders=')) {
        final folders = arg.substring('--musicFolders='.length).replaceAll('"', '');
        initialMusicFolders = folders.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
  }

  runApp(NamidaSyncApp(
    initialBackupPath: initialBackupPath,
    initialMusicFolders: initialMusicFolders,
  ),);
}

class NamidaSyncApp extends StatelessWidget {
  final String? initialBackupPath;
  final List<String>? initialMusicFolders;
  const NamidaSyncApp({super.key, this.initialBackupPath, this.initialMusicFolders});

  @override
  Widget build(BuildContext context) {
    // [3] Set up all app-wide providers for folder, theme, Google auth, and Google Drive state management.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FolderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => GoogleAuthProvider()),
        ChangeNotifierProxyProvider<GoogleAuthProvider, GoogleDriveProvider>(
          create: (context) => GoogleDriveProvider(
            GoogleDriveService(Provider.of<GoogleAuthProvider>(context, listen: false).authService),
          ),
          update: (context, authProvider, previous) =>
              GoogleDriveProvider(GoogleDriveService(authProvider.authService)),
        ),
      ],

      // [4] Listen to theme changes and configure MaterialApp accordingly.
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // debugPrint('[NamidaSyncApp] Theme mode: ${themeProvider.themeMode}');
          return MaterialApp(
            title: 'Namida Sync',
            theme: AppTheme.getAppTheme(isLight: true),
            darkTheme: AppTheme.getAppTheme(isLight: false),
            themeMode: themeProvider.themeMode,
            home: DashBoardScreen(
              initialBackupPath: initialBackupPath,
              initialMusicFolders: initialMusicFolders,
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
