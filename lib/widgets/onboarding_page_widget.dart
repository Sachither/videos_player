import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/onboarding_page.dart';
import '../../widgets/hero_image_container.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            // Hero Image Container
            HeroImageContainer(
              imageUrl: page.heroImage,
              showProfileImages: page.showProfileImages,
              showChatBubble: page.showChatBubble,
              profileImages: page.profileImages,
              chatBubble: page.chatBubble,
            ),
            const SizedBox(height: 48),
            // Text Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with highlighted subtitle
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${page.title} ',
                        style: GoogleFonts.splineSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          color: isDark
                              ? AppColors.textLightDark
                              : AppColors.textDarkLight,
                        ),
                      ),
                      TextSpan(
                        text: page.subtitle,
                        style: GoogleFonts.splineSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                          color: isDark
                              ? AppColors.accentYellow
                              : const Color(0xFFD4A500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textGreyDark
                        : AppColors.textGreyLightAlt,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          ],
        ),
      ),
    );
  }
}
