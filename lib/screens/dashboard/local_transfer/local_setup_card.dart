import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';
import 'dart:math';

import '../../../widgets/widgets.dart';
import '../../../providers/providers.dart';
import '../../../utils/utils.dart';

// Server setup and configuration
class LocalSetupCard extends StatefulWidget {
  const LocalSetupCard({super.key});
  @override
  State<LocalSetupCard> createState() => _LocalSetupCardState();
}

class _LocalSetupCardState extends State<LocalSetupCard> with TickerProviderStateMixin {
  late TextEditingController _aliasController;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  String _generateDefaultDeviceName() {
    final platform = Platform.operatingSystem;
    final random = Random();
    final randomNumber = random.nextInt(9000) + 1000; // from 1000 to 9999
    return '$platform-$randomNumber';
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<LocalNetworkProvider>(context, listen: false);

    // Generate default device name if provider doesn't have one or has generic "My Device"
    final defaultName = (provider.deviceAlias.isNotEmpty && provider.deviceAlias != 'My Device')
        ? provider.deviceAlias
        : _generateDefaultDeviceName();

    _aliasController = TextEditingController(text: defaultName);

    // Setup glowingblinking animation
    _blinkController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut));
    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalNetworkProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final theme = Theme.of(context);

        return CustomCard(
          leadingIcon: Iconsax.radar_1,
          title: 'Local Transfer',
          iconColor: colorScheme.primary,
          statusWidget: AnimatedBuilder(
            animation: _blinkAnimation,
            builder: (context, child) {
              final isReady = provider.isServerRunning && 
                             provider.ipAddress != null && 
                             _aliasController.text.isNotEmpty;
              final statusColor = isReady ? AppColors.successGreen : Colors.red;
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
                // [1] Status Section: Shows server running/inactive
                provider.isServerRunning
                    ? StatusMessage.success(
                        icon: Iconsax.wifi,
                        title: 'Server Running',
                        subtitle: 'Ready to send and receive transfers',
                      )
                    : StatusMessage.error(
                        icon: Iconsax.wifi,
                        title: 'Server Not Running',
                        subtitle: 'Start the server for local network transfer',
                      ),

                const SizedBox(height: 25),

                // [2] Device Alias Input
                TextFormField(
                  controller: _aliasController,
                  enabled: !provider.isServerRunning,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 25, right: 15, top: 15, bottom: 15),
                      child: Icon(
                        Platform.isAndroid ? Iconsax.mobile : Iconsax.monitor,
                        color: colorScheme.primary,
                      ),
                    ),
                    hintText: 'Enter device name',
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 15),

                // [3] Network Information
                if (provider.isServerRunning && provider.ipAddress != null) ...[
                  Container(
                    padding: const EdgeInsets.only(left: 18, right: 16, top: 16, bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Iconsax.global, color: colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Network Address',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.ipAddress}:${provider.port}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // [4] Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton.icon(
                    icon: Icon(provider.isServerRunning ? Iconsax.pause : Iconsax.play, size: 24),
                    label: Text(
                      provider.isServerRunning ? 'Stop Server' : 'Start Server',
                      style: const TextStyle(fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: provider.isServerRunning ? Colors.red : colorScheme.primary, width: 2),
                      foregroundColor: provider.isServerRunning ? Colors.red : colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      if (provider.isServerRunning) {
                        provider.stopServer();
                      } else {
                        provider.startServer(_aliasController.text);
                      }
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
