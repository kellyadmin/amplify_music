import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

// Viba "Midnight Luxe" theme — vibrant, premium, zinc-based dark UI

ThemeData get darkTheme {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      tertiary: accentPurple,
      surface: cardColor,
      background: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
      outline: cardBorderColor,
    ),
  );

  final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: textColor,
    ),
    headlineLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: textColor,
    ),
    titleLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: textColor,
    ),
    titleMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: textColor,
    ),
    bodyLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: textColor,
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w500,
      color: subtitleColor,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: textColor,
    ),
  );

  // Elevated button with warm glow
  final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shadowColor: primaryColor.withOpacity(0.55),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16),
    elevation: 8,
  ).copyWith(
    elevation: MaterialStateProperty.resolveWith(
      (states) => states.contains(MaterialState.pressed) ? 3.0 : 8.0,
    ),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.disabled)) {
        return primaryColor.withOpacity(0.35);
      }
      return primaryColor;
    }),
  );

  final textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
  );

  final outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: textColor,
    side: BorderSide(color: cardBorderColor.withOpacity(0.6)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  );

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        letterSpacing: -0.2,
        color: textColor,
      ),
      iconTheme: IconThemeData(color: textColor),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textDisabledColor,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: surfaceGlass,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cardBorderColor.withOpacity(0.15)),
      ),
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: cardBorderColor.withOpacity(0.2),
      thickness: 0.5,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: GoogleFonts.manrope(
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

ThemeData get lightTheme {
  final base = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      tertiary: accentPurple,
      surface: Colors.white,
      background: Colors.white,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
    ),
  );

  final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: Colors.black,
    ),
    headlineLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: Colors.black,
    ),
    titleLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
      color: Colors.black,
    ),
    titleMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    bodyLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: Colors.black,
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontWeight: FontWeight.w500,
      color: Colors.black54,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: Colors.black,
    ),
  );

  final elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16),
    elevation: 4,
    shadowColor: primaryColor.withOpacity(0.3),
  );

  final textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15),
  );

  final outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: BorderSide(color: primaryColor.withOpacity(0.18)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  );

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 20,
        letterSpacing: -0.2,
        color: Colors.black,
      ),
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
  );
}
