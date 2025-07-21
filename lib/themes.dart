import 'package:flutter/material.dart';

const Color gold = Color(0xFFFFD700);
const Color darkBackground = Color(0xFF121212);
const Color darkSurface = Color(0xFF1E1E1E);
const Color lightBackground = Colors.white;
const Color lightSurface = Color(0xFFF5F5F5);

ThemeData get darkTheme => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: darkBackground,
  fontFamily: 'Poppins',
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: gold,
    secondary: darkSurface,
    surface: darkSurface,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onSurface: Colors.white70,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: darkBackground,
    selectedItemColor: gold,
    unselectedItemColor: Colors.grey,
  ),
  cardTheme: CardThemeData(  // <-- Use CardThemeData here
    color: darkSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
  ),
);

ThemeData get lightTheme => ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: lightBackground,
  fontFamily: 'Poppins',
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: gold,
    secondary: lightSurface,
    surface: lightSurface,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onSurface: Colors.black87,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Poppins',
      fontWeight: FontWeight.bold,
      fontSize: 20,
      color: Colors.black,
    ),
    iconTheme: IconThemeData(color: Colors.black),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: lightBackground,
    selectedItemColor: gold,
    unselectedItemColor: Colors.grey[600],
  ),
  cardTheme: CardThemeData(  // <-- Use CardThemeData here
    color: lightSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black54),
    titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
  ),
);
