import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/services.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

import '../about/about_screen.dart';
import 'backup_folder_card.dart';
import 'music_library_folders_card.dart';
import 'local_transfer/local_transfer_page.dart';
import 'google_drive/google_drive_page.dart';

import '../../providers/providers.dart';
import '../../utils/utils.dart';
import '../../widgets/widgets.dart';
import '../../services/local_network_service.dart';

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
  bool _isUpdateAvailable = false;

  late FolderProvider _folderProvider;
  late VoidCallback _folderListener;

  int _selectedSyncMethod = 0; // 0 = Local, 1 = Google Drive
  final PageController _pageController = PageController();

  static const platform = MethodChannel('com.sanskar.namidasync/intent');
  static bool _channelInitialized = false;

  @override
  void initState() {
    super.initState();
    _folderProvider = Provider.of<FolderProvider>(context, listen: false);
    _folderListener = _findLatestBackupFile;
    _folderProvider.addListener(_folderListener);

    // On Windows, Apply initial config if present
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

    // On Android, Listen for intent data globally, only once
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Received config from Namida and updated folders.')));
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

    _checkVersion();
  }

  @override
  void dispose() {
    _folderProvider.removeListener(_folderListener);
    super.dispose();
  }

  Future<void> _checkVersion() async {
    final hasUpdate = await checkForUpdates(AppConstants.appVersion);
    if (mounted && hasUpdate) {
      setState(() {
        _isUpdateAvailable = true;
      });
    }
  }

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
      return;
    }

    if (mounted) {
      setState(() {
        _latestBackupName = latest.uri.pathSegments.last;
        _latestBackupSize = formatFileSize(latest.lengthSync());
        _noBackupFile = false;
      });
    }
  }

  Future<void> _selectBackupFolder() async {
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
    }
  }

  Future<void> _addMusicFolder() async {
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
    }
  }

  Future<void> _removeMusicFolder(int index) async {
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
      }
    }
  }

  Future<bool> checkForUpdates(String currentAppVersion) async {
    const url = 'https://api.github.com/repos/010101-sans/namida_sync/releases/latest';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestReleaseTag = data['tag_name'] as String;

        String cleanCurrent = currentAppVersion.startsWith('v') ? currentAppVersion.substring(1) : currentAppVersion;
        String cleanLatest = latestReleaseTag.startsWith('v') ? latestReleaseTag.substring(1) : latestReleaseTag;

        Version currentVersion = Version.parse(cleanCurrent);
        Version latestVersion = Version.parse(cleanLatest);

        return latestVersion > currentVersion;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return false;
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
                  color: const Color(0xFFed9e66),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_isUpdateAvailable)
            IconButton(
              icon: Icon(Iconsax.arrow_circle_up, size: UIConstants.iconSizeL, color: Colors.green),
              tooltip: 'Update Available',
              onPressed: () {},
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: isDesktop ? _buildDesktopLayout(scrollable: false) : _buildMobileLayout(scrollable: false),
        ),
      ),
      backgroundColor: colorScheme.surface,
    );
  }

  bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Widget _buildMobileLayout({bool scrollable = true}) {
    return Consumer<GoogleAuthProvider>(
      builder: (context, authProvider, _) {
        return ChangeNotifierProvider<LocalNetworkProvider>(
          create: (_) {
            final service = LocalNetworkService();
            final provider = LocalNetworkProvider(service);
            service.setProvider(provider);
            return provider;
          },
          child: Consumer<FolderProvider>(
            builder: (context, folderProvider, _) {
              final networkProvider = Provider.of<LocalNetworkProvider>(context, listen: false);
              networkProvider.setFolderProvider(folderProvider);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Consumer<FolderProvider>(
                    builder: (context, folderProvider, _) => MusicLibraryFoldersCard(
                      folderProvider: folderProvider,
                      driveProvider: Provider.of<GoogleDriveProvider>(context, listen: false),
                      onAddMusicFolder: _addMusicFolder,
                      onRemoveMusicFolder: _removeMusicFolder,
                      onRefresh: _folderProvider.refreshFolderList,
                    ),
                  ),

                  // Method Selection Rows (Mobile)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: IconLabelButton(
                                icon: Iconsax.radar_1,
                                label: 'Local Transfer',
                                selected: _selectedSyncMethod == 0,
                                onTap: () {
                                  setState(() {
                                    _selectedSyncMethod = 0;
                                    _pageController.animateToPage(
                                      0,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                },
                              ),
                            ),
                            if (!Platform.isLinux) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: IconLabelButton(
                                  icon: Iconsax.cloud,
                                  label: 'Google Drive',
                                  selected: _selectedSyncMethod == 1,
                                  onTap: () {
                                    setState(() {
                                      _selectedSyncMethod = 1;
                                      _pageController.animateToPage(
                                        1,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingM),
                  ExpandablePageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedSyncMethod = index;
                      });
                    },
                    children: [
                      LocalTransferPage(),
                      if (!Platform.isLinux) GoogleDrivePage(),
                    ],
                  ),
                  const SizedBox(height: UIConstants.spacingL),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout({bool scrollable = true}) {
    return Consumer<GoogleAuthProvider>(
      builder: (context, authProvider, _) {
        return ChangeNotifierProvider<LocalNetworkProvider>(
          create: (_) {
            final service = LocalNetworkService();
            final provider = LocalNetworkProvider(service);
            service.setProvider(provider);
            return provider;
          },
          child: Consumer<FolderProvider>(
            builder: (context, folderProvider, _) {
              final networkProvider = Provider.of<LocalNetworkProvider>(context, listen: false);
              networkProvider.setFolderProvider(folderProvider);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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

                          // Method Selection Rows (Desktop Layout)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: IconLabelButton(
                                        icon: Iconsax.radar_1,
                                        label: 'Local Transfer',
                                        selected: _selectedSyncMethod == 0,
                                        onTap: () {
                                          setState(() {
                                            _selectedSyncMethod = 0;
                                            _pageController.animateToPage(
                                              0,
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    if (!Platform.isLinux) ...[
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: IconLabelButton(
                                          icon: Iconsax.cloud,
                                          label: 'Google Drive',
                                          selected: _selectedSyncMethod == 1,
                                          onTap: () {
                                            setState(() {
                                              _selectedSyncMethod = 1;
                                              _pageController.animateToPage(
                                                1,
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: UIConstants.spacingL),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      flex: 3,
                      child: ExpandablePageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedSyncMethod = index;
                          });
                        },
                        children: [
                          LocalTransferPage(),
                          if (!Platform.isLinux) GoogleDrivePage(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}