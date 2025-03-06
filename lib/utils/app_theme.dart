import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryColorLight = Color(0xFF8F88FF);
  static const Color primaryColorDark = Color(0xFF4B44CC);
  
  // Secondary colors
  static const Color accentColor = Color(0xFF03DAC5);
  static const Color accentColorLight = Color(0xFF66FFF8);
  static const Color accentColorDark = Color(0xFF00A896);
  
  // Background colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceLight = Color(0xFF2C2C2C);
  static const Color darkCardColor = Color(0xFF2A2A2A);
  
  // Text colors
  static const Color primaryTextColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFFB3B3B3);
  static const Color textColor = Color(0xFFEEEEEE);
  
  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFB300);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Sleep stage colors
  static const Color deepSleepColor = Color(0xFF3949AB);
  static const Color lightSleepColor = Color(0xFF5C6BC0);
  static const Color remSleepColor = Color(0xFF7986CB);
  static const Color awakeSleepColor = Color(0xFF9FA8DA);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryColorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, accentColorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient morningGradient = LinearGradient(
    colors: [Color(0xFF64B3F4), Color(0xFF3A8ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient nightGradient = LinearGradient(
    colors: [Color(0xFF2B32B2), Color(0xFF1488CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text styles
  static const TextStyle headlineStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
  );
  
  static const TextStyle alarmTimeStyle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  // Get dark theme
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurface,
        background: darkBackground,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: primaryTextColor,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColorLight.withOpacity(0.5);
          }
          return null;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withOpacity(0.3),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
        valueIndicatorColor: primaryColor,
        valueIndicatorTextStyle: const TextStyle(
          color: primaryTextColor,
          fontFamily: 'Poppins',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: secondaryTextColor,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: secondaryTextColor,
        ),
      ),
      fontFamily: 'Poppins',
    );
  }
} 