import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/room_service.dart';
import 'room/room_player_screen.dart';

class RoomView extends StatefulWidget {
  final bool isDark;

  const RoomView({super.key, required this.isDark});

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  final RoomService _roomService = RoomService();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _foundRoom;
  String? _foundRoomId;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchRoom(String code) async {
    if (code.length != 6) {
      if (_foundRoom != null) {
        setState(() {
          _foundRoom = null;
          _foundRoomId = null;
        });
      }
      return;
    }

    setState(() => _isSearching = true);

    try {
      final snapshot = await _roomService.getRoom(code).get();
      if (snapshot.exists) {
        setState(() {
          _foundRoom = Map<String, dynamic>.from(snapshot.value as Map);
          _foundRoomId = code;
        });
      } else {
        setState(() {
          _foundRoom = null;
          _foundRoomId = null;
        });
      }
    } catch (e) {
      print('Error searching room: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  bool _isJoining = false;

  Future<void> _handleJoin(String roomId, Map<String, dynamic> room) async {
    if (_isJoining) return;

    setState(() => _isJoining = true);

    try {
      // RoomService will now handle anonymous auth internally if needed
      await _roomService.joinRoom(roomId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomPlayerScreen(
              roomId: roomId,
              movieId: room['movie']['id'] ?? 'unknown',
              roomTitle: room['movie']['title'] ?? 'Room',
              videoUrl: room['movie']['url'] ?? '',
              isHost: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        if (_foundRoom != null) ...[
                          _buildSectionHeader('Live Rooms'),
                          _buildRoomItem(_foundRoom!, _foundRoomId!),
                        ],
                        _buildCreateRoomPlaceholder(),
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isJoining)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryLight),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Entering Theater...',
                        style: GoogleFonts.splineSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.arrow_back_ios_new,
              size: 20,
              color: widget.isDark ? Colors.white : AppColors.textDarkLight),
          Expanded(
            child: Center(
              child: Text(
                'Find a Room',
                style: GoogleFonts.splineSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.textDarkLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // Placeholder to balance arrow
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF323118) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border:
              widget.isDark ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: _isSearching
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search,
                      color: Color(0xFF8C8B5F), size: 24),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _searchRoom,
                style: GoogleFonts.splineSans(
                  color: widget.isDark ? Colors.white : AppColors.textDarkLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search room code (e.g. 123456)',
                  hintStyle: GoogleFonts.splineSans(
                    color: widget.isDark
                        ? Colors.grey.shade500
                        : const Color(0xFF8C8B5F),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _searchController.text = data!.text!;
                    _searchRoom(data.text!);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.content_paste,
                      color: Color(0xFF181811), size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.splineSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppColors.textDarkLight,
            ),
          ),
          Text(
            'View All',
            style: GoogleFonts.splineSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomItem(Map<String, dynamic> room, String roomId) {
    final movie = room['movie'] as Map;
    final participants = room['participants'] as Map? ?? {};
    final isFull = participants.length >= 5;

    // Use a placeholder if movie image is missing
    final String movieImage = movie['posterUrl'] ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCcFLQ2I11LNEWRc_pf02UW1dy59RP_Be4SOzFo9oQK5nCpkZswSejFZWwTQn4Z_-dDcc3i_i3lsIHeoEldt9uF-c1esj_B6LuSh8i3iYZIYfqQuN_29F3J11pg3G5jGvCCzJN7k4RHYaUzqzI8rkHGERkJGa69zSpCxzRj2lE3JsNZvuIjwH1d3vVu84SOjALQA-syUhudl3-nAKK5lzti98WX5RTnjEgSFqQwZaB9-aTArIDm-7JoB4gbIJ0Z5J6esurQu3rdEyj7';

    // Get host name (first participant usually)
    final hostData = participants.values.firstOrNull as Map?;
    final hostName = hostData?['name'] ?? 'Host';
    final hostAvatar = hostData?['photoUrl'] ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCr2cR8nQUl3fwfQlXTzbW-YM1ImUgm8HkHmTl_G9zIWRaqE8igL4PZXAgtZzXffQ-lviNUPUaHOGK2tBVF98vWKhu6GU42Rhx9VAeb4kcX6n5xbBPEW9Th4s9w_KBdEdpPt1LBGQHaBq_iyy3gbwB4V0qQKHw4VhHDoXqjXDHwsn0gRpsROzxYgnRemGWnREiNGjevBxDZ6UGjTKrlYf7d4HkvdJHX_Gz39psVTB542_hliHkWLskp-fLNIl-qioGTOuV0d_B3-1j1';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: widget.isDark ? null : Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(movieImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -8,
                right: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isFull
                        ? const Color(0xFF2D2D2D)
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            widget.isDark ? AppColors.cardDark : Colors.white,
                        width: 2),
                  ),
                  child: Text(
                    isFull ? 'FULL' : 'LIVE',
                    style: GoogleFonts.splineSans(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isFull ? Colors.white : const Color(0xFF181811),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie['title'] ?? 'Room Session',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.splineSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDark ? Colors.white : AppColors.textDarkLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.black.withOpacity(0.2)
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group,
                          size: 10, color: Color(0xFF8C8B5F)),
                      const SizedBox(width: 4),
                      Text(
                        '${participants.length}/5 Friends',
                        style: GoogleFonts.splineSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8C8B5F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(hostAvatar),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '@$hostName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.splineSans(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isFull ? null : () => _handleJoin(roomId, room),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFull
                  ? (widget.isDark
                      ? const Color(0xFF3A3A3A)
                      : Colors.grey.shade200)
                  : AppColors.primaryLight,
              foregroundColor: isFull
                  ? (widget.isDark ? Colors.white : AppColors.textDarkLight)
                  : const Color(0xFF181811),
              elevation: isFull ? 0 : 2,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              isFull ? 'Full' : 'Join',
              style: GoogleFonts.splineSans(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRoomPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.screen_share,
                  color: AppColors.primaryLight, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              "Can't find what you're looking for?\nCreate your own room!",
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
