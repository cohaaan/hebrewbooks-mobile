import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hebrewbooks/shared/api_urls.dart';
import 'package:hebrewbooks/shared/classes/book.dart';
import 'package:hebrewbooks/shared/classes/subject.dart';
import 'package:hebrewbooks/shared/network_aware_fetch.dart';
import 'package:html/parser.dart' as parser;
import 'package:intl/intl.dart';

/// Extracts the JSON string from [jsonp].
String extractJsonFromJsonp(String jsonp) {
  // Define the regex pattern to match the JSON within setBookInfo callback
  final regex = RegExp(r'callback\((.*?)\);');

  // Find the first match of the pattern
  final match = regex.firstMatch(jsonp);

  if (match != null) {
    // Extract the JSON string from the match
    if (match.group(1) != null && match.group(1) != '') {
      return match.group(1)!;
    } else {
      return '{}';
    }
  } else {
    throw Exception('No match found; JSONP callback not removed');
  }
}

/// Fetches the book info with the given [id].
Future<Book> fetchInfo(int id, BuildContext context) async {
  final url = ApiUrls.bookInfo(id);
  final capturedContext = context;

  try {
    final response =
        await NetworkAwareFetch.get(Uri.parse(url), capturedContext);

    if (response.statusCode == 200) {
      // Parse the JSON response
      final trueJson = extractJsonFromJsonp(response.body);
      return Book.fromJson(jsonDecode(trueJson) as Map<String, dynamic>);
    } else {
      // Handle server error with retry
      if (response.statusCode == 500) {
        return fetchInfo(id, capturedContext);
      }
      throw Exception('Failed to load book info: ${response.statusCode}');
    }
  } on FormatException catch (e) {
    throw FormatException('Failed to parse JSON: ${e.message}');
  } on Exception catch (e) {
    throw Exception('Network error: $e');
  }
}

/// Fetches the list of subjects.
Future<List<Subject>> fetchSubjects(BuildContext context) async {
  final url = ApiUrls.subjectList();

  try {
    final response = await NetworkAwareFetch.get(Uri.parse(url), context);

    if (response.statusCode == 200) {
      // Parse the response into subjects
      return Subject.fromJsonList(response.body);
    } else {
      debugPrint(
          'Failed subject list request: Status code: ${response.statusCode}, ${response.body}');
      throw Exception('Failed to load subjects');
    }
  } on Exception catch (e) {
    throw Exception('Network error: $e');
  }
}

/// Returns the URL for the cover image of the book with the given [id].
String coverUrl(int id, int width, int height) {
  return ApiUrls.coverImage(id, width, height);
}

/// Fetches the list of books in the subject with the given [id].
Future<List<int>> fetchSubjectBooks(
    int id, int start, int length, BuildContext context) async {
  final url = ApiUrls.booksInSubject(id, start, length);

  try {
    final res = await NetworkAwareFetch.read(Uri.parse(url), context);
    final jsonData =
        jsonDecode(extractJsonFromJsonp(res)) as Map<String, dynamic>;
    final data = jsonData['data'] as List<dynamic>?;

    if (data == null) {
      return [];
    } else {
      return data.map((book) {
        final dynamic bookId = book['id'];
        return int.parse(bookId.toString());
      }).toList();
    }
  } catch (e) {
    throw Exception('Failed to fetch subject books: $e');
  }
}

/// Fetches the list of books with the given search [query].
Future<List<int>> fetchSearchBooks(
    String query, int start, int length, BuildContext context) async {
  final url = ApiUrls.searchByTitle(query, start, length);

  try {
    final res = await NetworkAwareFetch.read(Uri.parse(url), context);
    final jsonData =
        jsonDecode(extractJsonFromJsonp(res)) as Map<String, dynamic>;
    final data = jsonData['data'] as List<dynamic>?;

    if (data == null) {
      return [];
    } else {
      return data.map((book) {
        final dynamic bookId = book['id'];
        return int.parse(bookId.toString());
      }).toList();
    }
  } catch (e) {
    throw Exception('Failed to fetch search results: $e');
  }
}

/// Fetches the total number of Hebrew books from the website.
Future<String?> fetchCount(BuildContext context) async {
  try {
    // 1. Make an HTTP GET request to the website.
    final url = Uri.parse(
        'https://hebrewbooks.org/?utm_source=flutter&utm_campaign=checkBookCount');
    final response = await NetworkAwareFetch.get(url, context);

    // Check if the request was successful (status code 200).
    if (response.statusCode == 200) {
      // 2. Parse the HTML document from the response body.
      final document = parser.parse(response.body);

      // 3. Find the specific element containing the book count.
      // Based on the website's structure, the count is in a table with id 'totsfrcnt'.
      // It's the second <td> element within the first row of that table.
      final tableElement = document.getElementById('totsfrcnt');

      if (tableElement != null) {
        // Find all the table data cells (<td>) within the table.
        final tableCells = tableElement.getElementsByTagName('td');

        if (tableCells.length > 1) {
          // The number is in the second cell (index 1).
          final countText = tableCells[1].text.trim();

          // 4. Extract and print the number.
          debugPrint('Successfully extracted book count text: "$countText"');

          // Remove commas to parse it as a number.
          final numberString = countText.replaceAll(',', '');
          final bookCount = int.tryParse(numberString);

          if (bookCount != null) {
            // Format the number with a thousands separator.
            final formatter = NumberFormat('#,###');
            final formattedCount = formatter.format(bookCount);
            return formattedCount;
          } else {
            debugPrint(
                'Error: Could not parse the number from the text: "$countText"');
          }
        } else {
          debugPrint(
              'Error: Could not find the correct table cell (<td>) with the book count.');
        }
      } else {
        debugPrint(
            'Error: Could not find the table element with id "totsfrcnt". The website structure might have changed.');
      }
    } else {
      debugPrint(
          'Error: Failed to load the website. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to fetch book count: $e');
  }
  return null;
}
