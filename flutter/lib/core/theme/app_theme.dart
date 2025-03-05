import 'package:flutter/material.dart';

class AppTheme {
  // Updated color palette for a more modern look
  static const Color primaryColor = Color(0xFF4A6FE5);
  static const Color secondaryColor = Color(0xFF2A3F77);
  static const Color accentColor = Color(0xFF6C8EFF);
  @Deprecated('Use surfaceColor instead')
  static const Color backgroundColor = Color(0xFFF8F9FD);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFEEEEEE);

  // New colors for enhanced UI
  static const Color surfaceColor = Color(0xFFF0F4FF);
  static const Color shadowColor = Color(0x1A000000);
  static const Color highlightColor = Color(0xFFE3EAFF);

  // Persian font family
  static const String persianFontFamily = 'Vazirmatn';

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surfaceColor,
      fontFamily: persianFontFamily,
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: shadowColor,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: persianFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: persianFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: persianFontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(
          fontFamily: persianFontFamily,
          color: textSecondaryColor,
        ),
        labelStyle: const TextStyle(
          fontFamily: persianFontFamily,
          color: textSecondaryColor,
        ),
        prefixStyle: const TextStyle(color: textPrimaryColor),
        suffixStyle: const TextStyle(color: textPrimaryColor),
        floatingLabelStyle: const TextStyle(color: primaryColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        displayMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        displaySmall: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        bodyLarge: TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontFamily: persianFontFamily,
        ),
        bodyMedium: TextStyle(
          color: textPrimaryColor,
          fontSize: 14,
          fontFamily: persianFontFamily,
        ),
        bodySmall: TextStyle(
          color: textSecondaryColor,
          fontSize: 12,
          fontFamily: persianFontFamily,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        error: errorColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: persianFontFamily,
      cardTheme: CardTheme(
        color: const Color(0xFF2C2C2C),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        iconTheme: const IconThemeData(color: accentColor),
        shadowColor: Colors.black.withOpacity(0.3),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: persianFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: const BorderSide(color: accentColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: persianFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: persianFontFamily,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        hintStyle: const TextStyle(
          fontFamily: persianFontFamily,
          color: Color(0xFFAAAAAA),
        ),
        labelStyle: const TextStyle(
          fontFamily: persianFontFamily,
          color: Color(0xFFAAAAAA),
        ),
        prefixStyle: const TextStyle(color: Colors.white),
        suffixStyle: const TextStyle(color: Colors.white),
        floatingLabelStyle: const TextStyle(color: accentColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        displayMedium: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        displaySmall: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: persianFontFamily,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: persianFontFamily,
        ),
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: persianFontFamily,
        ),
        bodySmall: TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 12,
          fontFamily: persianFontFamily,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A3A3A),
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),
      iconTheme: const IconThemeData(
        color: accentColor,
        size: 24,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.withOpacity(0.5);
        }),
      ),
    );
  }
}
