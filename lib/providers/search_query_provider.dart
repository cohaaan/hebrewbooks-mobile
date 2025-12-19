import 'package:flutter/foundation.dart';

/// Provider that provides the search query.
class SearchQueryProvider extends ChangeNotifier {
  SearchQueryProvider._internal();

  static final SearchQueryProvider _instance = SearchQueryProvider._internal();

  /// Singleton instance
  static SearchQueryProvider get instance => _instance;

  String _searchQuery = '';
  bool _hasChanged = false;

  /// The current search query.
  String get searchQuery => _searchQuery;

  /// Whether the search query has changed since the last search.
  bool get hasChanged => _hasChanged;

  /// Marks the current query as handled
  void markAsHandled() {
    _hasChanged = false;
  }

  set searchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
      _hasChanged = true;
      notifyListeners();
    }
  }
}
