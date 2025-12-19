import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/back_to_top_provider.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/providers/history_provider.dart';
import 'package:hebrewbooks/providers/search_query_provider.dart';
import 'package:hebrewbooks/shared/widgets/book_list.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:hebrewbooks/shared/widgets/offline.dart';
import 'package:provider/provider.dart';

/// The search screen of the application.
class Search extends StatefulWidget {
  const Search({this.isActive = false, super.key});

  /// Whether this screen is currently active/visible
  final bool isActive;

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchQueryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool _initialized = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchQueryController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackToTopProvider.instance.enabled = false;

      // Only set focus if the screen is active
      _initializeFocusIfActive();

      // Check connection at startup
      final connectionProvider =
          Provider.of<ConnectionProvider>(context, listen: false);
      if (!connectionProvider.connected) {
        Offline.showAsDialog(
          context,
          onRetry: () => setState(() {}),
        );
      }
    });
  }

  @override
  void didUpdateWidget(Search oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle changes in active status
    if (widget.isActive != oldWidget.isActive) {
      _handleActiveStateChange();
    }
  }

  void _initializeFocusIfActive() {
    if (widget.isActive && !_initialized) {
      _focusNode.requestFocus();
      _initialized = true;
    }
  }

  void _handleActiveStateChange() {
    if (widget.isActive) {
      // Only focus when becoming active if we're already initialized
      if (_initialized) {
        _focusNode.requestFocus();
      } else {
        _initializeFocusIfActive();
      }
    } else {
      // Clear focus when becoming inactive
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _focusNode.unfocus,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: _buildSearchBarInAppBar(context),
          titleSpacing: 0,
          automaticallyImplyLeading: false,
          elevation: 1,
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageView(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarInAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSearchField(context),
            ),
            if (_searchQueryController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_outlined),
                onPressed: () => _clearSearchQuery(context),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // The text field has lost focus, add the current query to the history.
        final query = _searchQueryController.text;
        if (query.isNotEmpty) {
          HistoryProvider.instance.addSearch(query);
        }
      }
    });

    return TextField(
      focusNode: _focusNode,
      controller: _searchQueryController,
      onChanged: _onSearchChanged,
      textAlignVertical: TextAlignVertical.center,
      textInputAction: TextInputAction.search,
      onTapOutside: (a) => _focusNode.unfocus(),
      textDirection: TextDirection.rtl,
      onSubmitted: (query) {
        _focusNode.unfocus();
        updateSearchQuery(query, context);
      },
      onTapUpOutside: (a) => _focusNode.unfocus(),
      decoration: InputDecoration(
        hintText: 'Search in HebrewBooks library...',
        border: InputBorder.none,
        hintStyle:
            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Only update if the search is valid
      updateSearchQuery(query, context);
    });
  }

  void updateSearchQuery(String newQuery, BuildContext context) {
    SearchQueryProvider.instance.searchQuery = newQuery;
  }

  Widget _buildPageView(BuildContext context) {
    return Consumer<SearchQueryProvider>(
      builder: (context, searchQueryProvider, child) {
        final searchQuery = searchQueryProvider.searchQuery;
        if (searchQuery.length < 3) {
          return Consumer<HistoryProvider>(
            builder: (context, historyProvider, child) {
              final history = historyProvider.cutHistory();
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        //TODO: Add a way to remove items from the history
                        ListTile(
                          title: CustomText(history[index]),
                          onTap: () {
                            setState(() {
                              _searchQueryController.text = history[index];
                              updateSearchQuery(history[index], context);
                            });
                          },
                          trailing: const Icon(Icons.history_outlined),
                        ),
                        const Divider(
                          height: 0,
                          thickness: 1,
                        ),
                      ],
                    );
                  },
                  itemCount: history.length,
                ),
              );
            },
          );
        }
        return BookList(
          type: 'search',
          scrollController: _scrollController,
          onConnectionError: _handleConnectionError,
        );
      },
    );
  }

  void _handleConnectionError() {
    Offline.showAsDialog(
      context,
      onRetry: () {
        final query = SearchQueryProvider.instance.searchQuery;
        if (query.length >= 3) {
          setState(() {});
        }
      },
    );
  }

  void _clearSearchQuery(BuildContext context) {
    setState(() {
      _searchQueryController.clear();
      updateSearchQuery('', context);
    });
  }
}
