import 'dart:convert';

import 'package:hebrewbooks/shared/fetch.dart';

/// A class to represent a subject.
class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.total,
  });

  /// Creates a [Subject] from the json returned by the fetchSubjects api call.
  Subject.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        name = json['name'] as String,
        total = json['total'] as int;

  /// The hebrewbooks.org api id of the subject.
  final int id;

  /// The name of the subject.
  final String name;

  /// The total number of books in the subject.
  final int total;

  /// Creates a list of [Subject]s
  /// from the json returned by the fetchSubjects api call.
  static List<Subject> fromJsonList(String json) {
    final trueJson = extractJsonFromJsonp(json);
    final jsonList = jsonDecode(trueJson) as List<dynamic>;
    final subjects = <Subject>[];
    for (final json in jsonList) {
      subjects.add(Subject.fromJson(json as Map<String, dynamic>));
    }
    return subjects;
  }
}
