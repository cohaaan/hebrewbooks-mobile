import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/saved_books_provider.dart';
import 'package:hebrewbooks/screens/info.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:provider/provider.dart';

/// The saved books screen.
class Saved extends StatefulWidget {
  const Saved({super.key});

  @override
  State<Saved> createState() => _SavedState();
}

class _SavedState extends State<Saved> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SavedBooksProvider>(
      builder: (context, savedBooksProvider, child) {
        final saved = savedBooksProvider.savedBooks;
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
                  title: CustomText(
                    'Saved',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  centerTitle: true,
                ),
                if (saved.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: CustomText(
                        "You don't have any saved books.",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  // SizedBox(
                  //   height: saved.length * 72.0,
                  //   child:
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            ListTile(
                              title: CustomText(
                                overflow: TextOverflow.ellipsis,
                                saved[index].title,
                              ),
                              subtitle: CustomText(
                                overflow: TextOverflow.ellipsis,
                                _formatAuthorAndYear(
                                  saved[index].author,
                                  saved[index].year,
                                ),
                              ),
                              onTap: () {
                                FirebaseAnalytics.instance.logScreenView(
                                    screenName: 'info',
                                    parameters: {
                                      'book_id': saved[index].id,
                                    });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<Widget>(
                                    builder: (context) => Info(
                                      id: saved[index].id,
                                    ),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.star),
                                onPressed: () {
                                  savedBooksProvider
                                      .removeBook(saved[index].id);
                                },
                              ),
                            ),
                            const Divider(
                              height: 0,
                              thickness: 1,
                            ),
                          ],
                        );
                      },
                      itemCount: saved.length,
                    ),
                  ),
                //),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAuthorAndYear(String? author, String? year) {
    const maxLength = 20; // Define your maximum length here
    var authorTruncated = author ?? '';
    if (authorTruncated.length > maxLength) {
      authorTruncated = '${authorTruncated.substring(0, maxLength)}...';
    }
    if (authorTruncated.isNotEmpty && year != null) {
      return '$authorTruncated • $year';
    } else if (authorTruncated.isNotEmpty) {
      return authorTruncated;
    } else if (year != null) {
      return year;
    } else {
      return '';
    }
  }
}
