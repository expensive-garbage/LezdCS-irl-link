import 'package:flutter/material.dart';

class Themes {
  final ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      background: Color(0xFF0e0e10),
      secondary: Color(0xFF18181b),
      error: Color(0xFFEC0808),

      //buttons color
      tertiary: Colors.deepPurpleAccent[200],
      tertiaryContainer: Colors.grey[850],
    ),
    textTheme: TextTheme(bodyLarge: TextStyle(color: Colors.white)),
    primaryIconTheme: IconThemeData(color: Colors.white),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[600]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[600]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.deepPurpleAccent[200]!),
      ),
    ),
  );

  final ThemeData lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      background: Color(0xFFffffff),
      secondary: Color(0xFFefeff1),
      error: Color(0xFFEC0808),

      //buttons color
      tertiary: Colors.deepPurpleAccent[200],
      tertiaryContainer: Colors.grey[850],
    ),
    textTheme: TextTheme(bodyLarge: TextStyle(color: Colors.black)),
    primaryIconTheme: IconThemeData(color: Colors.black),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
    ),
  );
}
