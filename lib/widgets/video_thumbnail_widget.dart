import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatelessWidget {
  final AssetEntity asset;
  final bool isDark;
  final BoxFit fit;

  // Simple memory cache for thumbnails
  static final Map<String, Uint8List> _thumbCache = {};

  const VideoThumbnailWidget({
    super.key,
    required this.asset,
    required this.isDark,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // For movies (longer than 5 mins), skip the first 15 seconds to avoid black intros/logos
    // For shorter videos, skip 2 seconds.
    final int timeMs = (asset.duration > 300) ? 15000 : 2000;
    final String cacheKey = '${asset.id}_$timeMs';

    // Check memory cache first
    if (_thumbCache.containsKey(cacheKey)) {
      return Image.memory(
        _thumbCache[cacheKey]!,
        fit: fit,
        gaplessPlayback: true,
      );
    }

    return FutureBuilder<File?>(
      future: asset.file,
      builder: (context, fileSnapshot) {
        if (fileSnapshot.connectionState == ConnectionState.done &&
            fileSnapshot.hasData &&
            fileSnapshot.data != null) {
          return FutureBuilder<Uint8List?>(
            key: ValueKey(cacheKey),
            future: VideoThumbnail.thumbnailData(
              video: fileSnapshot.data!.path,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 300,
              timeMs: timeMs,
              quality: 40,
            ),
            builder: (context, thumbSnapshot) {
              if (thumbSnapshot.connectionState == ConnectionState.done &&
                  thumbSnapshot.hasData &&
                  thumbSnapshot.data != null) {
                // Save to cache for subsequent builds
                _thumbCache[cacheKey] = thumbSnapshot.data!;

                return Image.memory(
                  thumbSnapshot.data!,
                  fit: fit,
                  gaplessPlayback: true,
                );
              }
              return _placeholder();
            },
          );
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          color: isDark ? Colors.white10 : Colors.black12,
          size: 40,
        ),
      ),
    );
  }
}
