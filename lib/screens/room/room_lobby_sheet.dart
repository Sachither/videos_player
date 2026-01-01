import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import 'room_player_screen.dart';

class RoomLobbySheet extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String movieId;
  final String hostName;
  final VoidCallback onCancel;

  const RoomLobbySheet({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.movieId,
    required this.hostName,
    required this.onCancel,
  });

  @override
  State<RoomLobbySheet> createState() => _RoomLobbySheetState();
}

class _RoomLobbySheetState extends State<RoomLobbySheet> {
  late StreamSubscription _roomSubscription;
  final RoomService _roomService = RoomService();
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    _checkHost();
    _subscribeToRoom();

    // If Host, auto-start after delay (simulating "syncing clock")
    if (_isHost) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _roomService.updateRoomStatus(widget.roomId, 'playing');
        }
      });
    }
  }

  void _checkHost() {
    final user = AuthService().currentUser;
    // Check if current user is the host by comparing display names
    // In production, this should check against Firebase hostIds
    _isHost = user?.displayName == widget.hostName || widget.hostName == 'Host';
  }

  void _subscribeToRoom() {
    _roomSubscription =
        _roomService.getRoomStream(widget.roomId).listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map;
        final status = data['status'];

        if (status == 'playing' && mounted) {
          final movie = data['movie'] as Map?;
          final videoUrl = movie?['url'] ?? '';

          Navigator.pop(context); // Close Lobby
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RoomPlayerScreen(
                        roomTitle: widget.roomTitle,
                        movieId: widget.movieId,
                        videoUrl: videoUrl,
                        roomId: widget.roomId,
                      )));
        }
      }
    });
  }

  @override
  void dispose() {
    _roomSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 32),

            // Header Section
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.theater_comedy,
                    color: AppColors.primaryLight, size: 24),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.roomTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.1,
                color: isDark ? Colors.white : const Color(0xFF181811),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hosted by ${widget.hostName}',
              style: GoogleFonts.splineSans(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),

            // Status Card
            Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF000000).withOpacity(0.2)
                    : Colors.grey.shade100.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  // Spinner
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryLight),
                          strokeWidth: 3,
                          backgroundColor:
                              AppColors.primaryLight.withOpacity(0.1),
                        ),
                        Icon(Icons.sync,
                            size: 28,
                            color: AppColors.primaryLight.withOpacity(0.8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Text
                  Text(
                    'Synchronizing clock...',
                    style: GoogleFonts.splineSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.primaryLight
                          : const Color(0xFF181811),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Line
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor:
                            isDark ? Colors.white10 : Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Est. wait: 2s',
                    style: GoogleFonts.notoSansMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Cancel
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? Colors.white38 : Colors.grey.shade500,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.splineSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
