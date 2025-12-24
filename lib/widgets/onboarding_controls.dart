import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class OnboardingControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == currentPage ? 32 : 10,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: index == currentPage
                      ? (isDark
                          ? AppColors.primaryDark
                          : AppColors.textDarkLight)
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Buttons
          Column(
            children: [
              // Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.textDarkLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 2,
                  ),
                  onPressed: onNext,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: GoogleFonts.splineSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Skip Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.splineSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textGreyDark
                          : AppColors.textGreyLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
