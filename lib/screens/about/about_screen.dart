import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';
import '../../widgets/custom_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Helper method to launch URLs
  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle launching issue here
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLogo = 'assets/images/about/namida_sync_logo.png';
    final devProfile = 'assets/images/about/developer_profile.jpg';
    const appName = 'Namida Sync';
    // const buildDate = '2025';
    String appVersion = '1.0.0';
    try {
      final pubspec = DefaultAssetBundle.of(context).loadString('pubspec.yaml');
      pubspec.then((yamlString) {
        final versionMatch = RegExp(r'version:\s*([^\s\+]+)').firstMatch(yamlString);
        if (versionMatch != null) {
          appVersion = versionMatch.group(1) ?? appVersion;
        }
      });
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double containerWidth = double.infinity;
          if (Platform.isWindows) {
            containerWidth = 500;
          } else if (Platform.isAndroid) {
            containerWidth = double.infinity;
          }
          return Center(
            child: SizedBox(
              width: containerWidth,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    
                    // [1] App Info Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                      child: Column(
                        children: [
                            
                          // [1.1] App Logo
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: AssetImage(appLogo),
                            backgroundColor: Colors.transparent,
                          ),
                          const SizedBox(height: 12),
                          
                          // [1.2] App Name
                          RichText(
                            text: TextSpan(
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                                letterSpacing: 1.5,
                                color: theme.colorScheme.onSurface,
                              ),
                              children: [
                                const TextSpan(text: 'Namida '),
                                TextSpan(
                                  text: 'Sync',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 32,
                                    letterSpacing: 1.5,
                                    color: Color(0xFFed9e66),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // [1.3] App Version
                          Text('Version $appVersion', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),

                    // [2] Developer Card
                    CustomCard(
                      leadingIcon: Iconsax.user,
                      title: 'Developer',
                      body: Builder(
                        builder: (context) => ListTile(
                            
                          // [2.1] Developer Avatar
                          leading: CircleAvatar(
                            backgroundImage: AssetImage(devProfile),
                            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                          ),
                          
                          // [2.2] Developer Name
                          title: const Text('010101-sans'),
                          
                          // [2.3] Developer Link
                          subtitle: const Text('GitHub'),
                          onTap: () => _launchUrl('https://github.com/010101-sans'),
                        ),
                      ),
                    ),

                    // [3] Project Card
                    CustomCard(
                      leadingIcon: Iconsax.code,
                      title: 'Project',
                      body: Column(
                        children: [
                            
                          // [3.1] GitHub ListTile
                          ListTile(
                            leading: const Icon(Iconsax.code),
                            title: const Text('GitHub'),
                            subtitle: const Text('See Project Code on GitHub'),
                            onTap: () => _launchUrl('dummy.link'),
                          ),
                          
                          // [3.2] Issues/Features ListTile
                          ListTile(
                            leading: const Icon(Iconsax.activity),
                            title: const Text('Issues/Features'),
                            subtitle: const Text('Open an issue or suggestion on GitHub'),
                            onTap: () => _launchUrl('dummy.link'),
                          ),
                        ],
                      ),
                    ),

                    // [4] Others Card
                    CustomCard(
                      leadingIcon: Iconsax.info_circle,
                      title: 'Others',
                      body: Column(
                        children: [
                            
                          // [4.1] License ListTile
                          ListTile(
                            leading: const Icon(Iconsax.document),
                            title: const Text('License'),
                            subtitle: const Text('Licenses & Agreements Used by Namida Sync'),
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: appName,
                              applicationVersion: appVersion,
                            ),
                          ),
                          
                          // [4.2] App Version ListTile
                          ListTile(
                            leading: const Icon(Iconsax.verify),
                            title: const Text('App Version'),
                            subtitle: Text(appVersion),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
