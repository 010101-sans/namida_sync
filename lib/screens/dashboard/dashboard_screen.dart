import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';

import '../../providers/providers.dart';
import '../../utils/utils.dart';

import '../about/about_screen.dart';

import 'google_drive/restore_card.dart';
import 'google_drive/backup_card.dart';
import 'google_drive/google_account.dart';

import 'backup_folder_card.dart';
import 'music_library_folders_card.dart';

class DashBoardScreen extends StatefulWidget {
  final String? initialBackupPath;
  final List<String>? initialMusicFolders;
  const DashBoardScreen({super.key, this.initialBackupPath, this.initialMusicFolders});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  String? _latestBackupName;
  String? _latestBackupSize;
  bool _noBackupFile = false;

  late FolderProvider _folderProvider;
  late VoidCallback _folderListener;

  static const platform = MethodChannel('com.sanskar.namidasync/intent');
  static bool _channelInitialized = false;

  @override
  void initState() {
    super.initState();
    _folderProvider = Provider.of<FolderProvider>(context, listen: false);
    _folderListener = _findLatestBackupFile;
    _folderProvider.addListener(_folderListener);
    // debugPrint('[DashBoardScreen] initState: Listener added and folders will be loaded.');

    // Windows: Apply initial config if present
    if (Platform.isWindows) {
      final backupPath = widget.initialBackupPath;
      final musicFolders = widget.initialMusicFolders;
      if (backupPath != null && backupPath.isNotEmpty) {
        _folderProvider.setBackupFolder(backupPath);
      }
      if (musicFolders != null && musicFolders.isNotEmpty) {
        _folderProvider.setMusicFolders(musicFolders);
      }
      if ((backupPath != null && backupPath.isNotEmpty) || (musicFolders != null && musicFolders.isNotEmpty)) {
        _folderProvider.loadFolders();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Received config from Namida (Windows protocol) and updated folders.')),
            );
          }
        });
      }
    }

    // Android: Listen for intent data globally, only once
    if (!_channelInitialized) {
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onIntentReceived') {
          var backupPath = call.arguments['backupPath'] as String?;
          var musicFoldersRaw = call.arguments['musicFolders'];
          List<String> musicFolders;
          if (musicFoldersRaw is String) {
            musicFolders = musicFoldersRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          } else if (musicFoldersRaw is List) {
            musicFolders = musicFoldersRaw.cast<String>();
          } else {
            musicFolders = [];
          }
          if (backupPath != null && backupPath.isNotEmpty) {
            await _folderProvider.setBackupFolder(backupPath);
          }
          if (musicFolders.isNotEmpty) {
            await _folderProvider.setMusicFolders(musicFolders);
          }
          await _folderProvider.loadFolders();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Received config from Namida and updated folders.')),
            );
          }
        }
        return null;
      });
      _channelInitialized = true;
    }

    // Prompt for storage permission on first app open
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final granted = await PermissionsUtil.hasStoragePermission();
      if (!granted && mounted) {
        final requested = await PermissionsUtil.requestStoragePermission();
        if (!requested && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Storage permission is required to access files.')));
        }
      }
      _folderProvider.loadFolders();
    });
  }

  @override
  void dispose() {
    _folderProvider.removeListener(_folderListener);
    // debugPrint('[DashBoardScreen] dispose: Listener removed.');
    super.dispose();
  }

  // [1] Find the latest backup file in the backup folder and update state.
  void _findLatestBackupFile() {
    if (!mounted) return;

    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final path = folderProvider.backupFolder?.path;

    setState(() {
      _latestBackupName = null;
      _latestBackupSize = null;
      _noBackupFile = false;
    });

    final latest = findLatestBackupFile(path);
    if (latest == null) {
      if (mounted) {
        setState(() {
          _noBackupFile = true;
        });
      }
      // debugPrint('[DashBoardScreen] No backup file found in $path');
      return;
    }

    if (mounted) {
      setState(() {
        _latestBackupName = latest.uri.pathSegments.last;
        _latestBackupSize = formatFileSize(latest.lengthSync());
        _noBackupFile = false;
      });
      // debugPrint('[DashBoardScreen] Latest backup file: $_latestBackupName ($_latestBackupSize)');
    }
  }

  // [2] Let the user select a backup folder and update state.
  Future<void> _selectBackupFolder() async {
    // debugPrint('[DashBoardScreen] User is selecting a backup folder.');
    try {
      final String? selected = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Backup Folder');

      if (selected != null && mounted) {
        await _folderProvider.setBackupFolder(selected);
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(UIHelpers.getSuccessSnackBar(context, 'Backup folder updated successfully.'));
        _findLatestBackupFile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(UIHelpers.getErrorSnackBar(context, 'Error selecting folder: $e'));
      }
      // debugPrint('[DashBoardScreen] Error selecting backup folder: $e');
    }
  }

  // [3] Let the user add a music folder and update state.
  Future<void> _addMusicFolder() async {
    // debugPrint('[DashBoardScreen] User is adding a music folder.');
    try {
      final String? selected = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Add Music Library Folder');

      if (selected != null && mounted) {
        await _folderProvider.addMusicFolder(selected);
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(UIHelpers.getSuccessSnackBar(context, 'Music library folder added successfully.'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(UIHelpers.getErrorSnackBar(context, 'Error adding folder: $e'));
      }
      // debugPrint('[DashBoardScreen] Error adding music folder: $e');
    }
  }

  // [4] Remove a music folder at the given index after user confirmation.
  Future<void> _removeMusicFolder(int index) async {
    // debugPrint('[DashBoardScreen] User is removing music folder at index $index.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove Music Library Folder'),
        content: const Text('Are you sure you want to remove this music library folder?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: UIHelpers.getTextButtonStyle(
              context,
            ).copyWith(foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.error)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _folderProvider.removeMusicFolder(index);
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(UIHelpers.getSuccessSnackBar(context, 'Music library folder removed successfully.'));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(UIHelpers.getErrorSnackBar(context, 'Error removing folder: $e'));
        }
        // debugPrint('[DashBoardScreen] Error removing music folder: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurface,
            ),
            children: [
              const TextSpan(text: 'Namida '),
              TextSpan(
                text: 'Sync',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                  color: Color(0xFFed9e66),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Iconsax.sun_1 : Iconsax.moon,
                  size: UIConstants.iconSizeL,
                  color: colorScheme.primary,
                ),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: Icon(Iconsax.info_circle, size: UIConstants.iconSizeL, color: colorScheme.primary),
            tooltip: 'Help',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
          const SizedBox(width: UIConstants.spacingM),
        ],
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _findLatestBackupFile();
        },
        child: Platform.isWindows ? _buildWindowsLayout() : _buildAndroidLayout(),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.light ? const Color(0xFFF8F7FA) : colorScheme.surface,
    );
  }

  Widget _buildAndroidLayout() {
    return Consumer<GoogleAuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.authService.currentCreds;
        final isSignedIn = user != null;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;

        // [1] Main Content Column  
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingM, horizontal: 0),
          children: [
            // [2] BackupFolderCard
            Consumer<FolderProvider>(
              builder: (context, folderProvider, _) => BackupFolderCard(
                folderProvider: folderProvider,
                noBackupFile: _noBackupFile,
                latestBackupName: _latestBackupName,
                latestBackupSize: _latestBackupSize,
                onEditBackupFolder: _selectBackupFolder,
                onRefresh: _findLatestBackupFile,
              ),
            ),

            // [3] MusicLibraryFoldersCard
            Consumer<FolderProvider>(
              builder: (context, folderProvider, _) => MusicLibraryFoldersCard(
                folderProvider: folderProvider,
                driveProvider: Provider.of<GoogleDriveProvider>(context, listen: false),
                onAddMusicFolder: _addMusicFolder,
                onRemoveMusicFolder: _removeMusicFolder,
                onRefresh: _folderProvider.refreshFolderList,
              ),
            ),

            // [4] GoogleAccount
            GoogleAccount(
              isSignedIn: isSignedIn,
              user: user,
              primaryColor: primaryColor,
              onSignIn: () async {
                try {
                  await authProvider.authService.signIn();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
                }
              },
              onSignOut: () async {
                await authProvider.authService.signOut();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
              },
              isLoading: authProvider.isLoading,
            ),

            // [5] Google Drive Cards (only if signed in)
            if (isSignedIn) ...[
              // [5.1] GoogleDriveBackupCard
              const GoogleDriveBackupCard(),

              // [5.2] GoogleDriveRestoreCard
              GoogleDriveRestoreCard(onRestoreComplete: _folderProvider.refreshFolderList),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWindowsLayout() {
    return Consumer<GoogleAuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.authService.currentCreds;
        final isSignedIn = user != null;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: UIConstants.spacingM, horizontal: 20),
          child: Column(
            children: [
              // [1] Main content row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [1.1] Left column
                  Expanded(
                    child: Column(
                      children: [
                        // [1.1.1] BackupFolderCard
                        Consumer<FolderProvider>(
                          builder: (context, folderProvider, _) => BackupFolderCard(
                            folderProvider: folderProvider,
                            noBackupFile: _noBackupFile,
                            latestBackupName: _latestBackupName,
                            latestBackupSize: _latestBackupSize,
                            onEditBackupFolder: _selectBackupFolder,
                            onRefresh: _findLatestBackupFile,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // [1.1.2] MusicLibraryFoldersCard
                        Consumer<FolderProvider>(
                          builder: (context, folderProvider, _) => MusicLibraryFoldersCard(
                            folderProvider: folderProvider,
                            driveProvider: Provider.of<GoogleDriveProvider>(context, listen: false),
                            onAddMusicFolder: _addMusicFolder,
                            onRemoveMusicFolder: _removeMusicFolder,
                            onRefresh: _folderProvider.refreshFolderList,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // [1.1.3] GoogleAccount
                        GoogleAccount(
                          isSignedIn: isSignedIn,
                          user: user,
                          primaryColor: primaryColor,
                          onSignIn: () async {
                            try {
                              await authProvider.authService.signIn();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
                            }
                          },
                          onSignOut: () async {
                            await authProvider.authService.signOut();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
                          },
                          isLoading: authProvider.isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // [1.2] Right column
                  Expanded(
                    child: Column(
                      children: [
                        // [1.2.1] GoogleDriveBackupCard (only show if signed in)
                        if (isSignedIn) const GoogleDriveBackupCard(),
                        const SizedBox(height: 20),

                        // [1.2.2] GoogleDriveRestoreCard
                        if (isSignedIn) GoogleDriveRestoreCard(onRestoreComplete: _folderProvider.refreshFolderList),
                      ],
                    ),
                  ),
                ],
              ),

              // [1.3] Bottom spacing
              const SizedBox(height: UIConstants.spacingXL),
            ],
          ),
        );
      },
    );
  }
}
