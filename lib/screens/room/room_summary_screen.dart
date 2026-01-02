import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomSummaryScreen extends StatelessWidget {
  final String movieTitle;
  final String moviePoster;
  final String durationWatched;
  final List<String> participants;
  final VoidCallback onReturnHome;

  const RoomSummaryScreen({
    super.key,
    required this.movieTitle,
    required this.moviePoster,
    required this.durationWatched,
    this.participants = const [],
    required this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    const primaryYellow = Color(0xFFF9F506);
    const backgroundDark = Color(0xFF23220F);
    const surfaceDark = Color(0xFF2E2D1A);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: Stack(
        children: [
          // Background Glow Pattern
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1.0),
                  radius: 1.2,
                  colors: [
                    primaryYellow.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Header Section
                    const SizedBox(height: 20),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: primaryYellow.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: primaryYellow,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Room Ended',
                      style: GoogleFonts.splineSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The host has closed the session.',
                      style: GoogleFonts.splineSans(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Recap Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: surfaceDark,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Inner Card (Movie Info)
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WATCHED',
                                        style: GoogleFonts.splineSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: primaryYellow,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        movieTitle,
                                        style: GoogleFonts.splineSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule,
                                              size: 16,
                                              color: Color(0xFFBBBA9B)),
                                          const SizedBox(width: 6),
                                          Text(
                                            durationWatched,
                                            style: GoogleFonts.splineSans(
                                              fontSize: 14,
                                              color: const Color(0xFFBBBA9B),
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
                                    color: surfaceDark,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 10,
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: moviePoster.contains('http')
                                        ? Image.network(
                                            moviePoster,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildPosterFallback(
                                                        primaryYellow),
                                            loadingBuilder:
                                                (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            primaryYellow
                                                                .withOpacity(
                                                                    0.5)),
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : _buildPosterFallback(primaryYellow),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Divider(
                                color: Colors.white.withOpacity(0.05),
                                height: 1),
                          ),

                          // Lower section (Participants & Rate)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
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
                                        color: Colors.white.withOpacity(0.3),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAvatarStack(participants),
                                  ],
                                ),
                                _buildRateButton(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Bottom Buttons
                    Column(
                      children: [
                        _buildPrimaryButton(
                          text: 'Return to Home',
                          onPressed: onReturnHome,
                          color: primaryYellow,
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) => TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Thank you for your report. Our team has been notified.'),
                                  backgroundColor: surfaceDark,
                                ),
                              );
                            },
                            child: Text(
                              'Report an issue',
                              style: GoogleFonts.splineSans(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterFallback(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.2),
            accentColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_creation_outlined,
          color: accentColor.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<String> participants) {
    // Limited display to 3 + count for aesthetics
    final displayCount = participants.length > 3 ? 3 : participants.length;
    return SizedBox(
      height: 36,
      width: participants.isEmpty ? 150 : (displayCount * 24.0 + 12.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0;
              i < (participants.length > 3 ? 3 : participants.length);
              i++)
            Positioned(
              left: i * 24.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade800,
                  border: Border.all(color: const Color(0xFF2E2D1A), width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white30, size: 20),
                ),
              ),
            ),
          if (participants.length > 3)
            Positioned(
              left: 72,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade700,
                  border: Border.all(color: const Color(0xFF2E2D1A), width: 3),
                ),
                child: Center(
                  child: Text(
                    '+${participants.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (participants.isEmpty)
            const Positioned(
              left: 0,
              top: 10,
              child: Text('Solo viewing session',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildRateButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F506).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFFF9F506), size: 18),
          const SizedBox(width: 8),
          Text(
            'Rate',
            style: GoogleFonts.splineSans(
              color: const Color(0xFFF9F506),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: GoogleFonts.splineSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
