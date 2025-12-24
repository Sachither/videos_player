import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final int zIndex;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.zIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
}
