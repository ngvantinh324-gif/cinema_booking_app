// Người phụ trách: Tính (Nhóm trưởng)
import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF121420);
  static const surface = Color(0xFF1C1F2E);
  static const surfaceLight = Color(0xFF262A3D);
  static const primary = Color(0xFFFF8C00);
  static const textSecondary = Color(0xFF9A9DB0);
  static const seatAvailable = Color(0xFF2E3247);
  static const seatBooked = Color(0xFF161822);
  static const vip = Color(0xFFB36BFF);
  static const couple = Color(0xFFFF5C8A);
  static const success = Color(0xFF2ECC71);
  static const error = Color(0xFFFF5252);
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.black,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textSecondary,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerColor: Colors.white12,
    );
  }
}
