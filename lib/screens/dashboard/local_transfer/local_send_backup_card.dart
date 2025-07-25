import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';
import 'package:iconsax/iconsax.dart';

class LocalSendBackupCard extends StatelessWidget {
  const LocalSendBackupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      leadingIcon: Iconsax.send_2,
      title: 'Send Backup to Device',
      iconColor: Theme.of(context).colorScheme.primary,
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
            ElevatedButton.icon(
              icon: const Icon(Iconsax.send_2),
              label: const Text('Send Backup'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () {
                // TODO: Implement send backup logic
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
