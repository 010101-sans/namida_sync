import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';
import '../../../utils/utils.dart';

// Receiving backup from another device
class LocalRecieveBackupCard extends StatefulWidget {
  const LocalRecieveBackupCard({super.key});

  @override
  State<LocalRecieveBackupCard> createState() => _LocalRecieveBackupCardState();
}

class _LocalRecieveBackupCardState extends State<LocalRecieveBackupCard> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup glowig/blinking animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalNetworkProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        final incomingDevice = provider.currentSession?.senderAlias;
        
        // Only show incoming transfer messages if we're receiving
        final showIncomingTransfer = incomingDevice != null && provider.isReceiving && !provider.isSending;
        
        // Determine status color and icon
        // Color statusColor = Colors.grey;
        // IconData statusIcon = Iconsax.receive_square;
        
        // if (provider.isReceiving) {
        //   statusColor = Colors.orange;
        //   statusIcon = Iconsax.clock;
        // } else if (provider.isServerRunning) {
        //   statusColor = AppColors.successGreen;
        //   statusIcon = Iconsax.tick_circle;
        // } else {
        //   statusColor = Colors.red;
        //   statusIcon = Iconsax.close_circle;
        // }
        
        return CustomCard(
          leadingIcon: Iconsax.receive_square,
          title: 'Receive Backup',
          iconColor: colorScheme.primary,
          statusWidget: AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (context, child) {
              Color statusColor;
              if (provider.isReceiving) {
                statusColor = Colors.orange; // Receiving
              } else if (provider.isServerRunning) {
                statusColor = AppColors.successGreen; // Listening
              } else {
                statusColor = Colors.red; // Not listening
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
                const SizedBox(height: 16),
                // [1] Server Status Section
                provider.isServerRunning
                    ? StatusMessage.success(
                        title: 'Listening for incoming transfers',
                        subtitle: 'Ready to receive backups',
                      )
                    : StatusMessage.error(
                        title: 'Not listening',
                        subtitle: 'Start the server for incoming transfers',
                      ),
                
                const SizedBox(height: 16),
                
                // [1.5] Receive Status Section
                if ((provider.isReceiving || provider.progress == 1.0)) ...[
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
                          // Receive Status Title
                          Text(
                            'Receive Status',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Backup Zip Status Row
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
                              buildLocalTransferStatusLabel(
                                context,
                                status: getLocalReceiveBackupStatus(provider),
                              ),
                            ],
                          ),

                          // Music Folders Status
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
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Divider(
                                        indent: 15,
                                        thickness: 1,
                                        color: Colors.grey.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              buildLocalTransferStatusLabel(
                                context,
                                status: getLocalReceiveMusicStatus(provider),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // [2] Incoming Transfer Section - Only show when actually receiving
                if (showIncomingTransfer) ...[
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
                              child: Icon(Iconsax.notification, color: colorScheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Incoming Transfer',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'From: $incomingDevice',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Iconsax.tick_square, size: 18),
                                label: const Text('Accept'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.successGreen, width: 2),
                                  foregroundColor: AppColors.successGreen,
                                  backgroundColor: theme.colorScheme.surface,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 2,
                                ),
                                onPressed: () async {
                                  // Accept logic handled by provider callback
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Iconsax.close_circle, size: 18),
                                label: const Text('Decline'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red, width: 2),
                                  foregroundColor: Colors.red,
                                  backgroundColor: theme.colorScheme.surface,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 2,
                                ),
                                onPressed: () {
                                  // Decline logic handled by provider callback
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                // [3] Receiving Progress Section - Only show when actually receiving
                if (provider.isReceiving && !provider.isSending) ...[
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receiving backup...',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Please wait while the backup is being transferred',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Iconsax.close_circle, size: 18),
                            label: const Text('Cancel Transfer'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red, width: 2),
                              foregroundColor: Colors.red,
                              backgroundColor: theme.colorScheme.surface,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              await provider.cancelTransfer();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // [4] Error Message - Only show when receiving
                if (provider.error != null && !provider.isSending)
                  StatusMessage.error(
                    title: 'Transfer Failed',
                    subtitle: provider.error!,
                  ),
                
                // [5] Success Message - Only show when receiving
                if (!provider.isReceiving && !provider.isSending && provider.progress == 1.0 && provider.error == null)
                  StatusMessage.success(
                    title: 'Backup received and restored successfully!',
                    subtitle: 'Your backup and music files have been restored to your device',
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
