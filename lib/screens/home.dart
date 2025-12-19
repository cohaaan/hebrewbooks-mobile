import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hebrewbooks/main.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/screens/browse.dart';
import 'package:hebrewbooks/screens/category.dart';
import 'package:hebrewbooks/screens/webview_screen.dart';
import 'package:hebrewbooks/shared/classes/subject.dart';
import 'package:hebrewbooks/shared/fetch.dart';
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

  // Track if the list is currently expanded
  bool _isExpanded = false;

  // Height of each subject item including divider
  final double subjectItemHeight = 56;

  // Minimum number of subjects to show
  final int minSubjectsToShow = 3;

  // Number of visible subjects that fit on screen
  int visibleSubjectsCount = 3;

  // Height of the bottom navigation bar
  final double navigationBarHeight = 80;

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

  // Calculate how many subjects can fit on the screen
  void _calculateVisibleSubjectsCount(List<Subject> subjects) {
    // Get available height for the subjects list
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const headingHeight =
        60.0; // Approximate height for "Subjects" heading and spacing
    const padding = 16.0;

    // Calculate available height
    final availableHeight = screenHeight -
        appBarHeight -
        statusBarHeight -
        headingHeight -
        padding -
        navigationBarHeight;

    // Calculate how many items can fit (ensuring a minimum of minSubjectsToShow)
    final calculatedCount = (availableHeight / subjectItemHeight).floor();
    visibleSubjectsCount = calculatedCount > minSubjectsToShow
        ? calculatedCount
        : minSubjectsToShow;

    // If we have fewer subjects than calculated count, show all of them
    if (subjects.length < visibleSubjectsCount) {
      visibleSubjectsCount = subjects.length;
    }

    // If we have more subjects than can fit, add 1 for "More" button
    if (subjects.length > visibleSubjectsCount) {
      visibleSubjectsCount =
          visibleSubjectsCount > 0 ? visibleSubjectsCount - 1 : 0;
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
                      _buildBrowse(context),
                      const SizedBox(
                        height: 24,
                      ),
                      FutureBuilder<List<Subject>>(
                        future: fullSubjects,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final subjects = snapshot.data!;
                            _calculateVisibleSubjectsCount(subjects);

                            // Prepare display subjects list
                            var displaySubjects = <Subject>[];

                            if (_isExpanded) {
                              // Show all subjects when expanded
                              displaySubjects = List<Subject>.from(subjects)
                                // Add "Less" button at the end
                                ..add(const Subject(
                                    id: -2, name: 'Less', total: -1));
                            } else if (subjects.length > visibleSubjectsCount) {
                              // Show limited subjects with "More" button
                              displaySubjects = List<Subject>.from(
                                  subjects.sublist(0, visibleSubjectsCount))
                                // Add "More" button
                                ..add(const Subject(
                                    id: -1, name: 'More', total: -1));
                            } else {
                              // Show all subjects if they fit within visible count
                              displaySubjects = List<Subject>.from(subjects);
                            }

                            return Column(
                              children: [
                                CustomText(
                                  'Subjects',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return Column(
                                          children: [
                                            if (index != 0) ...[
                                              const Divider(
                                                height: 0,
                                                thickness: 1,
                                              ),
                                            ],
                                            ListTile(
                                              title: CustomText(
                                                  displaySubjects[index].name),
                                              onTap: displaySubjects[index]
                                                          .id ==
                                                      -1
                                                  ? _expandList // More button
                                                  : displaySubjects[index].id ==
                                                          -2
                                                      ? _collapseList // Less button
                                                      : () {
                                                          FirebaseAnalytics
                                                              .instance
                                                              .logScreenView(
                                                                  screenName:
                                                                      'category',
                                                                  parameters: {
                                                                'category_id':
                                                                    displaySubjects[
                                                                            index]
                                                                        .id,
                                                                'category_name':
                                                                    displaySubjects[
                                                                            index]
                                                                        .name,
                                                              });
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute<
                                                                Widget>(
                                                              builder:
                                                                  (context) =>
                                                                      Category(
                                                                id: displaySubjects[
                                                                        index]
                                                                    .id,
                                                                name: displaySubjects[
                                                                        index]
                                                                    .name,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                              trailing: () {
                                                // Determine the correct icon based on button type
                                                if (displaySubjects[index].id ==
                                                    -1) {
                                                  // More button should always have down arrow
                                                  return const Icon(Icons
                                                      .keyboard_arrow_down);
                                                } else if (displaySubjects[
                                                            index]
                                                        .id ==
                                                    -2) {
                                                  // Less button should always have up arrow
                                                  return const Icon(
                                                      Icons.keyboard_arrow_up);
                                                } else {
                                                  return null;
                                                }
                                              }(),
                                            ),
                                          ],
                                        );
                                      },
                                      itemCount: displaySubjects.length,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return const SizedBox.shrink();
                          }
                          return const CenteredSpinner();
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

  // Show all subjects by setting isExpanded to true
  void _expandList() {
    setState(() {
      _isExpanded = true;
    });
  }

  // Collapse list back to initial size
  void _collapseList() {
    setState(() {
      _isExpanded = false;
    });
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

  Widget _buildBrowse(BuildContext context) {
    return Column(children: [
      CustomText(
        'Browse',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(
        height: 8,
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final textScaler = MediaQuery.textScalerOf(context);
          const baseMinButtonWidth = 100.0;
          final minButtonWidth = baseMinButtonWidth * textScaler.scale(1);
          final columns =
              (constraints.maxWidth / (minButtonWidth + spacing)).floor();
          final buttonWidth = columns > 0
              ? (constraints.maxWidth - spacing * (columns - 1)) / columns
              : constraints.maxWidth;

          final labels = [
            'משניות',
            'תנ"ך',
            'רמב"ם',
            'גמרא',
            'שולחן ערוך',
            'טור',
            'משנה ברורה'
          ];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: labels.map((label) {
                final l = label;
                return SizedBox(
                  width: buttonWidth,
                  child: FilledButton(
                    onPressed: () {
                      FirebaseAnalytics.instance.logEvent(
                        name: 'browse_button_tapped',
                        parameters: {'label': l},
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<Widget>(
                          builder: (context) => Browse(
                            name: l,
                            topic: l,
                          ),
                        ),
                      );
                    },
                    child: CustomText(l),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    ]);
  }
}
