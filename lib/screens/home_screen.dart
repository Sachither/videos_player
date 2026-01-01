import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import 'video_player_screen.dart';
import 'room_view.dart';
import 'package:wecinema/models/video_model.dart';
import 'package:wecinema/screens/room/room_setup_sheet.dart';
import 'package:wecinema/widgets/video_thumbnail_widget.dart';

import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Set<String> _selectedVideos = {};
  List<Video> videos = [];
  bool _isLoading = true;
  bool _isScanning = false;
  DateTime? _lastBackPressTime;
  String _sortOption = 'date'; // 'date', 'name'

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    if (mounted) setState(() => _isScanning = true);
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScanning = false;
        });
      }
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );

    if (paths.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isScanning = false;
        });
      }
      return;
    }

    final AssetPathEntity path = paths[0];
    final int assetCount = await path.assetCountAsync;

    final List<AssetEntity> assets = await path.getAssetListRange(
      start: 0,
      end: assetCount,
    );

    final List<Video> loadedVideos = assets.map((asset) {
      return Video(
        asset: asset,
        title: asset.title ?? 'Unknown Video',
        duration: _formatDuration(asset.videoDuration),
        dateAdded: _formatDate(asset.createDateTime),
      );
    }).toList();

    if (mounted) {
      setState(() {
        videos = loadedVideos;
        _isLoading = false;
        _isScanning = false;
        _sortVideos();
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Added Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  void _handleMenuOption(String value) {
    switch (value) {
      case 'sort':
        _showSortDialog();
        break;
      case 'play_last':
        _playLastPlayed();
        break;
      case 'delete':
        if (_selectedVideos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Long press a video to select for deletion')),
          );
        } else {
          _confirmDelete();
        }
        break;
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Name'),
              onTap: () {
                setState(() => _sortOption = 'name');
                _sortVideos();
                Navigator.pop(context);
              },
              leading: Radio<String>(
                value: 'name',
                groupValue: _sortOption,
                onChanged: (val) {
                  setState(() => _sortOption = val!);
                  _sortVideos();
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Date'),
              onTap: () {
                setState(() => _sortOption = 'date');
                _sortVideos();
                Navigator.pop(context);
              },
              leading: Radio<String>(
                value: 'date',
                groupValue: _sortOption,
                onChanged: (val) {
                  setState(() => _sortOption = val!);
                  _sortVideos();
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sortVideos() {
    setState(() {
      if (_sortOption == 'name') {
        videos.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      } else if (_sortOption == 'date') {
        videos.sort(
            (a, b) => b.asset.createDateTime.compareTo(a.asset.createDateTime));
      }
    });
  }

  Future<void> _playLastPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('last_played_path');
    final title = prefs.getString('last_played_title');

    if (path != null && File(path).existsSync()) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoFile: File(path),
              title: title ?? 'Last Played',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No last played video found')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Videos?'),
        content: Text(
            'Are you sure you want to delete ${_selectedVideos.length} selected videos?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final List<String> idsToDelete = [];
      for (var video in videos) {
        if (_selectedVideos.contains(video.title)) {
          idsToDelete.add(video.asset.id);
        }
      }

      try {
        final result = await PhotoManager.editor.deleteWithIds(idsToDelete);
        if (result.isNotEmpty) {
          setState(() {
            videos.removeWhere((v) => idsToDelete.contains(v.asset.id));
            _selectedVideos.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting videos: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press back again to exit',
                  style: GoogleFonts.splineSans()),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildWatchView(isDark),
            RoomView(isDark: isDark),
            SettingsView(isDark: isDark),
          ],
        ),
        bottomNavigationBar: _buildCustomBottomNav(isDark),
        floatingActionButton: _selectedIndex < 2
            ? FloatingActionButton.extended(
                onPressed: () async {
                  _showRoomSetupSheet();
                },
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.black,
                elevation: 4,
                icon: const Icon(Icons.screen_share),
                label: Text(
                  'Start Room',
                  style: GoogleFonts.splineSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildWatchView(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryLight,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'W',
                      style: GoogleFonts.splineSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Text(
                  'WeCinema',
                  style: GoogleFonts.splineSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textLightDark
                        : AppColors.textDarkLight,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedIndex = 2), // Go to Settings
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark ? Colors.white24 : Colors.white,
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1), blurRadius: 8)
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAeJeLnCik4E2FXj47H757NcWME13AzzgjTorqRIDdslkz0qk23dAJESd2hUGK2JRxtOb9OffOJbV8rDeUWZpIYv8amN_yVhXRyXJdmVKre2NiaovwQ1DGEoyl-N5wTsuCC52UHWgt-dt9AbPFxKF4tvMjF1-iSGF9VLeZCZ0vnzn8KqEHeIl_xCBrjHvfluVaJLBeOX2eEIhKqqXbVn9sjblwg4Fxx1UDqcRNC913Gt7vwp6-HdePjKJdex7kSz7nO_axAveHsoIPf',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[400],
                            child: const Icon(Icons.person)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Library Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Library (${videos.length})',
                  style: GoogleFonts.splineSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textLightDark
                        : AppColors.textDarkLight,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: isDark
                            ? AppColors.textGreyDark
                            : AppColors.textGreyLight,
                      ),
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: VideoSearchDelegate(
                            videos: videos,
                            isDark: isDark,
                          ),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark
                            ? AppColors.textGreyDark
                            : AppColors.textGreyLight,
                      ),
                      onSelected: (value) {
                        _handleMenuOption(value);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'sort',
                          child: Text('Sort movies'),
                        ),
                        const PopupMenuItem(
                          value: 'play_last',
                          child: Text('Play last played movie'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(_selectedVideos.isEmpty
                              ? 'Delete'
                              : 'Delete selected'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Videos Grid
          Expanded(
            child: Column(
              children: [
                if (_isScanning)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primaryLight.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryLight),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Scanning library for new movies...',
                                style: GoogleFonts.splineSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textLightDark
                                      : AppColors.textDarkLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryLight),
                              minHeight: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchVideos,
                    color: AppColors.primaryLight,
                    backgroundColor:
                        isDark ? AppColors.backgroundDark : Colors.white,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : videos.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.4,
                                    child: Center(
                                      child: Text(
                                        "No videos found",
                                        style: GoogleFonts.splineSans(
                                          color: isDark
                                              ? AppColors.textGreyDark
                                              : AppColors.textGreyLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 16 / 15,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 24,
                                ),
                                itemCount: videos.length,
                                itemBuilder: (context, index) {
                                  final video = videos[index];
                                  final isSelected =
                                      _selectedVideos.contains(video.title);

                                  return GestureDetector(
                                    onTap: () async {
                                      if (_selectedVideos.isNotEmpty) {
                                        setState(() {
                                          if (_selectedVideos
                                              .contains(video.title)) {
                                            _selectedVideos.remove(video.title);
                                          } else {
                                            _selectedVideos.add(video.title);
                                          }
                                        });
                                        return;
                                      }
                                      final file = await video.asset.file;
                                      if (file != null && context.mounted) {
                                        // Save as last played
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        await prefs.setString(
                                            'last_played_path', file.path);
                                        await prefs.setString(
                                            'last_played_title', video.title);

                                        if (context.mounted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VideoPlayerScreen(
                                                videoFile: file,
                                                title: video.title,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    onLongPress: () {
                                      setState(() {
                                        if (_selectedVideos
                                            .contains(video.title)) {
                                          _selectedVideos.remove(video.title);
                                        } else {
                                          _selectedVideos.add(video.title);
                                        }
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Video Thumbnail
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      VideoThumbnailWidget(
                                                        asset: video.asset,
                                                        isDark: isDark,
                                                      ),
                                                      // Border if selected
                                                      if (isSelected)
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16),
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .primaryLight,
                                                              width: 2,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Duration badge
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    video.duration,
                                                    style:
                                                        GoogleFonts.splineSans(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Check icon if selected
                                              if (isSelected)
                                                Positioned(
                                                  top: -4,
                                                  right: -4,
                                                  child: Container(
                                                    width: 20,
                                                    height: 20,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: AppColors
                                                          .primaryLight,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.2),
                                                          blurRadius: 4,
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.check,
                                                        color: Colors.black,
                                                        size: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Video Info
                                        Text(
                                          video.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.splineSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? AppColors.primaryLight
                                                : (isDark
                                                    ? AppColors.textLightDark
                                                    : AppColors.textDarkLight),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FutureBuilder<File?>(
                                            future: video.asset.file,
                                            builder: (context, snapshot) {
                                              String details = video.dateAdded;
                                              if (snapshot.hasData &&
                                                  snapshot.data != null) {
                                                final sizeBytes =
                                                    snapshot.data!.lengthSync();
                                                final sizeMB =
                                                    (sizeBytes / (1024 * 1024))
                                                        .toStringAsFixed(1);
                                                final sizeStr = (double.parse(
                                                            sizeMB) >
                                                        1000)
                                                    ? '${(double.parse(sizeMB) / 1024).toStringAsFixed(1)} GB'
                                                    : '$sizeMB MB';
                                                details = '$sizeStr • $details';
                                              }
                                              return Text(
                                                details,
                                                style: GoogleFonts.splineSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? AppColors.textGreyDark
                                                      : AppColors.textGreyLight,
                                                ),
                                              );
                                            }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav(bool isDark) {
    return Container(
      height: 84 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom, top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23220F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.smart_display, 'Watch', isDark),
          _buildNavItem(1, Icons.meeting_room, 'Room', isDark),
          _buildNavItem(2, Icons.settings, 'Settings', isDark),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryLight.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.primaryLight
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.splineSans(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.primaryLight : AppColors.textDarkLight)
                  : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoomSetupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomSetupSheet(
        videos: videos,
        onCancel: () => Navigator.pop(context),
      ),
    );
  }
}

class VideoSearchDelegate extends SearchDelegate {
  final List<Video> videos;
  final bool isDark;

  VideoSearchDelegate({required this.videos, required this.isDark});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = videos
        .where((v) => v.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _buildListView(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = videos
        .where((v) => v.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return _buildListView(suggestions, context);
  }

  Widget _buildListView(List<Video> results, BuildContext context) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final video = results[index];
        return ListTile(
          leading: const Icon(Icons.movie),
          title: Text(video.title,
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          subtitle: Text(video.duration,
              style:
                  TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          onTap: () async {
            final file = await video.asset.file;
            if (file != null && context.mounted) {
              close(context, null);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    videoFile: file,
                    title: video.title,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
