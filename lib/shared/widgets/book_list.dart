import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hebrewbooks/providers/back_to_top_provider.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/providers/search_query_provider.dart';
import 'package:hebrewbooks/shared/fetch.dart';
import 'package:hebrewbooks/shared/widgets/book_tile.dart';
import 'package:hebrewbooks/shared/widgets/centered_spinner.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:provider/provider.dart';

/// A list of [BookTile] widgets.
class BookList extends StatefulWidget {
  const BookList({
    required this.type,
    required this.scrollController,
    super.key,
    this.subjectId,
    this.onConnectionError,
    String? this.topic,
  }) : assert(
            (type == 'subject' && subjectId != null) ||
                (type == 'search') ||
                (type == 'browse'),
            'Wrong format');

  /// The source of the listed books.
  ///
  /// If [type] is 'subject', [subjectId] must be provided.
  /// If [type] is 'search' or 'browse', [subjectId] must not be provided.
  final String type;

  /// The ScrollController of the parent widget.
  final ScrollController scrollController;

  /// The id of the subject.
  ///
  /// Must be provided when [type] is 'subject'.
  final int? subjectId;

  /// Callback when a connection error occurs
  final VoidCallback? onConnectionError;

  /// The topic for predefined book IDs (used for 'browse' type).
  final String? topic;

  @override
  State<BookList> createState() => _BookListState();
}

class _BookListState extends State<BookList> {
  final Set<int> _books = {};
  int _upTo = 1;
  bool _isError = false;
  bool _isLoading = true;
  bool _isOver = false;
  bool _noResults = false;
  String _lastSearchQuery = '';
  static const int _perReq = 15;

  static const Map<String, List<int>> predefinedBookIds = {
    'תנ"ך': [
      9597,
      9596,
      9754,
      14084,
      9617,
      14264,
      14258,
      14263,
      14257,
      14262,
      14256,
      14261,
      14259,
      14260,
      14254
    ],
    'משניות': [
      37939,
      37940,
      37941,
      37942,
      37943,
      37944,
      37945,
      37946,
      37947,
      37948,
      37949,
      37950,
      37951
    ],
    'גמרא': [
      37952,
      37953,
      37954,
      37955,
      37956,
      37957,
      37958,
      37959,
      37960,
      37961,
      37962,
      37963,
      37964,
      37965,
      37969,
      37970,
      37966,
      37967,
      37968,
      37971,
      40053
    ],
    'רמב"ם': [
      58956,
      58957,
      58958,
      58959,
      58960,
      58961,
      58962,
      58963,
      58964,
      58965,
      58966,
      58967,
      58968
    ],
    'טור': [14265, 14268, 14267, 14272, 14266, 14271, 14270],
    'שולחן ערוך': [14326, 14325, 14327, 9145, 9146, 9147, 14398, 40538, 40539],
    'משנה ברורה': [60386, 60387, 60388, 60389, 60390, 60391]
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSearch();
    });

    widget.scrollController.addListener(() {
      if (!mounted) return;
      // nextPageTrigger will have a value equivalent to 80% of the list size.
      final nextPageTrigger =
          widget.scrollController.position.maxScrollExtent - 2000;
      if (widget.scrollController.position.pixels >= nextPageTrigger &&
          !_isOver) {
        _isLoading = true;
        _fetchData(context);
      }
      if (widget.scrollController.position.pixels > 100) {
        BackToTopProvider.instance.enabled = true;
      } else {
        BackToTopProvider.instance.enabled = false;
      }
    });

    BackToTopProvider.instance.addListener(() {
      if (!mounted) return;
      if (BackToTopProvider.instance.pressed) {
        widget.scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _initializeSearch() {
    if (widget.type == 'search') {
      final query = SearchQueryProvider.instance.searchQuery;
      if (query.length >= 3) {
        _resetAndSearch();
      }
    } else {
      _fetchData(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.type == 'search') {
      final searchProvider = SearchQueryProvider.instance;
      final query = searchProvider.searchQuery;

      // If the search query changed and is valid, reset and search
      if (searchProvider.hasChanged &&
          query.length >= 3 &&
          query != _lastSearchQuery) {
        searchProvider.markAsHandled();
        _resetAndSearch();
      }
    }
  }

  void _resetAndSearch() {
    setState(() {
      _isOver = false;
      _noResults = false;
      _isLoading = true;
      _isError = false;
      _books.clear();
      _upTo = 1;
      _lastSearchQuery = SearchQueryProvider.instance.searchQuery;
      _fetchData(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for search query changes
    if (widget.type == 'search') {
      final searchProvider = SearchQueryProvider.instance;
      final currentQuery = searchProvider.searchQuery;

      // If query changed to valid length and is different from last search
      if (searchProvider.hasChanged &&
          currentQuery.length >= 3 &&
          currentQuery != _lastSearchQuery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchProvider.markAsHandled();
          _resetAndSearch();
        });
      }
    }

    // Get connection status
    final connectionProvider =
        Provider.of<ConnectionProvider>(context, listen: false);
    final hasConnection = connectionProvider.connected;

    if (_books.isEmpty) {
      if (_isLoading) {
        return const CenteredSpinner();
      } else if (_isError && hasConnection) {
        // Only show error UI if we have connection but still got an error
        return Center(child: _errorDialog(size: 20));
      } else if (_noResults) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomText(
              'No Results',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        );
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _books.length + (_isOver ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == _books.length) {
            if (_isError && hasConnection) {
              // Only show error UI if we have connection but still got an error
              return Center(child: _errorDialog(size: 15));
            } else if (_isLoading) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ));
            } else {
              return null;
            }
          }
          final bookId = _books.elementAt(index);
          if (bookId < 0) {
            return null;
          }
          return BookTile(id: bookId, removeFromSet: _removeFromSet);
        },
      ),
    );
  }

  //TODO: Make the error dialog more user friendly
  Widget _errorDialog({required double size}) {
    return SizedBox(
      height: 180,
      width: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomText(
            'An error occurred when fetching the books.',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _isError = false;
                _fetchData(context);
              });
            },
            child: CustomText(
              'Retry',
              style: const TextStyle(fontSize: 20, color: Colors.purpleAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchData(BuildContext context) async {
    if (_noResults || _isOver || !mounted) {
      debugPrint(
        '''
          fetchData: noResults: $_noResults,
          isOver: $_isOver,
          mounted: $mounted
          ''',
      );
      return;
    }

    var searchQuery = '';
    if (widget.type == 'search') {
      searchQuery = SearchQueryProvider.instance.searchQuery;
      if (searchQuery.isEmpty || searchQuery.length < 3) return;
      _lastSearchQuery = searchQuery;
    }

    final subjectId = widget.subjectId;
    var isError = false;
    var response = <int>[];

    try {
      if (widget.type == 'subject' && subjectId != null) {
        response = await fetchSubjectBooks(subjectId, _upTo, _perReq, context);
      } else if (widget.type == 'browse') {
        final ids = predefinedBookIds[widget.topic];
        if (ids != null) {
          response = ids;
        }
      } else {
        response = await fetchSearchBooks(searchQuery, _upTo, _perReq, context);
        if (searchQuery.length >= 3) {
          await FirebaseAnalytics.instance.logSearch(searchTerm: searchQuery);
        }
      }

      if (response.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _noResults = true;
        });
        return;
      }
    } on Exception catch (e) {
      debugPrint('fetchData() failed: $e}');

      if (!mounted) return;

      // Check connection status
      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);

      // Only mark as error if we have connection but still got an error
      isError = connectionProvider.connected;

      // If no connection, trigger the offline dialog through parent
      if (!connectionProvider.connected && widget.onConnectionError != null) {
        widget.onConnectionError!();
      }
    }

    if (!mounted) return;
    setState(() {
      _isError = isError;
      if (!isError) {
        _noResults = false;
        _isOver = response.length < _perReq;
        _upTo += _perReq;
        for (final book in response) {
          _books.add(book);
        }
      }
      _isLoading = false;
    });
  }

  void _removeFromSet(int id) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _books.remove(id);
        debugPrint('Removed $id from the set');
      });
    });
  }
}
