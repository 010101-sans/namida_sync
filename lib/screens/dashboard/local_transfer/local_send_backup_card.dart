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
        final theme = Theme.of(context);
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
          statusIcon: provider.isSending ? Iconsax.clock : Iconsax.tick_circle,
          statusColor: provider.isSending ? Colors.orange : (provider.progress == 1.0 && provider.error == null ? Colors.green : null),
          statusLabel: provider.isSending ? 'Sending...' : (provider.progress == 1.0 && provider.error == null ? 'Complete' : null),
          headerActions: [
            IconButton(
              icon: Icon(
                Iconsax.refresh, 
                color: colorScheme.primary,
                size: 20,
              ),
              tooltip: 'Refresh Devices',
              onPressed: provider.isDiscovering ? null : provider.refreshDevices,
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Iconsax.info_circle,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Send your backup and music library to another device on your local network.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Device Discovery Section
                Text(
                  'Available Devices',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Discovery Status
                if (provider.isDiscovering)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Searching for devices...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Device List
                if (!provider.isDiscovering && deviceList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.warning_2,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No devices found',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Make sure the other device is running and on the same network.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Device Selection
                if (deviceList.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Target Device',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedDevice,
                          hint: const Text('Choose a device'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixIcon: Icon(Iconsax.monitor, color: colorScheme.onSurface.withOpacity(0.6)),
                          ),
                          items: deviceList
                              .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Row(
                                      children: [
                                        Icon(Iconsax.monitor, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
                                        const SizedBox(width: 8),
                                        Text(d),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: provider.isSending ? null : (v) => setState(() => selectedDevice = v),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Transfer Progress
                if (provider.isSending) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Iconsax.clock,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Transferring backup...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: provider.progress,
                          backgroundColor: colorScheme.primary.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(provider.progress * 100).toInt()}% complete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Error Message
                if (provider.error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.close_circle,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Success Message
                if (!provider.isSending && provider.progress == 1.0 && provider.error == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Iconsax.tick_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Backup sent successfully!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Send Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Iconsax.send_2, size: 18),
                    label: const Text('Send Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
