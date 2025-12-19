import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/providers/downloads_provider.dart';
import 'package:hebrewbooks/providers/saved_books_provider.dart';
import 'package:hebrewbooks/screens/read.dart';
import 'package:hebrewbooks/shared/api_urls.dart';
import 'package:hebrewbooks/shared/classes/book.dart';
import 'package:hebrewbooks/shared/fetch.dart';
import 'package:hebrewbooks/shared/widgets/centered_spinner.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:hebrewbooks/shared/widgets/network_aware_image.dart';
import 'package:hebrewbooks/shared/widgets/offline.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// The information page of a book.
class Info extends StatefulWidget {
  const Info({required this.id, super.key});

  /// The id of the book.
  ///
  /// The book is accessible at `https://beta.hebrewbooks.org/$id`.
  final int id;

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  Future<Book>? futureBook;

  static const imageHeight = 400;
  static const imageWidth = 300;

  @override
  void initState() {
    super.initState();
    _loadBookInfo();
    _setupDownloadCallbacks();
  }

  void _setupDownloadCallbacks() {
    DownloadsProvider.instance
      ..onDownloadComplete = (bookId, filePath) {
        if (bookId == widget.id && mounted) {
          Navigator.of(context).pop();
          _showDownloadCompleteSnackbar(filePath);
        }
      }
      ..onDownloadFailed = (bookId) {
        if (bookId == widget.id && mounted) {
          Navigator.of(context).pop();
          _showSnackBar('Download failed');
        }
      };
  }

  Future<void> _loadBookInfo() async {
    try {
      setState(() {
        futureBook = fetchInfo(widget.id, context);
      });
    } on Exception {
      // If there's a connection error, show the offline dialog
      if (!mounted) return;

      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      if (!connectionProvider.connected) {
        await Offline.showAsDialog(
          context,
          onRetry: _loadBookInfo,
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Handle download book workflow
  Future<void> _downloadBook(int bookId, String title) async {
    if (!mounted) return;

    final downloadsProvider =
        Provider.of<DownloadsProvider>(context, listen: false);

    // Check if already downloading
    if (downloadsProvider.isDownloading(bookId)) {
      _showSnackBar('Download already in progress');
      return;
    }

    try {
      // Start download
      final taskId = await downloadsProvider.downloadBook(bookId, title);

      if (!mounted) return;
      if (taskId == null) {
        _showSnackBar('Failed to start download');
        return;
      }

      // Show progress modal
      await _showDownloadProgressModal(title, bookId);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e');
    }
  }

  /// Show download progress modal
  Future<void> _showDownloadProgressModal(String title, int bookId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressModal(
        title: title,
        bookId: bookId,
      ),
    );
  }

  void _showDownloadCompleteSnackbar(String filePath) {
    final directory = Platform.isAndroid ? 'Downloads' : 'App Documents';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText.left('File saved to $directory'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => DownloadsProvider.instance.openDownload(widget.id),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Show a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: futureBook == null
            ? const CenteredSpinner()
            : FutureBuilder<Book>(
                future: futureBook,
                builder: (bookCtx, bookSnapshot) {
                  if (bookSnapshot.hasData) {
                    return _buildBookView(bookSnapshot, context);
                  } else if (bookSnapshot.hasError) {
                    // Show connection error if that's the issue
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final connectionProvider =
                          Provider.of<ConnectionProvider>(context,
                              listen: false);
                      if (!connectionProvider.connected) {
                        Offline.showAsDialog(
                          context,
                          onRetry: _loadBookInfo,
                        );
                      }
                    });
                    return const SizedBox.shrink();
                  }
                  // Loading state
                  return const CenteredSpinner();
                },
              ),
      ),
    );
  }

  /// Build the main book view
  Widget _buildBookView(
    AsyncSnapshot<Book> bookSnapshot,
    BuildContext context,
  ) {
    final book = bookSnapshot.data!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAppBar(book.title),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildCoverImage(book.id),
              _buildBookDetails(book),
              _buildActionButtons(bookSnapshot, context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  /// Build the app bar
  Widget _buildAppBar(String title) {
    return AppBar(
      scrolledUnderElevation: 4,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.shadow,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: CustomText(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  /// Build the cover image
  Widget _buildCoverImage(int bookId) {
    return NetworkAwareImage(
      imageUrl: ApiUrls.coverImage(bookId, imageWidth, imageHeight),
      height: imageHeight.toDouble(),
      fit: BoxFit.fitHeight,
      errorMessage: 'Cover image not available',
    );
  }

  /// Build the book details section
  Widget _buildBookDetails(Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            book.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          CustomText(
            book.author,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          CustomText(
            'Published: ${book.year}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          CustomText(
            'Pages: ${book.pages}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  /// Build the action buttons row
  Widget _buildActionButtons(
    AsyncSnapshot<Book> bookSnapshot,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSaveButton(bookSnapshot.data!),
        _buildShareButton(bookSnapshot.data!.title),
        _buildReadButton(bookSnapshot, context),
      ],
    );
  }

  /// Build the save/unsave button
  Widget _buildSaveButton(Book book) {
    return Consumer<SavedBooksProvider>(
      builder: (context, savedBooksProvider, _) {
        final isSaved = savedBooksProvider.isBookSaved(widget.id);

        return FloatingActionButton.extended(
          heroTag: isSaved ? 'unsave' : 'save',
          label: CustomText(isSaved ? 'Unsave' : 'Save'),
          icon: Icon(isSaved ? Icons.star : Icons.star_border_outlined),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          onPressed: () {
            if (isSaved) {
              savedBooksProvider.removeBook(widget.id);
            } else {
              savedBooksProvider.saveBook(book);
            }
          },
        );
      },
    );
  }

  /// Build the share buttonWidget _buildShareButton(String title)
  Widget _buildShareButton(String title) {
    return FloatingActionButton.extended(
      heroTag: 'share',
      label: CustomText('Share'),
      icon: const Icon(Icons.share_outlined),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      onPressed: () => showShareOptions(context, title),
    );
  }

  /// Build the read button
  Widget _buildReadButton(
      AsyncSnapshot<Book> bookSnapshot, BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'read',
      label: CustomText('Read'),
      icon: const Icon(Icons.book_outlined),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () => showReadOptions(bookSnapshot),
    );
  }

  /// Show share options menu
  void showShareOptions(BuildContext context, String title) {
    // TODO: Implement file sharing
    // showMenu<String>(
    //   context: context,
    //   position: const RelativeRect.fromLTRB(100, 100, 0, 0),
    //   items: [
    //     PopupMenuItem<String>(
    //       value: 'link',
    //       child: ListTile(
    //         leading: const Icon(Icons.link),
    //         title: CustomText('Share Link'),
    //       ),
    //     ),
    //     PopupMenuItem<String>(
    //       value: 'file',
    //       child: ListTile(
    //         leading: const Icon(Icons.file_upload_outlined),
    //         title: CustomText('Share File'),
    //       ),
    //     ),
    //   ],
    // ).then((value) {
    //   if (value == 'link') {
    shareLink(title);
    //   }
    // });
  }

  /// Show read options bottom sheet
  void showReadOptions(AsyncSnapshot<Book> bookSnapshot) {
    showModalBottomSheet<void>(
      context: context,
      builder: (bsContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: CustomText('Read in app', textAlign: TextAlign.left),
            onTap: () {
              Navigator.pop(bsContext);
              FirebaseAnalytics.instance
                  .logScreenView(screenName: 'Read', parameters: {
                'book_id': widget.id.toString(),
              });
              Navigator.push(
                context,
                MaterialPageRoute<Widget>(
                  builder: (context) => Read(
                    bookId: widget.id,
                    bookName: bookSnapshot.data!.title,
                  ),
                ),
              );
            },
          ),
          Consumer<DownloadsProvider>(
            builder: (context, downloadsProvider, child) {
              final isDownloading = downloadsProvider.isDownloading(widget.id);

              return ListTile(
                leading: Icon(isDownloading
                    ? Icons.downloading
                    : Icons.download_outlined),
                title: CustomText(
                  isDownloading ? 'Downloading...' : 'Download',
                  textAlign: TextAlign.left,
                ),
                enabled: !isDownloading,
                onTap: isDownloading
                    ? null
                    : () {
                        Navigator.pop(bsContext);
                        _downloadBook(widget.id, bookSnapshot.data!.title);
                      },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Share book link
  Future<void> shareLink(String name) async {
    final link = Uri.parse(ApiUrls.shareUrl(widget.id));
    await SharePlus.instance.share(ShareParams(uri: link, title: name));
  }
}

/// Download progress modal widget
class DownloadProgressModal extends StatelessWidget {
  const DownloadProgressModal({
    required this.title,
    required this.bookId,
    super.key,
  });

  final String title;
  final int bookId;

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadsProvider>(
      builder: (context, downloadsProvider, child) {
        final downloadInfo = downloadsProvider.getDownloadInfo(bookId);

        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: CustomText('Downloading'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (downloadInfo?.progress ?? 0) / 100,
                ),
                const SizedBox(height: 8),
                CustomText('${downloadInfo?.progress ?? 0}%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  downloadsProvider.cancelDownload(bookId);
                  Navigator.pop(context);
                },
                child: CustomText('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}
