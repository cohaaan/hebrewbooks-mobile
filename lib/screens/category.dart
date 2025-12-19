import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/connection_provider.dart';
import 'package:hebrewbooks/shared/widgets/back_to_top.dart';
import 'package:hebrewbooks/shared/widgets/book_list.dart';
import 'package:hebrewbooks/shared/widgets/custom_text.dart';
import 'package:hebrewbooks/shared/widgets/offline.dart';
import 'package:provider/provider.dart';

/// A page that displays a list of books in a specific category.
class Category extends StatefulWidget {
  const Category({required this.id, required this.name, super.key});

  /// The hebrewbooks.org api ID of the category.
  final int id;

  /// The display name of the category.
  final String name;

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 4,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.shadow,
          title: CustomText(
            widget.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookList(
                type: 'subject',
                scrollController: scrollController,
                subjectId: widget.id,
                onConnectionError: _handleConnectionError,
              ),
            ],
          ),
        ),
        floatingActionButton: const BackToTop(),
      ),
    );
  }

  void _handleConnectionError() {
    Offline.showAsDialog(
      context,
      onRetry: () => setState(() {}),
    );
  }
}
