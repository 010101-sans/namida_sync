import 'package:flutter/material.dart';
import '../../../widgets/custom_card.dart';
import 'package:iconsax/iconsax.dart';

class GoogleAccount extends StatelessWidget {
  final bool isSignedIn;
  final dynamic user;
  final Color primaryColor;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final bool isLoading;

  const GoogleAccount({
    super.key,
    required this.isSignedIn,
    required this.user,
    required this.primaryColor,
    required this.onSignIn,
    required this.onSignOut,
    this.isLoading = false,
  });

  Widget _buildAvatar(dynamic user) {
    try {
      final photoUrl = user?.photoUrl;
      if (photoUrl != null && photoUrl is String && photoUrl.isNotEmpty) {
        return CircleAvatar(backgroundImage: NetworkImage(photoUrl), radius: 22);
      }
    } catch (_) {}
    return const CircleAvatar(radius: 22, child: Icon(Iconsax.profile_circle));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return Center(
        child: Container(margin: EdgeInsets.symmetric(vertical: 30), child: CircularProgressIndicator()),
      );
    }
    if (!isSignedIn) {
      // [1] Not Signed In Card
      return CustomCard(
        leadingIcon: Iconsax.cloud,
        title: 'Google Account',
        iconColor: primaryColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 28),
          child: ElevatedButton.icon(
            icon: const Icon(Iconsax.login),
            label: const Text('Sign in', style: TextStyle(fontSize: 15)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              side: BorderSide(color: primaryColor, width: 2),
              foregroundColor: primaryColor,
              backgroundColor: theme.colorScheme.surface.withAlpha(128),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            onPressed: onSignIn,
          ),
        ),
      );
    }

    // Signed-in UI
    String displayName = 'Signed in';
    try {
      if (user != null && user.name != null) {
        displayName = user.name;
      }
    } catch (_) {}

    String email = '';
    try {
      if (user != null && user.email != null) {
        email = user.email;
      }
    } catch (_) {}

    // [2] Signed In Card
    return CustomCard(
      leadingIcon: Iconsax.cloud,
      title: 'Google Drive Account',
      iconColor: primaryColor,
      headerActions: [
        // [2.1] Sign Out Button
        IconButton(icon: const Icon(Iconsax.logout), color: primaryColor, tooltip: 'Sign out', onPressed: onSignOut),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // [2.2] User Avatar
            _buildAvatar(user),
            const SizedBox(width: 18),

            // [2.3] User Info Column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [2.3.1] Display Name
                  Text(
                    displayName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // [2.3.2] Email
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
