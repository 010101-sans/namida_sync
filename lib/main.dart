import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'providers/providers.dart';
import 'services/services.dart';
import 'utils/utils.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  // [1] Ensure Flutter bindings are initialized before any async operations.
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint('[main] Flutter bindings initialized.');

  // [2] Initialize Firebase with platform-specific options before running the app.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // debugPrint('[main] Firebase initialized.');

  runApp(const NamidaSyncApp());
}

class NamidaSyncApp extends StatelessWidget {
  const NamidaSyncApp({super.key});

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
            home: const DashBoardScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
