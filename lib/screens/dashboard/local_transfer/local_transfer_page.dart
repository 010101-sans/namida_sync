import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/local_network_provider.dart';
import '../../../services/local_network_service.dart';
import 'local_setup_card.dart';
import 'local_send_backup_card.dart';
import 'local_recieve_backup_card.dart';

class LocalTransferPage extends StatefulWidget {
  const LocalTransferPage({super.key});

  @override
  State<LocalTransferPage> createState() => _LocalTransferPageState();
}

class _LocalTransferPageState extends State<LocalTransferPage> {
  bool _callbacksSet = false;

  @override
  void initState() {
    super.initState();
    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_callbacksSet) {
        final provider = Provider.of<LocalNetworkProvider>(context, listen: false);
        provider.setOnIncomingBackup((manifest) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Incoming Backup'),
              content: Text('Accept backup from ${manifest.backupName}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Decline')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Accept')),
              ],
            ),
          ) ?? false;
        });
        
        provider.setOnRestoreComplete(() async {
          await provider.restoreFromTempReceivedFiles(context);
        });
        
        _callbacksSet = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        LocalSetupCard(),
        SizedBox(height: 16),
        LocalSendBackupCard(),
        SizedBox(height: 16),
        LocalRecieveBackupCard(),
        SizedBox(height: 20),
      ],
    );
  }
}
