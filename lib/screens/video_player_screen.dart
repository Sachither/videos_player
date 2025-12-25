import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import '../services/video_controller_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoFile,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoControllerService _videoService;

  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isLocked = false;

  // Volume & Brightness
  double _volume = 0.5;
  double _brightness = 0.5;
  bool _isDragging = false;
  String? _dragLabel; // "Volume" or "Brightness"
  double? _dragValue; // current value being changed

  // State for UI updates
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;

  late final StreamSubscription _positionSub;
  late final StreamSubscription _durationSub;
  late final StreamSubscription _playingSub;
  late final StreamSubscription _bufferingSub;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _videoService = VideoControllerService();
    _initPlayer();
    _initSettings();
  }

  Future<void> _initPlayer() async {
    await _videoService.initialize(widget.videoFile);

    // Subscribe to streams
    _positionSub = _videoService.player.stream.position.listen((pos) {
      setState(() => _position = pos);
    });
    _durationSub = _videoService.player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _playingSub = _videoService.player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
      if (playing) _startHideControlsTimer();
    });
    _bufferingSub = _videoService.player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });

    if (mounted) setState(() {});

    // Auto play
    _videoService.player.play();
  }

  Future<void> _initSettings() async {
    try {
      _volume = await FlutterVolumeController.getVolume() ?? 0.5;
      _brightness = await ScreenBrightness().current;
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _videoService.dispose();
    _hideControlsTimer?.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _playingSub.cancel();
    _bufferingSub.cancel();
    super.dispose();
  }

  void _toggleControls() {
    if (_isLocked) {
      setState(() => _showControls = !_showControls);
      if (_showControls) _startHideControlsTimer();
      return;
    }

    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_isDragging && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  // --- Next / Prev ---
  Future<void> _playNext() async {
    await _videoService.playNext();
    setState(() {});
  }

  Future<void> _playPrev() async {
    await _videoService.playPrevious();
    setState(() {});
  }

  // --- Subtitles ---
  void _showSubtitleDialog() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          final tracks = _videoService.player.state.tracks.subtitle;
          final current = _videoService.player.state.track.subtitle;
          return Container(
            color: Colors.grey[900],
            child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return ListTile(
                    title: Text(
                        track.title ?? track.language ?? 'Track $index',
                        style: TextStyle(color: Colors.white)),
                    leading: track == current
                        ? Icon(Icons.check, color: Colors.orange)
                        : null,
                    onTap: () {
                      _videoService.setSubtitleTrack(track);
                      Navigator.pop(context);
                    },
                  );
                }),
          );
        });
  }

  // --- Gestures ---

  void _onVerticalDragUpdate(DragUpdateDetails details, bool isRightSide) {
    if (_isLocked) return;

    setState(() {
      _isDragging = true;
      _showControls = false;
    });

    final double delta = details.primaryDelta! / -300;

    if (isRightSide) {
      // Volume
      double newVol = (_volume + delta).clamp(0.0, 1.0);
      setState(() {
        _volume = newVol;
        _dragLabel = "Volume";
        _dragValue = _volume;
      });
      FlutterVolumeController.setVolume(_volume);
    } else {
      // Brightness
      double newBright = (_brightness + delta).clamp(0.0, 1.0);
      setState(() {
        _brightness = newBright;
        _dragLabel = "Brightness";
        _dragValue = _brightness;
      });
      ScreenBrightness().setScreenBrightness(_brightness);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isLocked) return;
    setState(() {
      _isDragging = false;
      _dragLabel = null;
      _dragValue = null;
    });
  }

  // --- Formatting ---
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // Title logic
    final currentTitle = _videoService.currentFile != null
        ? path.basename(_videoService.currentFile!.path)
        : widget.title;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Layer with Zoom
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Video(controller: _videoService.controller),
            ),
          ),

          if (_isBuffering)
            const Center(
                child: CircularProgressIndicator(color: Colors.orange)),

          // 2. Gesture Layer (Split Screen)
          Row(
            children: [
              // Left side - Brightness
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, false),
                  onVerticalDragEnd: _onDragEnd,
                  onDoubleTap: () {
                    // Rewind 10s
                    if (!_isLocked) {
                      final pos = _position;
                      _videoService.player
                          .seek(pos - const Duration(seconds: 10));
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Right side - Volume
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, true),
                  onVerticalDragEnd: _onDragEnd,
                  onDoubleTap: () {
                    // Forward 10s
                    if (!_isLocked) {
                      final pos = _position;
                      _videoService.player
                          .seek(pos + const Duration(seconds: 10));
                    }
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),

          // 3. Gesture Indicators (Volume/Brightness Overlay)
          if (_isDragging && _dragLabel != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _dragLabel == "Brightness"
                          ? Icons.brightness_6
                          : Icons.volume_up,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      width: 8,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(color: Colors.grey[600]),
                          Container(
                            height: 100 * (_dragValue ?? 0),
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

          // 4. Controls Layer
          if (_showControls && !_isDragging)
            IgnorePointer(
              ignoring: _isLocked,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isLocked ? 0.0 : 1.0,
                child: Stack(
                  children: [
                    // Top Bar
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Back
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                              // Title
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        currentTitle,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
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
                              // Start Room Button (Responsive)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // Start Room Action
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isLandscape ? 12 : 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.screen_share,
                                            size: 20, color: Colors.white),
                                        if (isLandscape) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            "Start Room",
                                            style: GoogleFonts.splineSans(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Center Play/Pause (Big)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 48,
                            icon: const Icon(Icons.skip_previous,
                                color: Colors.white),
                            onPressed: _playPrev,
                          ),
                          const SizedBox(width: 32),
                          GestureDetector(
                            onTap: () {
                              if (_isPlaying) {
                                _videoService.player.pause();
                              } else {
                                _videoService.player.play();
                              }
                            },
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            iconSize: 48,
                            icon: const Icon(Icons.skip_next,
                                color: Colors.white),
                            onPressed: _playNext,
                          ),
                        ],
                      ),
                    ),

                    // Bottom Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.only(
                            top: 40, bottom: 20, left: 16, right: 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Progress Bar with Time
                              Row(
                                children: [
                                  Text(
                                    _formatDuration(_position),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        activeTrackColor: Colors.orange,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.white,
                                        trackHeight: 2,
                                        thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 6),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                                overlayRadius: 12),
                                      ),
                                      child: Slider(
                                        value: _position.inSeconds
                                            .toDouble()
                                            .clamp(0.0,
                                                _duration.inSeconds.toDouble()),
                                        min: 0,
                                        max: _duration.inSeconds.toDouble(),
                                        onChanged: (val) {
                                          _videoService.player.seek(
                                              Duration(seconds: val.toInt()));
                                        },
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_duration),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Bottom controls row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left actions
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.lock_open,
                                            color: Colors.white),
                                        onPressed: () {
                                          setState(() => _isLocked = true);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.aspect_ratio,
                                            color: Colors.white),
                                        onPressed: () {
                                          // Toggle fit
                                        },
                                      ),
                                    ],
                                  ),
                                  // Right actions
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.subtitles,
                                            color: Colors.white),
                                        onPressed: _showSubtitleDialog,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.more_horiz,
                                            color: Colors.white),
                                        onPressed: () {},
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Lock Button Overlay (Visible even when locked)
          if (_isLocked && _showControls)
            Positioned(
              left: 20,
              bottom: 40,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: const Icon(Icons.lock, color: Colors.white),
                    onPressed: () {
                      setState(() => _isLocked = false);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
