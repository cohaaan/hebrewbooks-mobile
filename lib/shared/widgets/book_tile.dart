import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hebrewbooks/screens/info.dart';
import 'package:hebrewbooks/shared/classes/book.dart';
import 'package:hebrewbooks/shared/fetch.dart';
import 'package:hebrewbooks/shared/widgets/centered_spinner.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:hebrewbooks/shared/widgets/network_aware_image.dart';

/// A tile that displays a book's title, author, and cover image.
///
/// The tile should be used in a BookList.
class BookTile extends StatefulWidget {
  const BookTile({required this.id, required this.removeFromSet, super.key});

  /// The id of the book.
  ///
  /// The book is accessible at `https://beta.hebrewbooks.org/$id`.
  final int id;

  /// A function that removes the book from the set that contains it.
  final Function removeFromSet;

  @override
  State<BookTile> createState() => _BookTileState();
}

class _BookTileState extends State<BookTile> {
  late Future<Book>? book;
  bool _isError = false;
  int _reloaded = 0;

  static const int _imageHeight = 56;

  @override
  void initState() {
    super.initState();
    book = _safeFetchBook(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      widget.removeFromSet(widget.id);
      return const SizedBox.shrink();
    }
    return FutureBuilder(
      future: book,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _errorHandler(snapshot.error);
        }
        if (snapshot.hasData) {
          final bookData = snapshot.data!;
          debugPrint(bookData.title);
          return Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              title: CustomText(
                bookData.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: CustomText(
                bookData.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              //TODO: Make the overflow less ugly
              trailing: NetworkAwareImage(
                imageUrl: coverUrl(bookData.id, 100, 100),
                height: _imageHeight.toDouble(),
                fit: BoxFit.fitHeight,
                loadingSize: _imageHeight ~/ 2,
                errorMessage: 'Cover not available',
              ),
              onTap: () {
                //TODO: Use a hero animation using the image
                FirebaseAnalytics.instance.logScreenView(
                  screenName: 'info',
                  parameters: {'book_id': widget.id},
                );
                Navigator.push(
                  context,
                  MaterialPageRoute<Widget>(
                    builder: (context) => Info(id: widget.id),
                  ),
                );
              },
              onLongPress: () {
                //TODO: Expand the image and stack it above the tile
              },
            ),
          );
        } else {
          return const CenteredSpinner();
        }
      },
    );
  }

  void _errorHandler(Object? error) {
    // TODO: Put real error handling here
    debugPrint('error --> $error');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_reloaded > 3) {
        setState(() {
          _isError = true;
        });
        return;
      }
      setState(() {
        book = fetchInfo(widget.id, context);
        _reloaded++;
      });
    });
  }

  Future<Book>? _safeFetchBook(int id) {
    try {
      return fetchInfo(id, context);
    } on FormatException {
      _isError = true;
    }
    return null;
  }
}
