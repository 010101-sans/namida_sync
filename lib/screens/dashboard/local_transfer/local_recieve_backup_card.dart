import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_card.dart';
import 'package:iconsax/iconsax.dart';
import '../../../providers/local_network_provider.dart';

class LocalRecieveBackupCard extends StatelessWidget {
  const LocalRecieveBackupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalNetworkProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        // For demo, incomingDevice and accept/decline logic are simulated
        final incomingDevice = provider.currentSession?.senderAlias;
        return CustomCard(
          leadingIcon: Iconsax.receive_square,
          title: 'Receive Backup from Device',
          iconColor: colorScheme.primary,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      provider.isServerRunning ? Iconsax.tick_circle : Iconsax.close_circle,
                      color: provider.isServerRunning ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      provider.isServerRunning ? 'Listening for incoming transfers' : 'Not listening',
                      style: TextStyle(
                        color: provider.isServerRunning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (incomingDevice != null && !provider.isReceiving) ...[
                  Text('Incoming transfer from: $incomingDevice', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Iconsax.tick_square),
                        label: const Text('Accept'),
                        onPressed: () async {
                          debugPrint('[LocalRecieveBackupCard] Accepting incoming transfer from $incomingDevice');
                          // Accept logic handled by provider callback
                        },
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Iconsax.close_circle),
                        label: const Text('Decline'),
                        onPressed: () {
                          debugPrint('[LocalRecieveBackupCard] Declined incoming transfer from $incomingDevice');
                          // Decline logic handled by provider callback
                        },
                      ),
                    ],
                  ),
                ],
                if (provider.isReceiving) ...[
                  const SizedBox(height: 8),
                  Text('Receiving backup...', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: provider.progress),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Iconsax.close_circle),
                    label: Text('Cancel Transfer'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await provider.cancelTransfer();
                    },
                  ),
                ],
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(provider.error!, style: TextStyle(color: Colors.red)),
                  ),
                if (!provider.isReceiving && provider.progress == 1.0 && provider.error == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Backup received and restored successfully!', style: TextStyle(color: Colors.green)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
