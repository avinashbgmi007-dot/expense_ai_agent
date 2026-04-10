import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors — rich, premium fintech palette
  static const primaryColor = Color(0xFF1E3A5F); // Deep navy
  static const primaryLight = Color(0xFF3B82F6); // Bright blue accent
  static const secondaryColor = Color(0xFFF59E0B); // Warm amber
  static const backgroundColor = Color(0xFFF5F6FA); // Warm off-white
  static const surfaceColor = Colors.white;
  static const dangerColor = Color(0xFFEF4444);
  static const successColor = Color(0xFF10B981);
  static const textPrimaryColor = Color(0xFF1E293B);
  static const textSecondaryColor = Color(0xFF64748B);

  // Gradient for hero cards
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Subtle surface background
  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF8FAFC)],
  );

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFF97316), // Orange
    'transport': Color(0xFF3B82F6), // Blue
    'subscriptions': Color(0xFF8B5CF6), // Purple
    'shopping': Color(0xFFEC4899), // Pink
    'utilities': Color(0xFF14B8A6), // Teal
    'healthcare': Color(0xFF22C55E), // Green
    'finance': Color(0xFF6366F1), // Indigo
    'entertainment': Color(0xFFEF4444), // Red
    'mobile': Color(0xFF06B6D4), // Cyan
    'miscellaneous': Color(0xFF94A3B8), // Slate
  };

  // Card style helper
  static const cardShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const cardShadowSmall = BoxShadow(
    color: Color(0x06000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [cardShadow],
      );

  static BoxDecoration cardOutlineDecoration({Color? color}) => BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [cardShadowSmall],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: dangerColor,
      surface: surfaceColor,
      onSurface: textPrimaryColor,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shadowColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8ECF0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedIconTheme: IconThemeData(size: 24),
      unselectedIconTheme: IconThemeData(size: 22),
    ),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w800, color: textPrimaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700, color: textPrimaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: textPrimaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: textPrimaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500, color: textPrimaryColor,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimaryColor),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondaryColor),
      bodySmall: TextStyle(fontSize: 12, color: textSecondaryColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withOpacity(0.08),
      selectedColor: primaryColor,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: Color(0xFFE8ECF0),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF3B82F6), // Lighter blue for dark
      secondary: const Color(0xFFFBBF24), // Lighter amber
      error: const Color(0xFFEF4444),
      surface: const Color(0xFF1E293B),
      onSurface: const Color(0xFFF1F5F9),
      onPrimary: const Color(0xFF0F172A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF161E30),
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      color: const Color(0xFF1E293B),
      shadowColor: Colors.transparent,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF3B82F6),
      foregroundColor: Color(0xFF0F172A),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF161E30),
      selectedItemColor: Color(0xFF3B82F6),
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFF1F5F9),
      ),
      headlineMedium: TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9),
      ),
      headlineSmall: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9),
      ),
      titleLarge: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9),
      ),
      titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFF1F5F9),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFCBD5E1)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF3B82F6).withOpacity(0.15),
      selectedColor: const Color(0xFF3B82F6),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
