import 'dart:convert';

/// A class that represents a book object.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.pages,
    this.city,
    this.rawYear,
  });

  /// Creates a [Book] from the json returned by the fetchInfo api call.
  Book.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        title = json['title'] as String,
        author = json['author'] as String,
        city = json['city'] as String?,
        rawYear = json['year'] as String?,
        pages = json['pages'] as int;

  /// The id of the book.
  ///
  /// The book is accessible at `https://beta.hebrewbooks.org/$id`.
  final int id;

  /// The title of the book.
  final String title;

  /// The author of the book.
  final String author;

  /// The city where the book was published.
  final String? city;

  /// The year value given by the json.
  final String? rawYear;

  /// The year of the book in the Gregorian calendar.
  String? get year => _dateToGregorian(rawYear);

  /// The number of pages in the book.
  final int pages;

  /// A map of hebrew letters to their corresponding numbers.
  static const Map<String, int> _gematria = {
    'א': 1,
    'ב': 2,
    'ג': 3,
    'ד': 4,
    'ה': 5,
    'ו': 6,
    'ז': 7,
    'ח': 8,
    'ט': 9,
    'י': 10,
    'כ': 20,
    'ך': 20,
    'ל': 30,
    'מ': 40,
    'ם': 40,
    'נ': 50,
    'ן': 50,
    'ס': 60,
    'ע': 70,
    'פ': 80,
    'ף': 80,
    'צ': 90,
    'ץ': 90,
    'ק': 100,
    'ר': 200,
    'ש': 300,
    'ת': 400,
  };

  String? _dateToGregorian(String? date) {
    if (date == null) return date;
    // If the date has a number, space, or dash return
    final notHebrew = RegExp('[A-Za-z-_]+');
    if (notHebrew.hasMatch(date)) {
      return date;
    }
    var sum = int.tryParse(date) ?? _lettersToNumbers(date);
    if (!sum.isFinite) {
      return date;
    }
    if (sum > 0 && sum < 1000) {
      sum += 5000;
    }
    sum -= 3760;
    return sum.toString();
  }

  int _lettersToNumbers(String date) {
    var sum = 0;
    for (var i = 0; i < date.length; i++) {
      sum += _gematria[date[i]]!;
    }
    return sum;
  }

  /// Converts this [Book] to json.
  String toJson() => json.encode({
        'id': id,
        'title': title,
        'author': author,
        'city': city,
        'year': rawYear,
        'pages': pages,
      });
}
//TODO: Have a better check if the converted date is correct
