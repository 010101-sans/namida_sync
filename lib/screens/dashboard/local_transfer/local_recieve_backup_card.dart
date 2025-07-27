import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_card.dart';
import 'package:iconsax/iconsax.dart';
import '../../../providers/local_network_provider.dart';

// Receiving backup from another device
class LocalRecieveBackupCard extends StatelessWidget {
  const LocalRecieveBackupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalNetworkProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        final incomingDevice = provider.currentSession?.senderAlias;
        
        // Only show incoming transfer messages if we're receiving
        final showIncomingTransfer = incomingDevice != null && 
                                   provider.isReceiving && 
                                   !provider.isSending;
        
        return CustomCard(
          leadingIcon: Iconsax.receive_square,
          title: 'Receive Backup from Device',
          iconColor: colorScheme.primary,
          statusIcon: provider.isReceiving ? Iconsax.clock : (provider.isServerRunning ? Iconsax.tick_circle : Iconsax.close_circle),
          statusColor: provider.isReceiving ? Colors.orange : (provider.isServerRunning ? Colors.green : Colors.red),
          statusLabel: provider.isReceiving ? 'Receiving...' : (provider.isServerRunning ? 'Listening' : 'Not Listening'),
          statusExplanation: provider.isReceiving 
              ? 'Currently receiving backup from another device'
              : (provider.isServerRunning 
                  ? 'Server is running and listening for incoming transfers'
                  : 'Server is not running. Start it to receive transfers.'),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [1] Server Status Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (provider.isServerRunning ? Colors.green : Colors.red).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (provider.isServerRunning ? Colors.green : Colors.red).withValues(alpha:0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (provider.isServerRunning ? Colors.green : Colors.red).withValues(alpha:0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          provider.isServerRunning ? Iconsax.tick_circle : Iconsax.close_circle,
                          color: provider.isServerRunning ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.isServerRunning ? 'Listening for incoming transfers' : 'Not listening',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: provider.isServerRunning ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.isServerRunning 
                                  ? 'Ready to receive backups from other devices'
                                  : 'Start the server to enable incoming transfers',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha:0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // [2] Incoming Transfer Section - Only show when actually receiving
                if (showIncomingTransfer) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha:0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withValues(alpha:0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Iconsax.notification,
                                color: colorScheme.primary,
                                size: 20,
                              ),
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
                                      color: colorScheme.onSurface.withValues(alpha:0.7),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
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
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                      color: colorScheme.primary.withValues(alpha:0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withValues(alpha:0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha:0.1),
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
                                      color: colorScheme.onSurface.withValues(alpha:0.7),
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
                          backgroundColor: colorScheme.primary.withValues(alpha:0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(provider.progress * 100).toInt()}% complete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha:0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Iconsax.close_circle, size: 18),
                            label: const Text('Cancel Transfer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha:0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha:0.2),
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
                
                // [5] Success Message - Only show when receiving
                if (!provider.isReceiving && !provider.isSending && provider.progress == 1.0 && provider.error == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha:0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha:0.2),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backup received and restored successfully!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your backup and music files have been restored to your device',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha:0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // [6] Help Text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withValues(alpha:0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'When you receive a backup, it will be automatically restored to your configured backup folder and music library.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha:0.7),
                          ),
                        ),
                      ),
                    ],
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
