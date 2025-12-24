import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../constants/app_colors.dart';
import 'video_player_screen.dart';

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
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    // Request permission again just to be safe/granular with PhotoManager
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      // If no permission, just stop loading (empty list)
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Get video albums
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );

    if (paths.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Usually the first one is "Recent" or "All"
    final AssetPathEntity path = paths[0];
    final int assetCount = await path.assetCountAsync;

    // Fetch assets (videos)
    final List<AssetEntity> assets = await path.getAssetListRange(
      start: 0,
      end: assetCount,
    );

    // Map to our Video model
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
              content: Text(
                'Press back again to exit',
                style: GoogleFonts.splineSans(),
              ),
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
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Logo
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
                    // Profile Button
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to profile
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAeJeLnCik4E2FXj47H757NcWME13AzzgjTorqRIDdslkz0qk23dAJESd2hUGK2JRxtOb9OffOJbV8rDeUWZpIYv8amN_yVhXRyXJdmVKre2NiaovwQ1DGEoyl-N5wTsuCC52UHWgt-dt9AbPFxKF4tvMjF1-iSGF9VLeZCZ0vnzn8KqEHeIl_xCBrjHvfluVaJLBeOX2eEIhKqqXbVn9sjblwg4Fxx1UDqcRNC913Gt7vwp6-HdePjKJdex7kSz7nO_axAveHsoIPf',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[400],
                                child: const Icon(Icons.person),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Library Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    IconButton(
                      icon: Icon(
                        Icons.sort,
                        color: isDark
                            ? AppColors.textGreyDark
                            : AppColors.textGreyLight,
                      ),
                      onPressed: () {
                        // TODO: Implement sorting
                      },
                    ),
                  ],
                ),
              ),
              // Videos Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : videos.isEmpty
                        ? Center(
                            child: Text(
                              "No videos found",
                              style: GoogleFonts.splineSans(
                                color: isDark
                                    ? AppColors.textGreyDark
                                    : AppColors.textGreyLight,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  final file = await video.asset.file;
                                  if (file != null && context.mounted) {
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
                                onLongPress: () {
                                  setState(() {
                                    if (_selectedVideos.contains(video.title)) {
                                      _selectedVideos.remove(video.title);
                                    } else {
                                      _selectedVideos.add(video.title);
                                    }
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  // Use AssetEntityImage for high-performance thumbnail loading
                                                  AssetEntityImage(
                                                    video.asset,
                                                    isOriginal:
                                                        false, // Use thumbnail
                                                    thumbnailSize:
                                                        const ThumbnailSize
                                                            .square(300),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF333226)
                                                            : Colors.grey[200],
                                                        child: const Center(
                                                          child: Icon(Icons
                                                              .broken_image),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  // Border if selected
                                                  if (isSelected)
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.6),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                video.duration,
                                                style: GoogleFonts.splineSans(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
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
                                                  color: AppColors.primaryLight,
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
                                            // If larger than 1000MB, show GB
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
              const SizedBox(height: 100),
            ],
          ),
        ),
        // Start Party Button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // TODO: Start party with selected videos
          },
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.black,
          elevation: 2,
          icon: const Icon(Icons.screen_share),
          label: Text(
            'Start Party',
            style: GoogleFonts.splineSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Bottom Navigation
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFE5E5E5),
                width: 1,
              ),
            ),
            color: isDark
                ? AppColors.backgroundDark.withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryLight,
            unselectedItemColor:
                isDark ? AppColors.textGreyDark : AppColors.textGreyLight,
            selectedLabelStyle: GoogleFonts.splineSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.splineSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle),
                label: 'Watch',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Room',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Video {
  final AssetEntity asset;
  final String title;
  final String duration;
  final String dateAdded;

  Video({
    required this.asset,
    required this.title,
    required this.duration,
    required this.dateAdded,
  });
}
