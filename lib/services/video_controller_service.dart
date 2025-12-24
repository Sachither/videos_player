import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';

class VideoControllerService {
  late final Player player;
  late final VideoController controller;

  File? _currentFile;
  List<FileSystemEntity> _playlist = [];
  int _currentIndex = -1;

  VideoControllerService() {
    player = Player();
    controller = VideoController(player);
  }

  Future<void> initialize(File file) async {
    _currentFile = file;
    await _loadPlaylist(file.parent.path);
    await player.open(Media(file.path));
  }

  Future<void> _loadPlaylist(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return;

    final files = dir.listSync();
    _playlist = files.where((entity) {
      if (entity is! File) return false;
      final ext = path.extension(entity.path).toLowerCase();
      // Add more video extensions as needed
      return ['.mp4', '.mkv', '.avi', '.mov', '.webm', '.flv'].contains(ext);
    }).toList();

    // Sort naturally (requires custom sort or just by name)
    _playlist
        .sort((a, b) => path.basename(a.path).compareTo(path.basename(b.path)));

    _currentIndex = _playlist.indexWhere((e) => e.path == _currentFile?.path);
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentIndex == -1) return;

    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _playlist.length)
      nextIndex = 0; // Loop or stop? Let's loop for now

    final nextFile = _playlist[nextIndex] as File;
    _currentIndex = nextIndex;
    _currentFile = nextFile;
    await player.open(Media(nextFile.path));
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentIndex == -1) return;

    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) prevIndex = _playlist.length - 1;

    final prevFile = _playlist[prevIndex] as File;
    _currentIndex = prevIndex;
    _currentFile = prevFile;
    await player.open(Media(prevFile.path));
  }

  File? get currentFile => _currentFile;

  // Track Management
  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    await player.setSubtitleTrack(track);
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    await player.setAudioTrack(track);
  }

  void dispose() {
    player.dispose();
  }
}
