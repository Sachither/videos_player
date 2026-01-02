import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../constants/app_colors.dart';
import '../../services/room_service.dart';
import 'invite_friends_screen.dart';
import 'room_summary_screen.dart';

class RoomPlayerScreen extends StatefulWidget {
  final String roomTitle;
  final String movieId;
  final String roomId;
  final String videoUrl;
  final bool isHost;

  const RoomPlayerScreen({
    super.key,
    required this.roomTitle,
    required this.movieId,
    required this.videoUrl,
    required this.roomId,
    required this.isHost,
  });

  @override
  State<RoomPlayerScreen> createState() => _RoomPlayerScreenState();
}

class _RoomPlayerScreenState extends State<RoomPlayerScreen> {
  // Logic
  final RoomService _roomService = RoomService();
  StreamSubscription? _roomSubscription;
  late bool _isHost;
  Map<String, dynamic> _roomSettings = {
    'closeOnExit': true,
    'autoTransferOwnership': false,
  };

  // Player
  late final Player player;
  VideoController? controller;

  // UI State
  bool _showControls = true;
  bool _showChat = false;
  bool _isFullscreen = false;
  bool _isMuted = true;
  Timer? _hideTimer;
  Timer? _syncTimer;
  Timer? _bufferReportTimer;
  StreamSubscription? _broadcastSub;

  // Group Buffering State
  Map<String, dynamic> _participants = {};
  bool _everyoneReady = false;
  bool _hasStartedPlayback =
      false; // Prevents re-showing overlay after initial start
  String? _posterUrl;

  // Chat
  final TextEditingController _messageController = TextEditingController();
  int _unreadCount = 0;
  StreamSubscription? _chatSubscription;
  final List<String> _identityIcons = [
    '🐱',
    '🦊',
    '🐻',
    '🦉',
    '🦛',
    '🦈',
    '🦬',
    '🦎',
    '🐒',
    '🐨',
    '🦌',
    '🦅',
    '🐸',
    '🦒',
    '🦭'
  ];

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
    _isHost = widget.isHost;
    _initPlayer();
    _subscribeToChatMessages();
    _startHideTimer();
  }

  Future<void> _initPlayer() async {
    print('🎬 Initializing Room Player with Aggressive Caching (150MB)');

    // Configure aggressive caching via MPV arguments
    player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 300 * 1024 * 1024, // 300MB
      ),
    );

    // Set secret MPV properties for high-bitrate streaming stability
    if (player.platform is NativePlayer) {
      final native = player.platform as NativePlayer;
      await native.setProperty('demuxer-max-bytes', '300000000'); // 300MB
      await native.setProperty(
          'demuxer-max-back-bytes', '50000000'); // 50MB back-buffer
      await native.setProperty('cache-secs', '300'); // 5 minutes readahead
    }

    final vController = VideoController(player);

    // Subscribe to streams first
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

    if (mounted) {
      setState(() {
        controller = vController;
      });
    }

    try {
      final streamUrl = _getStreamableUrl(widget.videoUrl);
      print('📺 Opening stream: $streamUrl');

      // OPEN BUT PAUSE immediately for group buffering
      // We explicitly set play: false to ensure it doesn't start until we raise the curtain
      await player.open(Media(streamUrl), play: false);

      _subscribeToRoom();

      if (_isHost) {
        _setupHostBroadcasting();
      }

      _startBufferReporting();
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
      if (event.snapshot.value == null && mounted) {
        _goToSummary();
        return;
      }

      if (event.snapshot.value != null && mounted) {
        final data = event.snapshot.value as Map;
        final playback = data['playback'] as Map?;
        final participants = data['participants'] as Map?;
        final settings = data['settings'] as Map?;
        final hostIds = data['hostIds'] as Map?;
        final movie = data['movie'] as Map?;

        if (movie != null && mounted) {
          setState(() {
            _posterUrl = movie['posterUrl'] as String?;
          });
        }

        if (participants != null) {
          _updateParticipantsState(participants);
        }

        if (playback != null) {
          _handleSyncUpdate(playback);
        }

        if (settings != null && mounted) {
          setState(() {
            _roomSettings = Map<String, dynamic>.from(settings);
          });
        }

        final user = _roomService.currentUser;
        if (hostIds != null && user != null && mounted) {
          bool nowHost = hostIds.containsKey(user.uid);
          if (nowHost != _isHost) {
            setState(() {
              _isHost = nowHost;
            });
            if (_isHost) {
              _setupHostBroadcasting();
            } else {
              _stopHostBroadcasting();
            }
          }
        }
      }
    });
  }

  void _updateParticipantsState(Map participants) {
    bool allReady = true;
    final Map<String, dynamic> newParticipants = {};

    participants.forEach((key, value) {
      final pData = Map<String, dynamic>.from(value as Map);
      newParticipants[key.toString()] = pData;

      final bufferSecs = pData['bufferSecs'] ?? 0;
      if (bufferSecs < 20) {
        // Reduced from 30s to 20s
        allReady = false;
      }
    });

    setState(() {
      _participants = newParticipants;
      _everyoneReady = allReady;
    });

    // Auto-play for host when everyone is ready
    if (_everyoneReady && !_hasStartedPlayback) {
      print('🎬 Threshold met for all participants!');
      setState(() => _hasStartedPlayback = true);

      if (_isHost) {
        print('👑 Host raising the curtain.');
        player.play();
      }
    }
  }

  void _startBufferReporting() {
    _bufferReportTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Calculate how many seconds we have buffered ahead of the current position
      final bufferMs = player.state.buffer.inMilliseconds;
      final posMs = player.state.position.inMilliseconds;
      final bufferAheadSecs = max(0, (bufferMs - posMs) ~/ 1000);

      _roomService.updateUserBuffer(
        roomId: widget.roomId,
        userId: _roomService.currentUser?.uid ?? 'unknown',
        bufferSecs: bufferAheadSecs,
      );
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
        // 🪄 If server is playing, we MUST transition out of "Buckling Up"
        if (!_hasStartedPlayback) {
          setState(() => _hasStartedPlayback = true);
        }
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
    _stopHostBroadcasting(); // Prevent duplicates

    // Broadcast state changes
    _broadcastSub = player.stream.playing.listen((isPlaying) {
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

  void _stopHostBroadcasting() {
    _broadcastSub?.cancel();
    _broadcastSub = null;
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  void dispose() {
    player.dispose();
    _roomSubscription?.cancel();
    _chatSubscription?.cancel();
    _stopHostBroadcasting();
    _hideTimer?.cancel();
    _bufferReportTimer?.cancel();
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
    setState(() {
      _showChat = !_showChat;
      if (_showChat) {
        _unreadCount = 0; // Reset unread count when opening chat
      }
    });
  }

  void _subscribeToChatMessages() {
    _chatSubscription =
        _roomService.getChatStream(widget.roomId).listen((event) {
      if (event.snapshot.value != null && mounted) {
        // Increment unread count if chat is closed
        if (!_showChat) {
          setState(() => _unreadCount++);
        }
      }
    });
  }

  void _showRoomSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF1C1C16) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF181811);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.settings, color: AppColors.primaryLight),
                    const SizedBox(width: 12),
                    Text(
                      'Room Settings',
                      style: GoogleFonts.splineSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingToggle(
                  title: 'Close room on exit',
                  subtitle: 'Disconnect everyone when you leave',
                  value: _roomSettings['closeOnExit'] ?? true,
                  onChanged: (val) {
                    if (_isHost) {
                      setModalState(() {
                        _roomSettings['closeOnExit'] = val;
                        if (val) _roomSettings['autoTransferOwnership'] = false;
                      });
                      _roomService.updateRoomSettings(
                          widget.roomId, _roomSettings.cast<String, dynamic>());
                    }
                  },
                  enabled: _isHost,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),
                _buildSettingToggle(
                  title: 'Transfer leadership',
                  subtitle: 'Pick a new host automatically on exit',
                  value: _roomSettings['autoTransferOwnership'] ?? false,
                  onChanged: (val) {
                    if (_isHost) {
                      setModalState(() {
                        _roomSettings['autoTransferOwnership'] = val;
                        if (val) _roomSettings['closeOnExit'] = false;
                      });
                      _roomService.updateRoomSettings(
                          widget.roomId, _roomSettings.cast<String, dynamic>());
                    }
                  },
                  enabled: _isHost,
                  textColor: textColor,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool enabled,
    required Color textColor,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.splineSans(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.splineSans(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }

  Future<bool> _handleExit() async {
    bool? shouldExit;

    if (_isHost) {
      bool closeOnExit = _roomSettings['closeOnExit'] ?? true;
      String title = closeOnExit ? 'End Room?' : 'Leave Room?';
      String content = closeOnExit
          ? 'Ending the room will disconnect everyone. Are you sure?'
          : 'The room will stay active for others. Transfer ownership if you want someone else to control it.';

      shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title,
              style: GoogleFonts.splineSans(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(content,
              style: GoogleFonts.splineSans(
                  color: Colors.grey.shade400, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Stay',
                  style: GoogleFonts.splineSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(closeOnExit ? 'End Room' : 'Leave'),
            ),
          ],
        ),
      );
    } else {
      shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Leave Room?',
              style: GoogleFonts.splineSans(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to leave this watch party?',
              style: GoogleFonts.splineSans(
                  color: Colors.grey.shade400, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Stay',
                  style: GoogleFonts.splineSans(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
    }

    if (shouldExit == true) {
      bool closing = _isHost && (_roomSettings['closeOnExit'] ?? true);
      await _roomService.leaveRoom(widget.roomId);
      if (mounted) {
        if (closing) {
          _goToSummary();
        } else {
          Navigator.pop(context);
        }
      }
    }

    return shouldExit ?? false;
  }

  void _goToSummary() {
    if (!mounted) return;

    final participantNames = _participants.values
        .map((p) => (p['name'] as String?) ?? 'Anonymous')
        .toList();

    final duration = _position.inSeconds > player.state.position.inSeconds
        ? _position
        : player.state.position;

    String durationStr;
    if (duration.inSeconds < 60) {
      durationStr = '${duration.inSeconds}s watched';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      durationStr = hours > 0
          ? '${hours}hr ${minutes}min watched'
          : '${minutes}min watched';
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RoomSummaryScreen(
          movieTitle: widget.roomTitle,
          moviePoster: _posterUrl ??
              'https://lh3.googleusercontent.com/aida-public/AB6AXuANMhURGD2Au7cytwks6rLCs6WoRzbwd998rgdJjGBjslsIyS7N5HrqAmm3l_DUOMIbC26Iz-lJ2R6Qhan2N_VvekJEGsDuAec5rXmlb0TtckBJ9Cml-oYN2l3Dq1EPARw0sUu4xrJfFw3NDqHmb2a_p7jzZq9IEXBihsx-VaMbW6dJR4s-xUg78gFuEqPgB8Jz1lJUiBXwImPYyOODRykfUXEq5xgv-uD5lkZpJ3vz0cLiTq0dvIgWc_mRTOHDBtrdmeXs1f-CTJe0',
          durationWatched: durationStr,
          participants: participantNames,
          onReturnHome: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _buildFullscreenPlayer();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
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
            if (!_showChat) _buildBottomFloatingArea(),
          ],
        ),
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
            onTap: _handleExit,
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
          Expanded(
            child: Column(
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
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.splineSans(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showRoomSettings,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.more_horiz, color: Colors.white, size: 24),
            ),
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
                    if (controller != null)
                      Video(controller: controller!)
                    else
                      Container(
                          color: Colors.black,
                          child:
                              const Center(child: CircularProgressIndicator())),

                    if (!_hasStartedPlayback)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.primaryLight,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _everyoneReady
                                    ? 'Buffering...'
                                    : 'Buckling Up...',
                                style: GoogleFonts.splineSans(
                                  color: AppColors.primaryLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Participant Buffer Status
                              ..._participants.entries.map((e) {
                                final p = e.value as Map;
                                final buffer = p['bufferSecs'] ?? 0;
                                final isReady = buffer >= 30;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isReady
                                            ? Icons.check_circle
                                            : Icons.hourglass_top,
                                        color: isReady
                                            ? Colors.green
                                            : Colors.white30,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${p['name']}: ${buffer}s / 20s',
                                        style: GoogleFonts.splineSans(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              if (_isHost && !_everyoneReady) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _everyoneReady = true;
                                      _hasStartedPlayback = true;
                                    });
                                    player.play();
                                  },
                                  icon: const Icon(Icons.curtains),
                                  label: const Text('Force Start'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryLight,
                                    foregroundColor: AppColors.backgroundDark,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    textStyle: GoogleFonts.splineSans(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    // Small buffering spinner when playback is in progress
                    if (_hasStartedPlayback && _isBuffering)
                      const Positioned(
                        top: 16,
                        left: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primaryLight),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Play Overlay (Host Only for active control)
          if (!_isPlaying && _isHost)
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
          // Non-Host Message if paused
          if (!_isPlaying && !_isHost && _hasStartedPlayback)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Host has paused',
                    style: GoogleFonts.splineSans(
                        color: Colors.white, fontSize: 12),
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
            onHorizontalDragUpdate: _isHost
                ? (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final width = box.size.width - 48;
                    final relativePos =
                        (details.localPosition.dx - 24).clamp(0.0, width);
                    final newProgress = relativePos / width;
                    player.seek(Duration(
                        milliseconds:
                            (newProgress * _duration.inMilliseconds).toInt()));
                  }
                : null,
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
    final participantList = _participants.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IN THE ROOM (${participantList.length})',
                style: GoogleFonts.splineSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InviteFriendsScreen(
                        roomId: widget.roomId,
                        roomTitle: widget.roomTitle,
                      ),
                    ),
                  );
                },
                child: Container(
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
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: participantList.map((entry) {
              final participantData = entry.value as Map;
              final name = participantData['name'] ?? 'User';
              final iconIndex = participantData['iconIndex'] ?? 0;
              final isMuted =
                  true; // Could track this in participant data if needed
              return _buildParticipantAvatar(name, iconIndex, isMuted);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantAvatar(String name, int iconIndex, bool isMuted) {
    final emoji = _identityIcons[iconIndex % _identityIcons.length];
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              if (isMuted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E63),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_off,
                        color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.splineSans(
                fontSize: 10,
                color: Colors.white70,
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
            // Mute/Mic Toggle
            GestureDetector(
              onTap: () => setState(() => _isMuted = !_isMuted),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        color: AppColors.backgroundDark, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      _isMuted ? 'Muted' : 'Live',
                      style: GoogleFonts.splineSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.backgroundDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Chat Toggle Button
            GestureDetector(
              onTap: _toggleChat,
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: AppColors.backgroundDark, size: 28),
                      if (_unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E63),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              _unreadCount > 9 ? '9+' : '$_unreadCount',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.splineSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
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
          if (controller != null)
            Center(child: Video(controller: controller!))
          else
            const Center(child: CircularProgressIndicator()),

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
                        '${_participants.length} ONLINE',
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
            child: StreamBuilder<DatabaseEvent>(
              stream: _roomService.getChatStream(widget.roomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hi! 👋',
                      style:
                          const TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  );
                }

                final Map messagesMap = snapshot.data!.snapshot.value as Map;
                final messages = messagesMap.entries.toList()
                  ..sort((a, b) => (b.value['timestamp'] ?? 0)
                      .compareTo(a.value['timestamp'] ?? 0));

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].value as Map;
                    final isMe =
                        msg['senderId'] == _roomService.currentUser?.uid;
                    return _buildChatMessage(
                      msg['senderName'] ?? 'Anon',
                      msg['text'] ?? '',
                      isMe,
                      msg['iconIndex'] ?? 0,
                      msg['timestamp'] != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                              msg['timestamp'])
                          : DateTime.now(),
                    );
                  },
                );
              },
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
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                  color: Colors.white24, fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                _roomService.sendMessage(widget.roomId, val);
                                _messageController.clear();
                              }
                            },
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
                GestureDetector(
                  onTap: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _roomService.sendMessage(
                          widget.roomId, _messageController.text.trim());
                      _messageController.clear();
                    }
                  },
                  child: Container(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(String sender, String text, bool isMe, int iconIndex,
      DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _identityIcons[iconIndex % _identityIcons.length],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primaryLight
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          isMe ? const Radius.circular(20) : Radius.zero,
                      bottomRight:
                          isMe ? Radius.zero : const Radius.circular(20),
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
                  _formatTime(timestamp),
                  style: TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _identityIcons[iconIndex % _identityIcons.length],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
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
