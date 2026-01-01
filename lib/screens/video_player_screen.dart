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
import 'package:file_picker/file_picker.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoControllerService _videoService;

  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isLocked = false;
  bool _isOrientationLocked = false;
  BoxFit _videoFit = BoxFit.contain;

  // Volume & Brightness
  double _volume = 0.5;
  double _brightness = 0.5;
  bool _isDragging = false;
  String? _dragLabel; // "Volume" or "Brightness"
  double? _dragValue; // current value being changed

  // Resume state
  bool _showResumeToast = false;
  Duration? _resumedPosition;

  Timer? _saveTimer;

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
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _videoService = VideoControllerService();

    // Sync initial state if available
    _position = _videoService.player.state.position;
    _duration = _videoService.player.state.duration;

    _initPlayer();
    _initSettings();
    _startSaveTimer();
  }

  void _startSaveTimer() {
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveCurrentPosition();
    });
  }

  void _saveCurrentPosition() {
    if (_videoService.currentFile != null) {
      final pos = _videoService.player.state.position;
      if (pos.inSeconds > 0) {
        _videoService.savePosition(_videoService.currentFile!.path, pos);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveCurrentPosition();
    }
  }

  Future<void> _initPlayer() async {
    // 1. Subscribe to streams FIRST to catch all events
    _positionSub = _videoService.player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _durationSub = _videoService.player.stream.duration.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
        // Handle trigger for resume once duration is known
        if (dur.inSeconds > 0 && _resumedPosition != null) {
          _performResumeSeek();
        }
      }
    });
    _playingSub = _videoService.player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
      if (playing) _startHideControlsTimer();
    });
    _bufferingSub = _videoService.player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });

    // 2. Load resume position from local storage
    final savedPos =
        await _videoService.getSavedPosition(widget.videoFile.path);
    if (savedPos != null && savedPos.inSeconds > 2) {
      _resumedPosition = savedPos;
      if (mounted) {
        setState(() => _showResumeToast = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showResumeToast = false);
        });
      }
    }

    // 3. Initialize player (this triggers open)
    await _videoService.initialize(widget.videoFile);

    if (mounted) {
      setState(() {
        _position = _videoService.player.state.position;
        _duration = _videoService.player.state.duration;
      });
    }

    // 4. Fallback: if duration is already set or doesn't update,
    // attempt seek after a delay anyway.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _resumedPosition != null) {
        _performResumeSeek(force: true);
      }
      if (mounted) _videoService.player.play();
    });
  }

  bool _hasResumedAlready = false;
  void _performResumeSeek({bool force = false}) {
    if (_hasResumedAlready && !force) return;
    if (_resumedPosition == null) return;

    _hasResumedAlready = true;
    _videoService.player.seek(_resumedPosition!);
    debugPrint(
        'Performing resume seek to ${_resumedPosition!.inSeconds}s (force: $force)');
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
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _saveTimer?.cancel();
    _saveCurrentPosition();

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
  Future<void> _loadExternalSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      // Actually media_kit uses specific track for external subs:
      await _videoService.player.setSubtitleTrack(SubtitleTrack.uri(path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subtitle loaded')),
        );
      }
    }
  }

  void _showSubtitleDialog() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          final tracks = _videoService.player.state.tracks.subtitle;
          final current = _videoService.player.state.track.subtitle;
          return Container(
            color: Colors.grey[900],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_open, color: Colors.white),
                  title: const Text('Load from Device',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _loadExternalSubtitle();
                  },
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return ListTile(
                          title: Text(
                              track.title ?? track.language ?? 'Track $index',
                              style: const TextStyle(color: Colors.white)),
                          leading: track == current
                              ? const Icon(Icons.check, color: Colors.orange)
                              : null,
                          onTap: () {
                            _videoService.setSubtitleTrack(track);
                            Navigator.pop(context);
                          },
                        );
                      }),
                ),
              ],
            ),
          );
        });
  }

  // --- Aspect Ratio ---
  void _toggleAspectRatio() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.grey[900],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFitOption('Fit', BoxFit.contain),
            _buildFitOption('Fill', BoxFit.cover),
            _buildFitOption('Stretch', BoxFit.fill),
          ],
        ),
      ),
    );
  }

  Widget _buildFitOption(String label, BoxFit fit) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      leading: _videoFit == fit
          ? const Icon(Icons.check, color: Colors.orange)
          : null,
      onTap: () {
        setState(() => _videoFit = fit);
        Navigator.pop(context);
      },
    );
  }

  // --- Orientation Lock ---
  void _toggleOrientationLock() {
    setState(() {
      _isOrientationLocked = !_isOrientationLocked;
    });

    if (_isOrientationLocked) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  // --- More Options ---
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.speed, color: Colors.white),
                  title: const Text('Playback Speed',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSpeedDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.white),
                  title: const Text('Video Information',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showInfoDialog();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.bookmark_border, color: Colors.white),
                  title: const Text('Bookmark',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Save bookmark
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.picture_in_picture, color: Colors.white),
                  title: const Text('Pop-up Player',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: PiP logic
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.white),
                  title: const Text('Lock Controls',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _isLocked = true);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 1.0, 1.25, 1.5, 2.0]
              .map((s) => ListTile(
                    title: Text('${s}x'),
                    leading: _videoService.player.state.rate == s
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      _videoService.player.setRate(s);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${widget.title}'),
            Text('Duration: ${_formatDuration(_duration)}'),
            Text('Format: ${path.extension(widget.videoFile.path)}'),
            Text('Path: ${widget.videoFile.path}'),
          ],
        ),
      ),
    );
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
              child: Video(
                controller: _videoService.controller,
                fit: _videoFit,
              ),
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

          // 4. Resume Toast
          if (_showResumeToast && _resumedPosition != null)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Resumed from ${_formatDuration(_resumedPosition!)}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Controls Layer
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
                      height: 120,
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
                                if (_videoService.currentFile != null) {
                                  _videoService.savePosition(
                                      _videoService.currentFile!.path,
                                      _videoService.player.state.position);
                                }
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
                                            .clamp(
                                                0.0,
                                                _duration.inSeconds > 0
                                                    ? _duration.inSeconds
                                                        .toDouble()
                                                    : 1.0),
                                        min: 0,
                                        max: _duration.inSeconds > 0
                                            ? _duration.inSeconds.toDouble()
                                            : 1.0,
                                        onChanged: (val) {
                                          if (_duration.inSeconds > 0) {
                                            _videoService.player.seek(
                                                Duration(seconds: val.toInt()));
                                          }
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
                                        icon: Icon(
                                            _isOrientationLocked
                                                ? Icons.screen_lock_landscape
                                                : Icons.screen_rotation,
                                            color: Colors.white),
                                        onPressed: _toggleOrientationLock,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.aspect_ratio,
                                            color: Colors.white),
                                        onPressed: _toggleAspectRatio,
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
                                        onPressed: _showMoreOptions,
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
