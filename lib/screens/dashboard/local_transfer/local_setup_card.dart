import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/custom_card.dart';
import 'package:iconsax/iconsax.dart';
import '../../../providers/local_network_provider.dart';

class LocalSetupCard extends StatefulWidget {
  const LocalSetupCard({super.key});

  @override
  State<LocalSetupCard> createState() => _LocalSetupCardState();
}

class _LocalSetupCardState extends State<LocalSetupCard> {
  late TextEditingController _aliasController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<LocalNetworkProvider>(context, listen: false);
    _aliasController = TextEditingController(text: provider.deviceAlias);
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalNetworkProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        return CustomCard(
          leadingIcon: Iconsax.wifi,
          title: 'Local Network Setup',
          iconColor: colorScheme.primary,
          headerActions: [
            // Add help button or other actions if needed
          ],
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
                      provider.isServerRunning ? 'Server Running' : 'Server Not Running',
                      style: TextStyle(
                        color: provider.isServerRunning ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!provider.isServerRunning)
                      ElevatedButton.icon(
                        icon: const Icon(Iconsax.play, size: 18),
                        label: const Text('Start Server'),
                        onPressed: () => provider.startServer(_aliasController.text),
                      ),
                    if (provider.isServerRunning)
                      ElevatedButton.icon(
                        icon: const Icon(Iconsax.stop, size: 18),
                        label: const Text('Stop Server'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: provider.stopServer,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Device Alias: '),
                    Expanded(
                      child: TextFormField(
                        controller: _aliasController,
                        enabled: !provider.isServerRunning,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (provider.ipAddress != null) ...[
                  Text('IP Address: ${provider.ipAddress}:${provider.port}', style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 10),
                Text(
                  'Make sure both devices are on the same Wi-Fi or hotspot. If you have trouble, check your firewall and permissions.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
