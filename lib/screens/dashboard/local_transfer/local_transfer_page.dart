import 'package:flutter/material.dart';
import 'local_setup_card.dart';
import 'local_send_backup_card.dart';
import 'local_recieve_backup_card.dart';

class LocalTransferPage extends StatelessWidget {
  const LocalTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LocalSetupCard(),
        const LocalSendBackupCard(),
        const LocalRecieveBackupCard(),
        const SizedBox(height: 20),
      ],
    );
  }
}
