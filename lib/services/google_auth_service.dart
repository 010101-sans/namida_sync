import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import '../utils/utils.dart';

class GoogleAuthService extends ChangeNotifier {
  // [1] Initialize the GoogleSignIn client for all platforms.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: GoogleSignInParams(
      clientId: clientId,
      clientSecret: clientSecret, // Required on Desktop
      redirectPort: 3000,
      scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
    ),
  );

  GoogleSignInCredentials? _currentCreds;
  GoogleSignInCredentials? get currentCreds => _currentCreds;

  GoogleAuthService() {
    // debugPrint('[GoogleAuthService] Initializing and attempting silent sign-in.');
    _init();
  }

  // [2] Attempt silent sign-in on startup and notify listeners.
  Future<void> _init() async {
    _currentCreds = await _googleSignIn.signIn();
    // debugPrint('[GoogleAuthService] Silent sign-in result: ${_currentCreds != null ? 'Success' : 'No credentials'}');
    notifyListeners();
  }

  // Public method for silent sign-in, to be called by provider
  Future<void> silentSignIn() async {
    await _init();
  }

  // [3] Initiate Google sign-in flow and update credentials.
  Future<GoogleSignInCredentials?> signIn() async {
    // debugPrint('[GoogleAuthService] Starting Google sign-in flow.');
    final creds = await _googleSignIn.signIn();
    if (creds != null) {
      _currentCreds = creds;
      // debugPrint('[GoogleAuthService] Sign-in successful.');
      notifyListeners();
    } else {
      // debugPrint('[GoogleAuthService] Sign-in failed or cancelled.');
    }
    return _currentCreds;
  }

  // [4] Sign out from Google and clear credentials.
  Future<void> signOut() async {
    // debugPrint('[GoogleAuthService] Signing out from Google.');
    await _googleSignIn.signOut();
    _currentCreds = null;
    notifyListeners();
  }

  // [5] Get authentication headers for Google API requests.
  Future<Map<String, String>?> getAuthHeaders() async {
    final creds = _currentCreds ?? await _googleSignIn.signIn();
    if (creds == null) {
      // debugPrint('[GoogleAuthService] No credentials available for auth headers.');
      return null;
    }
    return {'Authorization': 'Bearer ${creds.accessToken}'};
  }

  // [6] Check if the user is currently signed in.
  Future<bool> isSignedIn() async {
    return _currentCreds != null;
  }
}
