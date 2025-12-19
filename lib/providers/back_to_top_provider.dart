import 'package:flutter/foundation.dart';

/// A provider that handles the back to top button.
class BackToTopProvider extends ChangeNotifier {
  BackToTopProvider._internal();

  static final BackToTopProvider _instance = BackToTopProvider._internal();

  /// Singleton instance
  static BackToTopProvider get instance => _instance;

  bool _enabled = false;
  bool _pressed = false;

  /// Whether the back to top button is enabled.
  bool get enabled => _enabled;

  /// Whether the back to top button was pressed.
  bool get pressed => _pressed;

  set enabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      notifyListeners();
    }
  }

  /// Presses the back to top button.
  void press() {
    _pressed = true;
    notifyListeners();
    // Reset the pressed state after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _pressed = false;
      notifyListeners();
    });
  }
}
