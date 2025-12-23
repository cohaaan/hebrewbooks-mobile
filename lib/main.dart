import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hebrewbooks/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hebrewbooks/l10n/app_localizations.dart';
import 'package:hebrewbooks/providers/back_to_top_provider.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/providers/downloads_provider.dart';
import 'package:hebrewbooks/providers/history_provider.dart';
import 'package:hebrewbooks/providers/saved_books_provider.dart';
import 'package:hebrewbooks/providers/search_query_provider.dart';
import 'package:hebrewbooks/providers/settings_provider.dart';
import 'package:hebrewbooks/screens/home.dart';
import 'package:hebrewbooks/screens/saved.dart';
import 'package:hebrewbooks/screens/search.dart';
import 'package:hebrewbooks/shared/theme.dart' as theme;
import 'package:hebrewbooks/shared/widgets/back_to_top.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobile-only initializations
  if (!kIsWeb) {
    // Request notification permission for iOS
    await Permission.notification.request();

    // Plugin must be initialized before using
    await FlutterDownloader.initialize(
      debug: true,
      // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          true, // option: set to false to disable working with http links (default: false)
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Log first open event
  FirebaseAnalytics.instance.logAppOpen();

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => ConnectionProvider()),
        ChangeNotifierProvider.value(value: BackToTopProvider.instance),
        ChangeNotifierProvider(create: (context) => SavedBooksProvider()),
        ChangeNotifierProvider.value(value: DownloadsProvider.instance),
        ChangeNotifierProvider.value(value: SearchQueryProvider.instance),
        ChangeNotifierProvider.value(value: HistoryProvider.instance),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Firebase Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// Firebase Analytics observer for tracking screen views
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  /// The version of the app.
  static String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          title: 'HebrewBooks',
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          themeMode: settingsProvider.themeMode,
          locale: Locale(settingsProvider.language),
          supportedLocales: const [
            Locale('en'),
            Locale('he'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          navigatorObservers: <NavigatorObserver>[observer],
          home: const MainPage(),
        );
      },
    );
  }
}

/// The main page of [MyApp]- it contains home, search and saved routes.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0; // Update the selected index to "Home"
          });
        }
      },
      child: Scaffold(
        // Use IndexedStack instead of array selection to preserve state of all screens
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            const Home(),
            Search(isActive: _selectedIndex == 1),
            const Saved(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            // Dismiss keyboard when changing tabs
            _dismissKeyboard();

            setState(() {
              _selectedIndex = index; // Update selected index
            });
            _logScreenView(index);
          },
          indicatorColor: Theme.of(context).colorScheme.tertiaryContainer,
          selectedIndex: _selectedIndex,
          // Ensure the correct index is displayed
          destinations: <Widget>[
            NavigationDestination(
              selectedIcon: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              icon: Icon(
                Icons.home_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              icon: Icon(
                Icons.search_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              label: 'Search',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              icon: Icon(
                Icons.star_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              label: 'Saved',
            ),
          ],
        ),
        floatingActionButton: BackToTop(route: _selectedIndex),
      ),
    );
  }

  /// Dismisses any active keyboard by unfocusing
  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  void _logScreenView(int index) {
    String screenName;
    switch (index) {
      case 0:
        screenName = 'home';
        break;
      case 1:
        screenName = 'search';
        break;
      case 2:
        screenName = 'saved';
        break;
      default:
        screenName = 'unknown';
    }
    FirebaseAnalytics.instance.logScreenView(screenName: screenName);
  }
}
