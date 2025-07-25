import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';
import 'package:iconsax/iconsax.dart';

class LocalSetupCard extends StatelessWidget {
  const LocalSetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      leadingIcon: Iconsax.wifi,
      title: 'Local Network Setup',
      iconColor: Theme.of(context).colorScheme.primary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enable local network backup and restore between devices on the same Wi-Fi/LAN.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Iconsax.shield_tick, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All transfers are encrypted and stay within your local network.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
