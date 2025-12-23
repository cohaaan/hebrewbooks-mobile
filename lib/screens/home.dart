import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hebrewbooks/main.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/providers/settings_provider.dart';
import 'package:hebrewbooks/screens/category.dart';
import 'package:hebrewbooks/screens/settings.dart';
import 'package:hebrewbooks/screens/webview_screen.dart';
import 'package:hebrewbooks/shared/category_metadata.dart';
import 'package:hebrewbooks/shared/classes/subject.dart';
import 'package:hebrewbooks/shared/fetch.dart';
import 'package:hebrewbooks/shared/widgets/category_card.dart';
import 'package:hebrewbooks/shared/widgets/centered_spinner.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:hebrewbooks/shared/widgets/offline.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// The home screen of the application.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Subject>> fullSubjects;

  late Future<String?> countFuture;

  @override
  void initState() {
    super.initState();
    countFuture = fetchCount(context);
    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjects();
      _checkConnection();
    });
  }

  Future<void> _loadSubjects() async {
    if (!mounted) return;

    try {
      fullSubjects = fetchSubjects(context);
      setState(() {});
    } on Exception {
      // If there's a connection error, show the offline dialog

      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      if (!connectionProvider.connected) {
        await Offline.showAsDialog(
          context,
          onRetry: _loadSubjects,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height,
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBar(
                  scrolledUnderElevation: 4,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shadowColor: Theme.of(context).colorScheme.shadow,
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: Align(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ),
                  title: Column(
                    children: <Widget>[
                      CustomText(
                        'HebrewBooks',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      FutureBuilder<String?>(
                        future: countFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return CustomText(
                              '${snapshot.data} Hebrew Books',
                              style: Theme.of(context).textTheme.titleSmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: <Widget>[
                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) {
                        return IconButton(
                          onPressed: () {
                            // Toggle between Hebrew and English
                            final newLang =
                                settings.language == 'he' ? 'en' : 'he';
                            settings.setLanguage(newLang);
                          },
                          icon: CustomText(
                            settings.language == 'he' ? 'א' : 'A',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          tooltip: settings.language == 'he'
                              ? 'Switch to English'
                              : 'Switch to Hebrew',
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        FirebaseAnalytics.instance.logScreenView(
                          screenName: 'settings',
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute<Widget>(
                            builder: (context) => const Settings(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
                    ),
                    IconButton(
                      onPressed: () {
                        _showAboutDialog(context);
                      },
                      icon: const Icon(Icons.info_outline),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Consumer<SettingsProvider>(
                        builder: (context, settings, child) {
                          final isHebrew = settings.language == 'he';
                          return FutureBuilder<List<Subject>>(
                            future: fullSubjects,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final subjects = snapshot.data!;

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: CustomText(
                                        isHebrew
                                            ? 'ספרייה'
                                            : 'Browse the Library',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Directionality(
                                      textDirection: isHebrew
                                          ? TextDirection.rtl
                                          : TextDirection.ltr,
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.85,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: subjects.length,
                                        itemBuilder: (context, index) {
                                          final subject = subjects[index];
                                          final metadata =
                                              getCategoryMetadata(subject.name);

                                          return CategoryCard(
                                            metadata: metadata,
                                            itemCount: subject.total,
                                            isRTL: isHebrew,
                                            onTap: () {
                                              FirebaseAnalytics.instance
                                                  .logScreenView(
                                                screenName: 'category',
                                                parameters: {
                                                  'category_id': subject.id,
                                                  'category_name': subject.name,
                                                },
                                              );
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute<Widget>(
                                                  builder: (context) =>
                                                      Category(
                                                    id: subject.id,
                                                    name: subject.name,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              } else if (snapshot.hasError) {
                                return const SizedBox.shrink();
                              }
                              return const CenteredSpinner();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-fetch when dependencies change (including when first built)
    if (!ModalRoute.of(context)!.isCurrent) return;

    _loadSubjects();
  }

  /// Check internet connection and show offline dialog if needed
  Future<void> _checkConnection() async {
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    final hasConnection = await connectionProvider.checkConnection();

    if (!hasConnection && mounted) {
      await Offline.showAsDialog(
        context,
        onRetry: _checkConnection,
      );
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: url.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomText.left('Email address copied to clipboard'),
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'HebrewBooks',
      applicationVersion: MyApp.appVersion,
      applicationIcon: Image.asset(
        'assets/images/logo.png',
        width: 36,
        height: 36,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.book, size: 36),
      ),
      children: [
        CustomText.left(
          'HebrewBooks.org is the largest collection of free seforim online, providing universal access to a vast collection of texts. HebrewBooks.org is a not-for-profit 501(c)(3) organization.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle:
                  (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
                      .copyWith(decoration: TextDecoration.underline),
            ),
            onPressed: () {
              _launchExternalUrl(
                  'https://hebrewbooks.org/virtmedia/PrivacyPolicy111925.html');
            },
            child: CustomText.left(
              'Privacy Policy',
              style:
                  (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
                      .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle:
                  (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
                      .copyWith(decoration: TextDecoration.underline),
            ),
            onPressed: () {
              _launchExternalUrl(
                  'https://hebrewbooks.org/virtmedia/TermsofUse111925_.html');
            },
            child: CustomText.left(
              'Terms of Use',
              style:
                  (Theme.of(context).textTheme.bodySmall ?? const TextStyle())
                      .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CustomText.left(
          'App designed and developed by Daniel Farkas',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Button with Address
            ElevatedButton.icon(
              onPressed: () {
                _launchExternalUrl('mailto:app@hebrewbooks.org');
              },
              icon: const Icon(Icons.email_outlined),
              label: CustomText('app@hebrewbooks.org'),
            ),
            const SizedBox(height: 8),
            // Feedback Form Button with Text
            ElevatedButton.icon(
              onPressed: () {
                // Close the dialog first
                Navigator.of(context).pop();
                FirebaseAnalytics.instance.logScreenView(
                  screenName: 'feedback_form',
                );
                // Then push the WebView screen
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(
                    builder: (context) => const WebViewScreen(
                      title: 'Feedback Form',
                      url:
                          'https://form.jotform.us/21148852504148?&feedbackType=Mobile%20Sites%20and%20Apps%20-%20%D7%90%D7%AA%D7%A8%D7%99%D7%9D%20%D7%95%D7%99%D7%99%D7%A9%D7%95%D7%9E%D7%99%D7%9D%20%D7%A0%D7%99%D7%99%D7%93%D7%99%D7%9D',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.feedback_outlined),
              label: CustomText('Send Feedback'),
            ),
            const SizedBox(height: 8),
            // Feedback Form Button with Text
            ElevatedButton.icon(
              onPressed: () {
                // Close the dialog first
                Navigator.of(context).pop();
                FirebaseAnalytics.instance.logScreenView(
                  screenName: 'github',
                );
                // Then push the WebView screen
                Navigator.of(context).push(
                  MaterialPageRoute<Widget>(
                    builder: (context) => const WebViewScreen(
                      title: 'HebrewBooks GitHub',
                      url: 'https://github.com/hebrewbooks/mobile_app_public',
                    ),
                  ),
                );
              },
              // github icon
              icon: const Icon(Icons.code_outlined),
              label: CustomText('GitHub Repository'),
            ),
          ],
        ),
      ],
    );
  }

}
