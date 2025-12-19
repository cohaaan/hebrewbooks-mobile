import 'package:flutter/material.dart';

/// A centered spinner that can be used to indicate loading.
class CenteredSpinner extends StatelessWidget {
  const CenteredSpinner({
    super.key,
    this.size = 100,
  });

  /// The size of the spinner.
  final int size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size.toDouble(),
          height: size.toDouble(),
          child: const CircularProgressIndicator(),
        ),
      ],
    );
  }
}
