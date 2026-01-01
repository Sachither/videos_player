import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../constants/app_colors.dart';
import '../../services/room_service.dart';

class RoomPlayerScreen extends StatefulWidget {
  final String roomTitle;
  final String movieId;
  final String roomId;
  final String videoUrl;

  const RoomPlayerScreen({
    super.key,
    required this.roomTitle,
    required this.movieId,
    required this.videoUrl,
    required this.roomId,
  });

  @override
  State<RoomPlayerScreen> createState() => _RoomPlayerScreenState();
}

class _RoomPlayerScreenState extends State<RoomPlayerScreen> {
  // Logic
  final RoomService _roomService = RoomService();
  StreamSubscription? _roomSubscription;
  bool _isHost = false;

  // Player
  late final Player player;
  late final VideoController controller;

  // UI State
  bool _showControls = true;
  bool _showChat = true; // Open chat by default as per design
  bool _isFullscreen = false;
  bool _isMuted = true;
  Timer? _hideTimer;
  Timer? _syncTimer;

  // Recording playback state for custom seek bar
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = true;
  late final StreamSubscription _positionSub;
  late final StreamSubscription _durationSub;
  late final StreamSubscription _playingSub;
  late final StreamSubscription _bufferingSub;

  @override
  void initState() {
    super.initState();
    _checkHost();
    _initPlayer();
    _startHideTimer();
  }

  void _checkHost() {
    // For MVP: Everyone has host controls to test the sync engine
    // TODO: In production, check user.uid against room's hostIds in Firebase
    _isHost = true;
  }

  Future<void> _initPlayer() async {
    print('🎬 Initializing Room Player for: ${widget.videoUrl}');
    player = Player();
    controller = VideoController(player);

    _positionSub = player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _playingSub = player.stream.playing.listen((playing) {
      print('▶️ Playback Status: $playing');
      if (mounted) setState(() => _isPlaying = playing);
    });
    _bufferingSub = player.stream.buffering.listen((buffering) {
      print('⏳ Buffering: $buffering');
      if (mounted) setState(() => _isBuffering = buffering);
    });

    try {
      // Ensure the URL is in a direct streamable format if it's from Google Drive
      final streamUrl = _getStreamableUrl(widget.videoUrl);
      print('📺 Opening stream: $streamUrl');

      await player.open(Media(streamUrl));

      // Start Sync Listeners
      _subscribeToRoom();

      if (_isHost) {
        _setupHostBroadcasting();
      }
    } catch (e) {
      print('❌ Error initializing player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load video: $e')),
        );
      }
    }
  }

  String _getStreamableUrl(String url) {
    if (url.contains('drive.google.com')) {
      // Convert /file/d/ID/view to /uc?export=download&id=ID
      final regExp = RegExp(r'\/file\/d\/([a-zA-Z0-9_-]+)\/');
      final match = regExp.firstMatch(url);
      if (match != null) {
        final id = match.group(1);
        return 'https://drive.google.com/uc?export=download&id=$id';
      }
    }
    return url;
  }

  void _subscribeToRoom() {
    _roomSubscription =
        _roomService.getRoomStream(widget.roomId).listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = event.snapshot.value as Map;
        final playback = data['playback'] as Map?;

        if (playback != null) {
          _handleSyncUpdate(playback);
        }
      }
    });
  }

  void _handleSyncUpdate(Map playback) {
    if (_isHost)
      return; // Host dictates state, doesn't listen to echo (except maybe for corrections)

    final bool serverPlaying = playback['isPlaying'] ?? false;
    final int serverPosition = playback['position'] ?? 0;
    final int serverUpdatedAt = playback['updatedAt'] ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;

    // Calculate actual server position (compensating for latency/time elapsed)
    int targetPosition = serverPosition;
    if (serverPlaying) {
      targetPosition += (now - serverUpdatedAt); // Add elapsed time
    }

    // Sync Play/Pause
    if (serverPlaying != player.state.playing) {
      if (serverPlaying) {
        player.play();
      } else {
        player.pause();
      }
    }

    // Sync Position (if drift > 2 seconds)
    final int currentPos = player.state.position.inMilliseconds;
    if ((currentPos - targetPosition).abs() > 2000) {
      player.seek(Duration(milliseconds: targetPosition));
    }
  }

  void _setupHostBroadcasting() {
    // Broadcast state changes
    player.stream.playing.listen((isPlaying) {
      _roomService.updatePlayback(
        roomId: widget.roomId,
        isPlaying: isPlaying,
        positionMs: player.state.position.inMilliseconds,
      );
    });

    // Broadcast periodic sync (to correct drift)
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (player.state.playing) {
        _roomService.updatePlayback(
          roomId: widget.roomId,
          isPlaying: true,
          positionMs: player.state.position.inMilliseconds,
        );
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    _roomSubscription?.cancel();
    _syncTimer?.cancel();
    _hideTimer?.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _playingSub.cancel();
    _bufferingSub.cancel();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleChat() {
    setState(() => _showChat = !_showChat);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _buildFullscreenPlayer();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSmallPlayer(),
                        _buildMovieDetails(),
                        _buildCustomSeekBar(),
                        _buildParticipantsList(),
                        _buildAdCard(),
                        const SizedBox(height: 120), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sliding Chat Overlay
          _buildChatOverlay(),

          // Bottom Floating Controls
          _buildBottomFloatingArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
          Column(
            children: [
              Text(
                'ROOM ${widget.roomId.substring(0, min(widget.roomId.length, 4)).toUpperCase()}',
                style: GoogleFonts.splineSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.roomTitle,
                style: GoogleFonts.splineSans(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPlayer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Video(controller: controller),
                    if (_isBuffering)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primaryLight,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading Theater...',
                              style: GoogleFonts.splineSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Play Overlay
          if (!_isPlaying)
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: () => player.play(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
          // Fullscreen Toggle
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => setState(() => _isFullscreen = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.fullscreen, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.roomTitle,
            style: GoogleFonts.splineSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Christopher Nolan • 2010', // Placeholder
            style: GoogleFonts.splineSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSeekBar() {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position),
                  style: GoogleFonts.notoSansMono(
                      fontSize: 12, color: Colors.white.withOpacity(0.6))),
              Text('-${_formatDuration(_duration - _position)}',
                  style: GoogleFonts.notoSansMono(
                      fontSize: 12, color: Colors.white.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final width = box.size.width - 48;
              final relativePos =
                  (details.localPosition.dx - 24).clamp(0.0, width);
              final newProgress = relativePos / width;
              player.seek(Duration(
                  milliseconds:
                      (newProgress * _duration.inMilliseconds).toInt()));
            },
            child: Container(
              height: 48,
              width: double.infinity,
              color: Colors.transparent, // Expand tap area
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  Positioned(
                    left: progress.clamp(0.0, 1.0) *
                        (MediaQuery.of(context).size.width - 48),
                    child: Transform.translate(
                      offset: const Offset(-8, 0),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x66F9F506),
                                  blurRadius: 10,
                                  spreadRadius: 2)
                            ]),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: AppColors.backgroundDark,
                                shape: BoxShape.circle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IN THE ROOM (3)',
                style: GoogleFonts.splineSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Invite +',
                  style: GoogleFonts.splineSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildParticipantAvatar(
                  'https://lh3.googleusercontent.com/a/ACg8ocL...', true),
              _buildParticipantAvatar(
                  'https://lh3.googleusercontent.com/a/ACg8ocL...', false),
              _buildParticipantAvatar(
                  'https://lh3.googleusercontent.com/a/ACg8ocL...', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantAvatar(String url, bool isMuted) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: AppColors.backgroundDark, width: 3),
              ),
              child: const Center(
                child: Icon(Icons.person, color: Colors.white70, size: 32),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 2),
              ),
              child: Icon(
                isMuted ? Icons.mic_off : Icons.mic,
                size: 10,
                color: AppColors.backgroundDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.movie_filter,
                      color: AppColors.primaryLight, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'COMING SOON',
                    style: GoogleFonts.splineSans(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Interstellar 2: The Void',
                style: GoogleFonts.splineSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Watch Trailer',
                        style: GoogleFonts.splineSans(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFloatingArea() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              AppColors.backgroundDark.withOpacity(0.9)
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isMuted = !_isMuted),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_isMuted ? Icons.mic_off : Icons.mic,
                        color: AppColors.backgroundDark, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      _isMuted ? 'Unmute' : 'Mute',
                      style: GoogleFonts.splineSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.backgroundDark,
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

  Widget _buildChatOverlay() {
    final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: const Cubic(0.32, 0.72, 0, 1),
      bottom: _showChat ? 0 : -screenHeight * 0.6,
      left: 0,
      right: 0,
      height: screenHeight * 0.6,
      child: _buildChatSheet(),
    );
  }

  Widget _buildFullscreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: Video(controller: controller)),
          Positioned(
            top: 48,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit,
                  color: Colors.white, size: 32),
              onPressed: () => setState(() => _isFullscreen = false),
            ),
          ),
          // Add simplified play/pause controls here if needed
        ],
      ),
    );
  }

  // ... Reuse Chat UI methods if possible, or implement simple version ...
  // For brevity in this replacement, I'll include the chat build method.
  Widget _buildChatSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          GestureDetector(
            onTap: _toggleChat,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              color: Colors.transparent,
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Room Chat',
                      style: GoogleFonts.splineSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '3 ONLINE',
                        style: GoogleFonts.splineSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _toggleChat,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // Chat Messages
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              reverse: true, // Show recent at bottom
              children: [
                _buildChatMessage('Marcus',
                    'Did you see that detail in the background? 🧐', false),
                _buildChatMessage('Elena',
                    'Yes!! The spinning top hasn\'t stopped yet...', false),
                _buildChatMessage('You',
                    'Wait for the end scene! It changes everything.', true),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withOpacity(0.5),
              border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        const Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.white30),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const Icon(Icons.sentiment_satisfied,
                            color: Colors.white24, size: 22),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x33F9F506),
                          blurRadius: 15,
                          spreadRadius: 2)
                    ],
                  ),
                  child: const Icon(Icons.send,
                      color: AppColors.backgroundDark, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(String sender, String text, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Text(
              sender,
              style: GoogleFonts.splineSans(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                  fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isMe ? AppColors.primaryLight : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.splineSans(
                color: isMe
                    ? AppColors.backgroundDark
                    : Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Just now',
            style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }
}
