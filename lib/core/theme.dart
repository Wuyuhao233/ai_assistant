import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 主色调 — 类似豆包的蓝色系
  static const Color primaryColor = Color(0xFF2563EB);    // 蓝
  static const Color secondaryColor = Color(0xFF7C3AED);  // 紫
  static const Color accentColor = Color(0xFF06B6D4);     // 青

  // 文字色
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // 背景色
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFF111827);

  // 消息气泡
  static const Color bubbleUser = Color(0xFF2563EB);
  static const Color bubbleAI = Color(0xFFF3F4F6);
  static const Color bubbleAIDark = Color(0xFF1F2937);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: bgCard,
    ),
    scaffoldBackgroundColor: bgLight,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: bgCard,
      foregroundColor: textPrimary,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
      ),
      color: bgCard,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF60A5FA),
      secondary: const Color(0xFFA78BFA),
      tertiary: const Color(0xFF22D3EE),
      surface: const Color(0xFF1F2937),
    ),
    scaffoldBackgroundColor: bgDark,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF1F2937),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF374151), width: 0.5),
      ),
      color: const Color(0xFF1F2937),
    ),
  );
}
