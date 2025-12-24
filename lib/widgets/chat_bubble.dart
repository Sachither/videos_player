import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class ChatBubble extends StatefulWidget {
  final String text;

  const ChatBubble({super.key, required this.text});

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * (2 * (_controller.value - 0.5).abs() - 0.5)),
          child: child,
        );
      },
      child: Container(
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
          widget.text,
          style: GoogleFonts.splineSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLightDark : AppColors.textDarkLight,
          ),
        ),
      ),
    );
  }
}
