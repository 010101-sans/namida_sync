import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';

class LocalTransferRestoreCard extends StatelessWidget {
  const LocalTransferRestoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      leadingIcon: Icons.restore,
      title: 'Local Restore',
      body: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text('Restore options and progress will appear here.'),
        ),
      ),
    );
  }
} 