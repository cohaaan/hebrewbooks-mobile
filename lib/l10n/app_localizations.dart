import 'package:flutter/material.dart';

/// Simple localization class for the app
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Localized strings
  String get appTitle => locale.languageCode == 'he' ? 'ספרים עבריים' : 'HebrewBooks';
  String get home => locale.languageCode == 'he' ? 'בית' : 'Home';
  String get search => locale.languageCode == 'he' ? 'חיפוש' : 'Search';
  String get saved => locale.languageCode == 'he' ? 'שמורים' : 'Saved';
  String get settings => locale.languageCode == 'he' ? 'הגדרות' : 'Settings';
  String get language => locale.languageCode == 'he' ? 'שפה' : 'Language';
  String get theme => locale.languageCode == 'he' ? 'ערכת נושא' : 'Theme';
  String get networkUsage => locale.languageCode == 'he' ? 'שימוש ברשת' : 'Network Usage';
  String get allowMobileData => locale.languageCode == 'he' ? 'אפשר שימוש בנתונים סלולריים' : 'Allow mobile data usage';
  String get english => locale.languageCode == 'he' ? 'אנגלית' : 'English';
  String get hebrew => locale.languageCode == 'he' ? 'עברית' : 'Hebrew';
  String get light => locale.languageCode == 'he' ? 'בהיר' : 'Light';
  String get dark => locale.languageCode == 'he' ? 'כהה' : 'Dark';
  String get system => locale.languageCode == 'he' ? 'מערכת' : 'System';
  String get browse => locale.languageCode == 'he' ? 'עיון' : 'Browse';
  String get subjects => locale.languageCode == 'he' ? 'נושאים' : 'Subjects';
  String get more => locale.languageCode == 'he' ? 'עוד' : 'More';
  String get less => locale.languageCode == 'he' ? 'פחות' : 'Less';
  String get mobileDataWarningTitle => locale.languageCode == 'he' ? 'שימוש בנתונים סלולריים' : 'Mobile Data Usage';
  String get mobileDataWarningMessage => locale.languageCode == 'he'
      ? 'הגבלת שימוש בנתונים סלולריים בהגדרות. התחבר לרשת WiFi כדי להוריד תוכן או שנה את ההגדרות שלך.'
      : 'You have restricted mobile data usage in settings. Connect to WiFi to download content or change your settings.';
  String get ok => locale.languageCode == 'he' ? 'אישור' : 'OK';
  String get openSettings => locale.languageCode == 'he' ? 'פתח הגדרות' : 'Open Settings';

  String hebrewBooksCount(String count) {
    return locale.languageCode == 'he' ? '$count ספרים עבריים' : '$count Hebrew Books';
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'he'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
