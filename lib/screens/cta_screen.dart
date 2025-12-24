import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import 'permissions_screen.dart';

class CTAScreen extends StatelessWidget {
  final VoidCallback onGuestStart;
  final VoidCallback onSignUpLogin;

  const CTAScreen({
    super.key,
    required this.onGuestStart,
    required this.onSignUpLogin,
  });

  void _handleGuestStart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PermissionsScreen(
          onGrantPermissions: () {
            // TODO: Navigate to home screen
          },
          onMaybeLater: () {
            // TODO: Navigate to home screen or stay on permissions
          },
        ),
      ),
    );
  }

  void _handleSkip(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PermissionsScreen(
          onGrantPermissions: () {
            // TODO: Navigate to home screen
          },
          onMaybeLater: () {
            // TODO: Navigate to home screen or stay on permissions
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Top Skip Button
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: () => _handleSkip(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.splineSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textGreyDarkAlt
                                  : const Color(0xFF8c8b5f),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Hero Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              "https://lh3.googleusercontent.com/aida-public/AB6AXuDg1e0HBwXVZ5EfGZh38vtMUwOnzrbspeLP2UeZRKOV3L4OOmzMSTirV7xl_aGzHeWvuiYkt5B_wKZe9r4c0wtlIallAtg7hnuV3y1yEvkbQqhZE6UTx5B13IM2HN3o6jWxLXbF79_xKHhus2v3tXsRaRQRq_NKDEk6Q43vOBOtuJo3wL8PTRzT6ZWO-rdzqcHr_8egx4b_yGD85Cwy4i5Z8DpW3OyZ3q8mMYZIPTiCMzt2xR2jsNH_GmYTIMzJU2cHE8IInmBJZw7r",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDark
                                      ? const Color(0xFF333226)
                                      : Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Text Content
                      Column(
                        children: [
                          Text(
                            'Tap below to stop stressing and start doing!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.splineSans(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: isDark
                                  ? AppColors.textLightDark
                                  : AppColors.textDarkLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Watch local movies with friends seamlessly. Share your screen and react in real-time.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.splineSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: isDark
                                  ? AppColors.textGreyDark
                                  : AppColors.textDarkLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Action Buttons (fixed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              color:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Button: Guest
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
                      onPressed: () => _handleGuestStart(context),
                      child: Text(
                        'Get Started as guest',
                        style: GoogleFonts.splineSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Secondary Button: Sign Up/Login
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFFE5E5E5),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                      ),
                      onPressed: () => _handleGuestStart(context),
                      child: Text(
                        'Sign up/Login to get started',
                        style: GoogleFonts.splineSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textLightDark
                              : AppColors.textDarkLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
