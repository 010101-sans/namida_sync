import 'package:flutter/material.dart';
import '../providers/providers.dart';
import 'package:iconsax/iconsax.dart';

// [1] Status label widget for file/folder transfer status
Widget buildLocalTransferStatusLabel(BuildContext context, {required String status}) {
  Color color;
  IconData icon;
  switch (status) {
    case 'Transferred':
      color = Colors.green;
      icon = Iconsax.tick_circle;
      break;
    case 'Transferring':
      color = Theme.of(context).colorScheme.primary;
      icon = Iconsax.send_2;
      break;
    case 'Skipped':
      color = Colors.orange;
      icon = Iconsax.next;
      break;
    case 'Failed':
      color = Colors.red;
      icon = Iconsax.close_circle;
      break;
    default:
      color = Colors.blueGrey;
      icon = Iconsax.info_circle;
  }
  return Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(
        status,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

// [2] Get the status string for backup zip during local transfer
String getLocalTransferBackupStatus(LocalNetworkProvider provider) {
  if (provider.error != null) return 'Failed';
  if (provider.progress == 1.0) return 'Transferred';
  if (provider.isSending && provider.progress > 0.0) return 'Transferring';
  return 'Pending';
}

// [3] Get the status string for music folders during local transfer
String getLocalTransferMusicStatus(LocalNetworkProvider provider) {
  if (provider.error != null) return 'Failed';
  if (provider.progress == 1.0) return 'Transferred';
  if (provider.isSending && provider.progress > 0.5) return 'Transferring';
  return 'Pending';
}

// [4] Get the status string for backup zip during local receive
String getLocalReceiveBackupStatus(LocalNetworkProvider provider) {
  if (provider.error != null) return 'Failed';
  if (provider.progress == 1.0) return 'Received';
  if (provider.isReceiving && provider.progress > 0.0) return 'Receiving';
  return 'Pending';
}

// [5] Get the status string for music folders during local receive
String getLocalReceiveMusicStatus(LocalNetworkProvider provider) {
  if (provider.error != null) return 'Failed';
  if (provider.progress == 1.0) return 'Received';
  if (provider.isReceiving && provider.progress > 0.5) return 'Receiving';
  return 'Pending';
}

// [6] Normalize file/folder paths for consistent comparison
String normalizeLocalPath(String path) {
  var n = path.replaceAll('\\', '/');
  if (n.length > 2 && n[1] == ':') {
    n = n[0].toLowerCase() + n.substring(1);
  }
  if (n.endsWith('/')) n = n.substring(0, n.length - 1);
  return n;
} 