// ignore_for_file: prefer_const_constructors, unused_import, implementation_imports

import 'package:flutter/material.dart';


class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green[800],
    primaryColorLight: Colors.green[100],
    primaryColorDark: Colors.green[900],
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.green[800]),
      titleMedium: TextStyle(color: Colors.grey[600]),
      bodySmall: TextStyle(color: Colors.grey[600]),
      labelLarge: TextStyle(color: Colors.green[800]),
    ),
    inputDecorationTheme: InputDecorationTheme(
      prefixIconColor: Colors.green,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        minimumSize: Size(double.infinity, 50),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.green[600],
    primaryColorLight: Colors.green[200],
    primaryColorDark: Colors.green[800],
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Color.fromRGBO(67, 160, 71, 1)),
      titleMedium: TextStyle(color: Colors.grey[400]),
      bodySmall: TextStyle(color: Colors.grey[400]),
      labelLarge: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      prefixIconColor: Colors.green[600],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green[600]!, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        minimumSize: Size(double.infinity, 50),
      ),
    ),
  );
}