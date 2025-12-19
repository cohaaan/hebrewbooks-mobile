import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hebrewbooks/shared/classes/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A provider to handle locally saved (bookmarked) books.
class SavedBooksProvider extends ChangeNotifier {
  SavedBooksProvider() {
    _loadSavedBooks();
  }

  final Set<Book> _savedBooks = {};
  bool _isLoaded = false;

  /// The list of saved books.
  List<Book> get savedBooks => _savedBooks.toList();

  /// Adds a book to the saved list.
  void saveBook(Book book) {
    if (!_isLoaded) return;

    if (_savedBooks.add(book)) {
      _saveToPersistence();
      notifyListeners();
    }

    FirebaseAnalytics.instance.logEvent(
      name: 'save_book',
      parameters: {
        'book_id': book.id,
      },
    );
  }

  /// Removes a book from the saved list by ID.
  void removeBook(int bookId) {
    if (!_isLoaded) return;

    final bookToRemove =
        _savedBooks.where((book) => book.id == bookId).firstOrNull;
    _savedBooks.where((book) => book.id == bookId).firstOrNull;
    _savedBooks.where((book) => book.id == bookId).firstOrNull;
    if (bookToRemove != null) {
      _savedBooks.remove(bookToRemove);
      _saveToPersistence();
      notifyListeners();
    }

    FirebaseAnalytics.instance.logEvent(
      name: 'unsave_book',
      parameters: {
        'book_id': bookId,
      },
    );
  }

  /// Checks if a book is in the saved list.
  bool isBookSaved(int bookId) {
    return _savedBooks.any((book) => book.id == bookId);
  }

  /// Public method to manually trigger loading (for compatibility).
  Future<void> loadSavedBooks() async {
    // This is now a no-op since loading happens automatically
    if (!_isLoaded) {
      await _loadSavedBooks();
    }
  }

  /// Loads saved books from SharedPreferences.
  Future<void> _loadSavedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookStrings = prefs.getStringList('savedBooks') ?? [];

      _savedBooks.clear();
      for (final bookString in bookStrings) {
        try {
          final bookJson = jsonDecode(bookString) as Map<String, dynamic>;
          _savedBooks.add(Book.fromJson(bookJson));
        } catch (e) {
          debugPrint('Error parsing saved book: $e');
        }
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved books: $e');
      _isLoaded = true;
    }
  }

  /// Saves the current list to SharedPreferences.
  Future<void> _saveToPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookStrings = _savedBooks.map((book) => book.toJson()).toList();
      await prefs.setStringList('savedBooks', bookStrings);
    } catch (e) {
      debugPrint('Error saving books: $e');
    }
  }
}
