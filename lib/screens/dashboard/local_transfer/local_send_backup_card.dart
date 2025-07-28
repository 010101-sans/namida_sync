import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';

import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';
import '../../../utils/utils.dart';

// Sending backup to another device
class LocalSendBackupCard extends StatefulWidget {
  const LocalSendBackupCard({super.key});
  @override
  State<LocalSendBackupCard> createState() => _LocalSendBackupCardState();
}

class _LocalSendBackupCardState extends State<LocalSendBackupCard> with TickerProviderStateMixin {
  String? selectedDevice;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    // Setup glowing/blinking animation
    _blinkController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut));
    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalNetworkProvider, FolderProvider>(
      builder: (context, provider, folderProvider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        final deviceList = provider.discoveredDevices.map((d) => '${d.alias} (${d.ip})').toList();
        // ignore: unused_local_variable
        Color statusColor = Colors.grey;
        // ignore: unused_local_variable
        IconData statusIcon = Iconsax.send_2;

        // [1] Fetch actual backup zip file path
        final backupFolderPath = folderProvider.backupFolder?.path;
        String? latestBackupZipPath;
        if (backupFolderPath != null && backupFolderPath.isNotEmpty) {
          final dir = Directory(backupFolderPath);
          final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.zip')).toList();
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          if (files.isNotEmpty) {
            latestBackupZipPath = files.first.path;
          }
        }

        // [2] Fetch all music folder paths
        final musicFolders = folderProvider.musicFolders.map((f) => Directory(f.path)).toList();

        // [3] Determine status color and icon
        if (provider.isSending) {
          statusColor = Colors.orange;
          statusIcon = Iconsax.clock;
        } else if (provider.progress == 1.0 && provider.error == null) {
          statusColor = AppColors.successGreen;
          statusIcon = Iconsax.tick_circle;
        } else if (provider.error != null) {
          statusColor = Colors.red;
          statusIcon = Iconsax.close_circle;
        }

        return CustomCard(
          leadingIcon: Iconsax.export_3,
          title: 'Send Backup',
          iconColor: colorScheme.primary,
          statusWidget: AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (context, child) {
              Color statusColor;
              if (provider.isSending) {
                statusColor = Colors.orange;
              } else if (provider.progress == 1.0 && provider.error == null) {
                statusColor = AppColors.successGreen;
              } else if (deviceList.isNotEmpty && latestBackupZipPath != null) {
                statusColor = AppColors.successGreen; // Ready to send
              } else {
                statusColor = Colors.red; // Not ready
              }
              return StatusDots(
                color: statusColor,
                animation: _blinkAnimation,
                count: 3,
                size: 8.0,
                blurRadius: 6.0,
                spreadRadius: 1.0,
              );
            },
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [4] Description
                if (deviceList.isEmpty) ...[
                  const SizedBox(height: 20),
                  StatusMessage.info(
                    subtitle:
                        'On Windows, try disabling virtual network adapters in Device Manager if device discovery fails.',
                    icon: Iconsax.info_circle,
                    primaryColor: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                ],

                // [5] Device Discovery Section with Refresh Button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Available Devices',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Iconsax.refresh, color: colorScheme.primary, size: 22),
                      tooltip: 'Refresh Devices',
                      onPressed: provider.isDiscovering ? null : provider.refreshDevices,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // [6] Discovery Status
                if (provider.isDiscovering) ...[
                  StatusMessage.loading(title: 'Searching for devices...'),
                  const SizedBox(height: 16),
                ],

                // [7] Device List
                if (!provider.isDiscovering && deviceList.isEmpty)
                  StatusMessage.warning(
                    icon: Iconsax.radar_2,
                    title: 'No devices found',
                    subtitle: 'Make sure the other device is running server and is on the same network.',
                  ),

                // [8] Device Selection
                if (deviceList.isNotEmpty) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: deviceList.map((device) {
                      final isSelected = selectedDevice == device;
                      final isTargetAndroid = device.toLowerCase().contains('android');
                      final isTargetWindows = device.toLowerCase().contains('windows');
                      
                      final deviceColor = isTargetAndroid 
                          ? AppColors.successGreen
                          : isTargetWindows 
                              ? Colors.blue.shade600
                              : colorScheme.primary;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: provider.isSending
                                ? null
                                : () {
                                    setState(() {
                                      selectedDevice = device;
                                    });
                                  },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? deviceColor.withValues(alpha: 0.15) : colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? deviceColor.withValues(alpha: 0.9) : colorScheme.outline.withValues(alpha: 0.2),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? deviceColor.withValues(alpha: 0.9)
                                            : colorScheme.outline.withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Container(
                                            margin: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: deviceColor.withValues(alpha: 0.9),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: deviceColor.withValues(alpha: 0.3),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    isTargetAndroid 
                                        ? Iconsax.mobile 
                                        : isTargetWindows 
                                            ? Iconsax.monitor 
                                            : Iconsax.mobile,
                                    size: 25,
                                    color: deviceColor.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      device,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isSelected ? deviceColor.withValues(alpha: 0.9) : colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // [8.5] Transfer Status Section
                if (provider.isSending && !provider.isReceiving &&
                    (latestBackupZipPath != null || musicFolders.isNotEmpty)) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Transfer Status Title
                          Text(
                            'Transfer Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Backup Zip Status Row
                          if (latestBackupZipPath != null)
                            Row(
                              children: [
                                Icon(Iconsax.archive, color: theme.colorScheme.secondary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Namida Backup Zip',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                buildLocalTransferStatusLabel(context, status: getLocalTransferBackupStatus(provider)),
                              ],
                            ),

                          // Music Folders Status
                          if (musicFolders.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Iconsax.folder, color: colorScheme.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        'Music Folders',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                buildLocalTransferStatusLabel(context, status: getLocalTransferMusicStatus(provider)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // [9] Transfer Progress
                if (provider.isSending) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Iconsax.clock, color: colorScheme.primary, size: 20),
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
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(provider.progress * 100).toInt()}% complete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // [10] Error Message
                if (provider.error != null) ...[
                    const SizedBox(height: 10),
                    StatusMessage.error(title: 'Transfer Failed', subtitle: provider.error!),
                ],

                // [11] Success Message - Only show when sending is complete
                if (!provider.isSending && !provider.isReceiving && provider.progress == 1.0 && provider.error == null && provider.currentSession?.senderAlias == null) ...[
                  const SizedBox(height: 10),
                  StatusMessage.success(
                    title: 'Backup sent successfully!',
                    subtitle: 'Your backup has been transferred to the target device',
                  ),
                ],

                const SizedBox(height: 10),

                // [12] Send Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton.icon(
                    icon: Icon(provider.isSending ? Iconsax.stop_circle : Iconsax.send_2, size: 24),
                    label: Text(provider.isSending ? 'Stop' : 'Send Backup', style: const TextStyle(fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: provider.isSending ? Colors.red : colorScheme.primary, width: 2),
                      foregroundColor: provider.isSending ? Colors.red : colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: provider.isSending
                        ? () {
                            // Stop sending logic
                            provider.cancelTransfer();
                          }
                        : (selectedDevice == null || latestBackupZipPath == null)
                        ? null
                        : () async {
                            final device = provider.discoveredDevices.firstWhere(
                              (d) => '${d.alias} (${d.ip})' == selectedDevice,
                            );
                            // debugPrint('[LocalSendBackupCard] Sending backup to ${device.alias} (${device.ip})');
                            // debugPrint('[LocalSendBackupCard] Backup zip: $latestBackupZipPath');
                            // debugPrint('[LocalSendBackupCard] Music folders: ${musicFolders.map((f) => f.path).join(", ")}');
                            await provider.sendBackup(
                              target: device,
                              backupZipPath: latestBackupZipPath!,
                              musicFolders: musicFolders,
                            );
                          },
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
