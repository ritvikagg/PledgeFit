import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2DD4BF), // teal-ish
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF6F7FB),
  cardTheme: const CardThemeData(
    elevation: 0.5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
  ),
  textTheme: const TextTheme(
    // Keep defaults from Material 3; override a couple for polish.
    bodyMedium: TextStyle(fontSize: 15),
  ),
);

