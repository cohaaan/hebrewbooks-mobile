import 'package:flutter/material.dart';
import 'package:hebrewbooks/providers/back_to_top_provider.dart';
import 'package:provider/provider.dart';

/// A floating action button that scrolls to the top of the page.
class BackToTop extends StatelessWidget {
  const BackToTop({
    super.key,
    this.route,
  });

  /// The route that the user is currently on in the MainPage.
  final int? route;

  // The main page route for the search page.
  static const _searchRoute = 1;

  @override
  Widget build(BuildContext context) {
    final routeNotifier = ValueNotifier<int?>(route);

    return ValueListenableBuilder<int?>(
      valueListenable: routeNotifier,
      builder: (context, route, child) {
        return Visibility(
          visible: context.watch<BackToTopProvider>().enabled &&
              (route == null || route == _searchRoute),
          child: FloatingActionButton(
            heroTag: "backToTop_${route ?? 'default'}",
            onPressed: () {
              context.read<BackToTopProvider>().press();
            },
            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            autofocus: true,
            child: const Icon(Icons.arrow_upward),
          ),
        );
      },
    );
  }
}
