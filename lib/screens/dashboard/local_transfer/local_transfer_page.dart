import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/local_network_provider.dart';
import '../../../services/local_network_service.dart';
import 'local_setup_card.dart';
import 'local_send_backup_card.dart';
import 'local_recieve_backup_card.dart';

class LocalTransferPage extends StatelessWidget {
  const LocalTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localNetworkService = LocalNetworkService();
    return ChangeNotifierProvider<LocalNetworkProvider>(
      create: (_) => LocalNetworkProvider(localNetworkService),
      child: Column(
        children: [
          LocalSetupCard(),
          LocalSendBackupCard(),
          LocalRecieveBackupCard(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
