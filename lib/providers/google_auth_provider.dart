import 'package:flutter/material.dart';
import '../services/services.dart';

// [1] Provider for managing Google authentication state and notifying listeners on changes.
class GoogleAuthProvider extends ChangeNotifier {
  final GoogleAuthService _authService = GoogleAuthService();

  GoogleAuthService get authService => _authService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // [2] Register a listener to notify UI when authentication state changes.
  GoogleAuthProvider() {
    // debugPrint('[GoogleAuthProvider] Adding listener to GoogleAuthService.');
    _authService.addListener(notifyListeners);
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    await _authService.silentSignIn();
    _isLoading = false;
    notifyListeners();
  }

  // [3] Remove the listener when the provider is disposed to prevent memory leaks.
  @override
  void dispose() {
    // debugPrint('[GoogleAuthProvider] Removing listener from GoogleAuthService and disposing provider.');
    _authService.removeListener(notifyListeners);
    super.dispose();
  }
}
