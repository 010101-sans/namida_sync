import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../google_drive/google_account.dart';
import '../google_drive/backup_card.dart';
import '../google_drive/restore_card.dart';
import '../../../providers/providers.dart';

class GoogleDrivePage extends StatelessWidget {
  const GoogleDrivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GoogleAuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.authService.currentCreds;
        final isSignedIn = user != null;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        return Column(
          children: [
            // [1] Google Drive Setup Card (GoogleAccount)
            GoogleAccount(
              isSignedIn: isSignedIn,
              user: user,
              primaryColor: primaryColor,
              onSignIn: () async {
                try {
                  await authProvider.authService.signIn();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
                }
              },
              onSignOut: () async {
                await authProvider.authService.signOut();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
              },
              isLoading: authProvider.isLoading,
            ),
            // [2] Google Drive Cards (only if signed in)
            if (isSignedIn) ...[
              // [2.1] GoogleDriveBackupCard
              const GoogleDriveBackupCard(),
              // [2.2] GoogleDriveRestoreCard
              GoogleDriveRestoreCard(
                onRestoreComplete: Provider.of<FolderProvider>(context, listen: false).refreshFolderList,
              ),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
