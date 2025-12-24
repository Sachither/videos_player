import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class HeroImageContainer extends StatelessWidget {
  final String imageUrl;
  final bool showProfileImages;
  final bool showChatBubble;
  final List<String>? profileImages;
  final String? chatBubble;

  const HeroImageContainer({
    super.key,
    required this.imageUrl,
    this.showProfileImages = false,
    this.showChatBubble = false,
    this.profileImages,
    this.chatBubble,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero Image with Gradient Overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color:
                          isDark ? const Color(0xFF333226) : Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    );
                  },
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile Images (if enabled)
          if (showProfileImages && profileImages != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildProfileAvatar(
                profileImages![0],
                80,
                isDark,
              ),
            ),
          if (showProfileImages &&
              profileImages != null &&
              profileImages!.length > 1)
            Positioned(
              bottom: 8,
              right: 64,
              child: _buildProfileAvatar(
                profileImages![1],
                80,
                isDark,
              ),
            ),
          // Chat Bubble (if enabled)
          if (showChatBubble && chatBubble != null)
            Positioned(
              top: 40,
              left: 12,
              child: _buildChatBubble(chatBubble!, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String imageUrl, double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[400],
              child: const Icon(Icons.person),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.chatBubbleDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.splineSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textLightDark : AppColors.textDarkLight,
        ),
      ),
    );
  }
}
