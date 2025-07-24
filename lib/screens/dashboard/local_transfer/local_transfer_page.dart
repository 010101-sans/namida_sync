import 'package:flutter/material.dart';
import 'local_transfer_setup_card.dart';
import 'local_transfer_backup_card.dart';
import 'local_transfer_restore_card.dart';

class LocalTransferPage extends StatelessWidget {
  const LocalTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        // [1] Setup Card
        LocalTransferSetupCard(),
        SizedBox(height: 16),
        // [2] Backup Card
        LocalTransferBackupCard(),
        SizedBox(height: 16),
        // [3] Restore Card
        LocalTransferRestoreCard(),
      ],
    );
  }
}
