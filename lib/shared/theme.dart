import 'package:flutter/material.dart';

Color _seed = const Color.fromRGBO(252, 88, 5, 1);

/// Light theme of MyApp.
ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  useMaterial3: true,
);
