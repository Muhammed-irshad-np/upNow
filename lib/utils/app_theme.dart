import 'package:flutter/material.dart';

enum AppThemeType {
  tealOrange,
  redOrange,
  blueYellow,
  purplePink,
  pastelPink,
  pastelBlue,
  pastelMint,
}

class AppTheme {
  static AppThemeType currentTheme = AppThemeType.tealOrange;

  // Primary colors
  static Color get primaryColor {
    switch (currentTheme) {
      case AppThemeType.redOrange:
        return const Color(0xFFFF9800);
      case AppThemeType.blueYellow:
        return const Color(0xFF2196F3);
      case AppThemeType.purplePink:
        return const Color(0xFF9C27B0);
      case AppThemeType.pastelPink:
        return const Color(0xFFFFB7B2);
      case AppThemeType.pastelBlue:
        return const Color(0xFFAEC6CF);
      case AppThemeType.pastelMint:
        return const Color(0xFF77DD77);
      case AppThemeType.tealOrange:
      default:
        return const Color.fromARGB(255, 28, 231, 167);
    }
  }

  static Color get primaryColorLight {
    switch (currentTheme) {
      case AppThemeType.redOrange:
        return const Color(0xFFFF6659);
      case AppThemeType.blueYellow:
        return const Color(0xFF6EC6FF);
      case AppThemeType.purplePink:
        return const Color(0xFFD05CE3);
      case AppThemeType.pastelPink:
        return const Color(0xFFFFD1CE);
      case AppThemeType.pastelBlue:
        return const Color(0xFFD1E0E4);
      case AppThemeType.pastelMint:
        return const Color(0xFFB2EEB2);
      case AppThemeType.tealOrange:
      default:
        return const Color.fromARGB(255, 32, 214, 120);
    }
  }

  static Color get primaryColorDark {
    switch (currentTheme) {
      case AppThemeType.redOrange:
        return const Color(0xFFAB000D);
      case AppThemeType.blueYellow:
        return const Color(0xFF0069C0);
      case AppThemeType.purplePink:
        return const Color(0xFF6A0080);
      case AppThemeType.tealOrange:
      default:
        return const Color.fromARGB(255, 0, 121, 57);
    }
  }

  // Secondary colors
  static Color get accentColor {
    switch (currentTheme) {
      case AppThemeType.redOrange:
        return const Color(0xFFFF5722);
      case AppThemeType.blueYellow:
        return const Color(0xFFFFEB3B);
      case AppThemeType.purplePink:
        return const Color(0xFFFF4081);
      case AppThemeType.tealOrange:
      default:
        return const Color(0xFFFF9800);
    }
  }

  static Color get accentColorLight {
    switch (currentTheme) {
      case AppThemeType.redOrange:
        return const Color(0xFFFF8A50);
      case AppThemeType.blueYellow:
        return const Color(0xFFFFFF72);
      case AppThemeType.purplePink:
        return const Color(0xFFFF79B0);
      case AppThemeType.tealOrange:
      default:
        return const Color(0xFFFFB74D);
    }
  }

  static Color get accentColorDark {
    switch (currentTheme) {
      case AppThemeType.redOrange:
        return const Color(0xFFBF360C);
      case AppThemeType.blueYellow:
        return const Color(0xFFC8B900);
      case AppThemeType.purplePink:
        return const Color(0xFFC60055);
      case AppThemeType.tealOrange:
      default:
        return const Color(0xFFF57C00);
    }
  }

  // Background colors - Changed to pure black and darker surfaces
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF0A0A0A);
  static const Color darkSurfaceLight = Color(0xFF1A1A1A);
  static const Color darkCardColor = Color(0xFF151515);

  // Light theme colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8F9FA);
  static const Color lightSurfaceLight = Color(0xFFE9ECEF);
  static const Color lightCardColor = Color(0xFFFFFFFF);

  // Text colors
  static const Color primaryTextColorDark = Color(0xFFFFFFFF);
  static const Color secondaryTextColorDark = Color(0xFFB3B3B3);
  static const Color textColorDark = Color(0xFFEEEEEE);

  static const Color primaryTextColorLight = Color(0xFF1A1A1A);
  static const Color secondaryTextColorLight = Color(0xFF6C757D);
  static const Color textColorLight = Color(0xFF212529);

  static bool isDarkMode = true;

  // Getters for theme-specific colors
  static Color get backgroundColor =>
      isDarkMode ? darkBackground : lightBackground;
  static Color get surfaceColor => isDarkMode ? darkSurface : lightSurface;
  static Color get primaryTextColor =>
      isDarkMode ? primaryTextColorDark : primaryTextColorLight;
  static Color get secondaryTextColor =>
      isDarkMode ? secondaryTextColorDark : secondaryTextColorLight;
  static Color get textColor => isDarkMode ? textColorDark : textColorLight;

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
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primaryColor, primaryColorLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => LinearGradient(
        colors: [accentColor, accentColorLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const LinearGradient morningGradient = LinearGradient(
    colors: [Color(0xFF64B3F4), Color(0xFF3A8ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient wakeUpGradient = LinearGradient(
    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nightGradient = LinearGradient(
    colors: [Color(0xFF2B32B2), Color(0xFF1488CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text styles
  static TextStyle get headlineStyle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  static TextStyle get titleStyle => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  static TextStyle get subtitleStyle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textColor,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontSize: 16,
        color: textColor,
      );

  static TextStyle get captionStyle => TextStyle(
        fontSize: 14,
        color: secondaryTextColor,
      );

  static TextStyle get alarmTimeStyle => TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  // Get dark theme
  static ThemeData getDarkTheme() {
    return _buildTheme(Brightness.dark);
  }

  // Get light theme
  static ThemeData getLightTheme() {
    return _buildTheme(Brightness.light);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color background = isDark ? darkBackground : lightBackground;
    final Color surface = isDark ? darkSurface : lightSurface;
    final Color surfaceLight = isDark ? darkSurfaceLight : lightSurfaceLight;
    final Color textPrimary =
        isDark ? primaryTextColorDark : primaryTextColorLight;
    final Color textSecondary =
        isDark ? secondaryTextColorDark : secondaryTextColorLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: accentColor,
              surface: surface,
              background: background,
              error: errorColor,
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: accentColor,
              surface: surface,
              background: background,
              error: errorColor,
            ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 4 : 2,
        shadowColor: isDark ? Colors.black : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: isDark ? 4 : 2,
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
          side: BorderSide(color: primaryColor, width: 2),
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
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
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
        valueIndicatorTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontFamily: 'Poppins',
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
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
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: textSecondary,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: textSecondary,
        ),
      ),
      fontFamily: 'Poppins',
    );
  }
}
