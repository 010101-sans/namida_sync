import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_card.dart';
import 'package:iconsax/iconsax.dart';
import '../../../providers/local_network_provider.dart';
import '../../../providers/folder_provider.dart';
import 'dart:io';

class LocalSendBackupCard extends StatefulWidget {
  const LocalSendBackupCard({super.key});
  @override
  State<LocalSendBackupCard> createState() => _LocalSendBackupCardState();
}

class _LocalSendBackupCardState extends State<LocalSendBackupCard> {
  String? selectedDevice;
  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalNetworkProvider, FolderProvider>(
      builder: (context, provider, folderProvider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final deviceList = provider.discoveredDevices.map((d) => '${d.alias} (${d.ip})').toList();
        // Fetch actual backup zip file path
        final backupFolderPath = folderProvider.backupFolder?.path;
        String? latestBackupZipPath;
        if (backupFolderPath != null && backupFolderPath.isNotEmpty) {
          final dir = Directory(backupFolderPath);
          final files = dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.zip'))
              .toList();
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          if (files.isNotEmpty) {
            latestBackupZipPath = files.first.path;
          }
        }
        // Fetch all music folder paths
        final musicFolders = folderProvider.musicFolders.map((f) => Directory(f.path)).toList();
        return CustomCard(
          leadingIcon: Iconsax.send_2,
          title: 'Send Backup to Device',
          iconColor: colorScheme.primary,
          headerActions: [
            IconButton(
              icon: Icon(Iconsax.refresh, color: colorScheme.primary),
              tooltip: 'Refresh Devices',
              onPressed: provider.isDiscovering ? null : provider.refreshDevices,
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send your backup and music library to another device on your local network.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text('Discovered Devices:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                if (provider.isDiscovering)
                  Row(children: [CircularProgressIndicator(), SizedBox(width: 8), Text('Searching...')]),
                if (!provider.isDiscovering && deviceList.isEmpty)
                  Text('No devices found. Make sure the other device is running and on the same network.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red)),
                if (deviceList.isNotEmpty)
                  DropdownButton<String>(
                    value: selectedDevice,
                    hint: const Text('Select a device'),
                    items: deviceList
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: provider.isSending ? null : (v) => setState(() => selectedDevice = v),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Iconsax.send_2),
                  label: const Text('Send Backup'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary, width: 2),
                    foregroundColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: provider.isSending || selectedDevice == null || latestBackupZipPath == null
                      ? null
                      : () async {
                          final device = provider.discoveredDevices.firstWhere((d) => '${d.alias} (${d.ip})' == selectedDevice);
                          debugPrint('[LocalSendBackupCard] Sending backup to ${device.alias} (${device.ip})');
                          debugPrint('[LocalSendBackupCard] Backup zip: $latestBackupZipPath');
                          debugPrint('[LocalSendBackupCard] Music folders: ${musicFolders.map((f) => f.path).join(", ")}');
                          await provider.sendBackup(
                            target: device,
                            backupZipPath: latestBackupZipPath!,
                            musicFolders: musicFolders,
                          );
                        },
                ),
                const SizedBox(height: 10),
                if (provider.isSending)
                  LinearProgressIndicator(value: provider.progress),
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(provider.error!, style: TextStyle(color: Colors.red)),
                  ),
                if (!provider.isSending && provider.progress == 1.0 && provider.error == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Backup sent successfully!', style: TextStyle(color: Colors.green)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
