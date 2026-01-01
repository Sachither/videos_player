import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class RoomSummaryScreen extends StatelessWidget {
  final VoidCallback onReturnHome;
  final VoidCallback onReportIssue;

  const RoomSummaryScreen({
    super.key,
    required this.onReturnHome,
    required this.onReportIssue,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.8),
                  radius: 0.8,
                  colors: [
                    AppColors.primaryLight.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Header
                  Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.check_circle,
                          size: 36, color: AppColors.primaryLight),
                    ),
                  ),
                  Text(
                    'Room Ended',
                    style: GoogleFonts.splineSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF181811),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The host has closed the session.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.splineSans(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),

                  const Spacer(),

                  // Recap Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E2D1A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Movie Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WATCHED',
                                      style: GoogleFonts.splineSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryLight,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Interstellar: Director's Cut",
                                      style: GoogleFonts.splineSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF181811),
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: isDark
                                              ? const Color(0xFFBBBA9B)
                                              : Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '2hr 49min watched',
                                          style: GoogleFonts.splineSans(
                                            fontSize: 12,
                                            color: isDark
                                                ? const Color(0xFFBBBA9B)
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 80,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuANMhURGD2Au7cytwks6rLCs6WoRzbwd998rgdJjGBjslsIyS7N5HrqAmm3l_DUOMIbC26Iz-lJ2R6Qhan2N_VvekJEGsDuAec5rXmlb0TtckBJ9Cml-oYN2l3Dq1EPARw0sUu4xrJfFw3NDqHmb2a_p7jzZq9IEXBihsx-VaMbW6dJR4s-xUg78gFuEqPgB8Jz1lJUiBXwImPYyOODRykfUXEq5xgv-uD5lkZpJ3vz0cLiTq0dvIgWc_mRTOHDBtrdmeXs1f-CTJe0'),
                                    fit: BoxFit.cover,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Interaction Section
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'WITH FRIENDS',
                                    style: GoogleFonts.splineSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 32,
                                    child: Stack(
                                      children: [
                                        _buildAvatar(0),
                                        Positioned(
                                            left: 24, child: _buildAvatar(1)),
                                        Positioned(
                                            left: 48, child: _buildAvatar(2)),
                                        Positioned(
                                          left: 72,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white10
                                                  : Colors.grey.shade200,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF2E2D1A)
                                                      : Colors.white,
                                                  width: 2),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '+2',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),

                              // Rate Button
                              Container(
                                height: 36,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryLight.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16,
                                        color: AppColors.primaryLight),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rate',
                                      style: GoogleFonts.splineSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Return Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onReturnHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.backgroundDark,
                        elevation: 0,
                        shadowColor: AppColors.primaryLight.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Return to Home',
                        style: GoogleFonts.splineSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report
                  TextButton(
                    onPressed: onReportIssue,
                    child: Text(
                      'Report an issue',
                      style: GoogleFonts.splineSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(int index) {
    // Placeholder avatars
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.backgroundDark, width: 2),
      ),
    );
  }
}
