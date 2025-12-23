import 'package:flutter/material.dart';

/// Metadata for a category including English translations and styling.
class CategoryMetadata {
  const CategoryMetadata({
    required this.hebrewName,
    required this.englishName,
    required this.englishDescription,
    required this.hebrewDescription,
    required this.color,
  });

  final String hebrewName;
  final String englishName;
  final String englishDescription;
  final String hebrewDescription;
  final Color color;
}

/// Map of Hebrew category names to their metadata.
final Map<String, CategoryMetadata> categoryMetadataMap = {
  'תנ"ך': const CategoryMetadata(
    hebrewName: 'תנ"ך',
    englishName: 'Tanakh',
    englishDescription: 'Torah, Prophets, and Writings - the Hebrew Bible.',
    hebrewDescription: 'תורה, נביאים וכתובים - המקרא העברי.',
    color: Color(0xFF2196F3), // Blue
  ),
  'משנה': const CategoryMetadata(
    hebrewName: 'משנה',
    englishName: 'Mishnah',
    englishDescription: 'First major work of rabbinic literature.',
    hebrewDescription: 'יצירה ראשונה מרכזית בספרות חז"ל.',
    color: Color(0xFF673AB7), // Purple
  ),
  'תלמוד': const CategoryMetadata(
    hebrewName: 'תלמוד',
    englishName: 'Talmud',
    englishDescription: 'Rabbinic debates about law, ethics, and Bible.',
    hebrewDescription: 'ויכוחים רבניים על הלכה, מוסר ומקרא.',
    color: Color(0xFFFF9800), // Orange
  ),
  'מדרש': const CategoryMetadata(
    hebrewName: 'מדרש',
    englishName: 'Midrash',
    englishDescription: 'Interpretations of biblical texts.',
    hebrewDescription: 'פירושים לטקסטים מקראיים.',
    color: Color(0xFFFF5722), // Deep Orange
  ),
  'הלכה': const CategoryMetadata(
    hebrewName: 'הלכה',
    englishName: 'Halakhah',
    englishDescription: 'Legal works guiding Jewish life.',
    hebrewDescription: 'ספרים הלכתיים המנחים את החיים היהודיים.',
    color: Color(0xFFD32F2F), // Red
  ),
  'קבלה': const CategoryMetadata(
    hebrewName: 'קבלה',
    englishName: 'Kabbalah',
    englishDescription: 'Mystical works.',
    hebrewDescription: 'ספרי מיסטיקה.',
    color: Color(0xFF9C27B0), // Purple
  ),
  'סדר התפילה': const CategoryMetadata(
    hebrewName: 'סדר התפילה',
    englishName: 'Liturgy',
    englishDescription: 'Prayers and ritual texts.',
    hebrewDescription: 'תפילות וטקסטים ליטורגיים.',
    color: Color(0xFFE91E63), // Pink
  ),
  'מחשבת ישראל': const CategoryMetadata(
    hebrewName: 'מחשבת ישראל',
    englishName: 'Jewish Thought',
    englishDescription: 'Philosophy and theology.',
    hebrewDescription: 'פילוסופיה ותאולוגיה.',
    color: Color(0xFF3F51B5), // Indigo
  ),
  'תוספתא': const CategoryMetadata(
    hebrewName: 'תוספתא',
    englishName: 'Tosefta',
    englishDescription: 'Supplement to the Mishnah.',
    hebrewDescription: 'השלמה למשנה.',
    color: Color(0xFF00ACC1), // Cyan
  ),
  'חסידות': const CategoryMetadata(
    hebrewName: 'חסידות',
    englishName: 'Chasidut',
    englishDescription: 'Spiritual teachings.',
    hebrewDescription: 'תורות רוחניות.',
    color: Color(0xFF009688), // Teal
  ),
  'ספרי מוסר': const CategoryMetadata(
    hebrewName: 'ספרי מוסר',
    englishName: 'Musar',
    englishDescription: 'Ethical literature.',
    hebrewDescription: 'ספרות מוסרית.',
    color: Color(0xFF7B1FA2), // Deep Purple
  ),
  'שו"ת': const CategoryMetadata(
    hebrewName: 'שו"ת',
    englishName: 'Responsa',
    englishDescription: 'Rabbinic legal answers.',
    hebrewDescription: 'תשובות הלכתיות רבניות.',
    color: Color(0xFFC62828), // Dark Red
  ),
  'בית שני': const CategoryMetadata(
    hebrewName: 'בית שני',
    englishName: 'Second Temple',
    englishDescription: 'Second Temple period texts.',
    hebrewDescription: 'כתבים מתקופת בית שני.',
    color: Color(0xFF1565C0), // Dark Blue
  ),
  'מילונים וספרי יעץ': const CategoryMetadata(
    hebrewName: 'מילונים וספרי יעץ',
    englishName: 'Reference',
    englishDescription: 'Dictionaries and encyclopedias.',
    hebrewDescription: 'מילונים ואנציקלופדיות.',
    color: Color(0xFF424242), // Dark Gray
  ),
};

/// Get category metadata by Hebrew name, with fallback.
CategoryMetadata getCategoryMetadata(String hebrewName) {
  return categoryMetadataMap[hebrewName] ??
      CategoryMetadata(
        hebrewName: hebrewName,
        englishName: hebrewName,
        englishDescription: '',
        hebrewDescription: '',
        color: const Color(0xFF757575), // Gray fallback
      );
}
