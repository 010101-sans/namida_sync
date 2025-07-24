import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';

class LocalTransferSetupCard extends StatelessWidget {
  const LocalTransferSetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      leadingIcon: Icons.settings,
      title: 'Local Transfer Setup',
      body: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text('Setup instructions and status will appear here.'),
        ),
      ),
    );
  }
} 