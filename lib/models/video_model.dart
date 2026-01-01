import 'package:photo_manager/photo_manager.dart';

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
