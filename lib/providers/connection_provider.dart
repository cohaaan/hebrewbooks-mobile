import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Provider to check internet connection status.
class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider() {
    // Initial connection check on startup without showing any UI
    _checkConnectionSilently();
  }

  bool _connected = true;
  bool _isCheckingConnection = false;

  /// Whether the device is connected to the internet.
  bool get connected => _connected;

  /// Whether a connection check is currently in progress
  bool get isCheckingConnection => _isCheckingConnection;

  /// Checks the internet connection status silently (on startup)
  Future<bool> _checkConnectionSilently() async {
    try {
      final result = await InternetConnection().hasInternetAccess;
      _connected = result;
      notifyListeners();
    } on Exception {
      _connected = false;
      notifyListeners();
    }
    return _connected;
  }

  /// Checks the internet connection status and notifies listeners.
  Future<bool> checkConnection() async {
    _isCheckingConnection = true;
    notifyListeners();

    try {
      final result = await InternetConnection().hasInternetAccess;
      _connected = result;
    } on Exception {
      _connected = false;
    }

    _isCheckingConnection = false;
    notifyListeners();
    return _connected;
  }
}
