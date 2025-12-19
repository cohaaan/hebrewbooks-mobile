import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A provider to handle the locally saved history.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider._internal() {
    loadHistory().then((_) {
      notifyListeners();
    });
  }

  static final HistoryProvider _instance = HistoryProvider._internal();

  /// Singleton instance
  static HistoryProvider get instance => _instance;

  List<String> _history = [];

  static const int _cutLength = 10;

  /// The list of history.
  List<String> get history => _history;

  /// Gets the list of history as strings from local storage.
  Future<List<String>> _getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('history') ?? [];
  }

  /// Loads the history from local storage and notifies listeners.
  Future<void> loadHistory() async {
    _history = await _getHistory();
    notifyListeners();
  }

  /// Adds a book to history.
  Future<void> addSearch(String query) async {
    if (_history.isNotEmpty && _history[_history.length - 1] == query) return;
    final prefs = await SharedPreferences.getInstance();
    final history = await _getHistory()
      ..add(query);
    await prefs.setStringList('history', history);
    await loadHistory();
  }

  /// Removes a book from history.
  Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _getHistory();
    history.removeWhere((q) => q == query);
    await prefs.setStringList('history', history);
    await loadHistory();
  }

  /// A cut-down version of [history] without duplicates and with [_cutLength].
  /// This returns books in reverse chronological order of being searched.
  List<String> cutHistory() {
    final history = _history.reversed.toList();
    final cutHistory = <String>[];
    for (final query in history) {
      if (!cutHistory.contains(query)) {
        cutHistory.add(query);
      }
      if (cutHistory.length == _cutLength) {
        break;
      }
    }
    return cutHistory;
  }
}
