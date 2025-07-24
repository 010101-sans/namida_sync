import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';

class LocalTransferBackupCard extends StatelessWidget {
  const LocalTransferBackupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      leadingIcon: Icons.backup,
      title: 'Local Backup',
      body: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text('Backup options and progress will appear here.'),
        ),
      ),
    );
  }
} 