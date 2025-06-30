import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Yeni Ana Renk Paleti - Splash/Login ile uyumlu
  static const Color primaryColor = Color(0xFF2E8B57); // Sea Green
  static const Color secondaryColor = Color(0xFF4169E1); // Royal Blue
  static const Color accentColor = Color(0xFF32CD32); // Lime Green
  static const Color tertiaryColor = Color(0xFF4682B4); // Steel Blue
  static const Color quaternaryColor = Color(0xFF9ACD32); // Yellow Green
  
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  
  // Dark Theme Colors - Blur gradyan ile uyumlu
  static const Color darkBackground = Color(0xFF0A1A0F); // Darker green tint
  static const Color darkSurface = Color(0xFF1A2D22); // Green-tinted dark
  static const Color darkCard = Color(0xFF233A2D); // Green-tinted card
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFB3D9C4); // Green-tinted gray
  
  // Light Theme Colors - Blur gradyan ile uyumlu  
  static const Color lightBackground = Color(0xFFF8FFFE); // Very light green tint
  static const Color lightSurface = Color(0xFFF0F8F5); // Light green tint
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1F2937);
  static const Color lightSecondaryText = Color(0xFF6B8072); // Green-tinted gray
  
  // Glassmorphism Colors
  static Color glassDark = Colors.white.withOpacity(0.1);
  static Color glassLight = Colors.black.withOpacity(0.05);
  static Color glassBorderDark = Colors.white.withOpacity(0.2);
  static Color glassBorderLight = Colors.black.withOpacity(0.1);
  
  // Note Card Colors - Glassmorphism tarzında
  static const List<Color> noteCardColors = [
    Color(0xFF7DD3FC), // Light Blue
    Color(0xFFFCA5A5), // Light Red
    Color(0xFFFDE68A), // Light Yellow
    Color(0xFFA7F3D0), // Light Green
    Color(0xFFDDD6FE), // Light Purple
    Color(0xFFFED7E2), // Light Pink
    Color(0xFFD1FAE5), // Light Mint
    Color(0xFFE0E7FF), // Light Indigo
  ];

  // Background Gradients
  static const List<Color> lightGradient = [
    Color(0xFFF8FAFF), // Light blue tint
    Color(0xFFE8F2FF), // Lighter blue
    Color(0xFFDCE9FF), // Pale blue
    Color(0xFFE8F5E8), // Light green
    Color(0xFFF0F8F0), // Very light green
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0F1F23), // Dark blue-green
    Color(0xFF1A2A3A), // Dark blue
    Color(0xFF1F3026), // Dark green
    Color(0xFF262651), // Dark blue-purple
    Color(0xFF2A4C32), // Dark green
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: lightText,
        outline: Color(0xFFE0E7E0), // Green-tinted outline
      ),
      
      scaffoldBackgroundColor: lightBackground,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: const IconThemeData(color: lightText),
        toolbarHeight: 80,
      ),
      
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: lightText,
          fontFamily: 'Inter',
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: lightText,
          fontFamily: 'Inter',
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightText,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightText,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: lightText,
          fontFamily: 'Inter',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: lightText,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: lightText,
          fontFamily: 'Inter',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightText,
          fontFamily: 'Inter',
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightSecondaryText,
          fontFamily: 'Inter',
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightSecondaryText,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: darkText,
        outline: Color(0xFF404A44), // Dark green-tinted outline
      ),
      
      scaffoldBackgroundColor: darkBackground,
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: const IconThemeData(color: darkText),
        toolbarHeight: 80,
      ),
      
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkText,
          fontFamily: 'Inter',
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkText,
          fontFamily: 'Inter',
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkText,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkText,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkText,
          fontFamily: 'Inter',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkText,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkText,
          fontFamily: 'Inter',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkText,
          fontFamily: 'Inter',
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkSecondaryText,
          fontFamily: 'Inter',
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkSecondaryText,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Helper methods for glassmorphism effects
  static BoxDecoration glassContainer(bool isDarkMode) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: isDarkMode ? glassDark : glassLight,
      border: Border.all(
        color: isDarkMode ? glassBorderDark : glassBorderLight,
        width: 1,
      ),
    );
  }

  static BoxDecoration glassCard(bool isDarkMode) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: isDarkMode ? glassDark : glassLight,
      border: Border.all(
        color: isDarkMode ? glassBorderDark : glassBorderLight,
        width: 1,
      ),
    );
  }

  // Background gradients for screens
  static Gradient backgroundGradient(bool isDarkMode) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDarkMode ? darkGradient : lightGradient,
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );
  }
} 