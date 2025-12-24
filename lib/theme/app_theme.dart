import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// App theme configuration
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      fontFamily: GoogleFonts.splineSans().fontFamily,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.splineSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDarkLight,
        ),
        headlineMedium: GoogleFonts.splineSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDarkLight,
        ),
        bodyLarge: GoogleFonts.splineSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textGreyLight,
        ),
        labelSmall: GoogleFonts.splineSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textGreyLight,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: GoogleFonts.splineSans().fontFamily,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.splineSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textLightDark,
        ),
        headlineMedium: GoogleFonts.splineSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textLightDark,
        ),
        bodyLarge: GoogleFonts.splineSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textGreyDark,
        ),
        labelSmall: GoogleFonts.splineSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textGreyDark,
        ),
      ),
    );
  }
}
