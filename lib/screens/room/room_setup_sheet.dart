import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/video_model.dart';
import '../../widgets/video_thumbnail_widget.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import 'room_lobby_sheet.dart';

class RoomSetupSheet extends StatefulWidget {
  final List<Video> videos;
  final VoidCallback onCancel;

  const RoomSetupSheet({
    super.key,
    required this.videos,
    required this.onCancel,
  });

  @override
  State<RoomSetupSheet> createState() => _RoomSetupSheetState();
}

class _RoomSetupSheetState extends State<RoomSetupSheet> {
  int _currentStep = 1;
  Video? _selectedVideo;
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : const Color(0xFF181811);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == 1
            ? _buildStep1(isDark, textColor)
            : _buildStep2(isDark, textColor),
      ),
    );
  }

  Widget _buildStep1(bool isDark, Color textColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(isDark),
            const SizedBox(height: 24),
            Text(
              'Pick a Movie',
              style: GoogleFonts.splineSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Swipe to browse your library',
              style: GoogleFonts.splineSans(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.videos.length,
                itemBuilder: (context, index) {
                  final video = widget.videos[index];
                  final isSelected = _selectedVideo == video;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedVideo = video),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryLight
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: VideoThumbnailWidget(
                                asset: video.asset,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            video.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.splineSans(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton(
              label: 'Next',
              onPressed: _selectedVideo != null
                  ? () => setState(() => _currentStep = 2)
                  : null,
            ),
            const SizedBox(height: 16),
            _buildSecondaryButton(label: 'Cancel', onPressed: widget.onCancel),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(bool isDark, Color textColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(isDark),
            const SizedBox(height: 16),
            // Hero Thumbnail
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: VideoThumbnailWidget(
                  asset: _selectedVideo!.asset,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedVideo!.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedVideo!.duration} • Local Movie',
              style: GoogleFonts.splineSans(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildIconButton(
                    icon: Icons.share,
                    label: 'Save to Drive',
                    onTap: _saveToDrive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIconButton(
                    icon: Icons.link,
                    label: 'Get Link',
                    onTap: _openDrive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Paste Field
            TextField(
              controller: _linkController,
              style: GoogleFonts.splineSans(color: textColor),
              decoration: InputDecoration(
                hintText: 'Paste Drive Link here...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, color: AppColors.primaryLight),
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildPrimaryButton(
              label: _isLoading ? 'Creating Room...' : 'Start Watch Party',
              onPressed: _isLoading ? null : _createRoom,
            ),
            const SizedBox(height: 16),
            _buildSecondaryButton(
                label: 'Back',
                onPressed: () => setState(() => _currentStep = 1)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      width: 48,
      height: 6,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF55553A) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: Text(
          label,
          style:
              GoogleFonts.splineSans(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(
      {required String label, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.splineSans(
            color: Colors.grey, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A3927) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryLight),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.splineSans(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _saveToDrive() async {
    final file = await _selectedVideo!.asset.file;
    if (file != null) {
      _showTutorial('How to Save',
          '1. Tap Share\n2. Select "Google Drive"\n3. After upload finishes, come back here.');
      await Share.shareXFiles([XFile(file.path)],
          text: 'Uploading to my theater');
    }
  }

  void _openDrive() async {
    _showTutorial('Manage Access',
        '1. Find the file in Drive\n2. Tap "Manage Access"\n3. Set to "Anyone with link"\n4. Copy link and paste here.');
    final url = Uri.parse('https://drive.google.com/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showTutorial(String title, String steps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title,
            style: GoogleFonts.splineSans(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(steps,
            style: GoogleFonts.splineSans(
                color: Colors.grey.shade400, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!',
                style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() => _linkController.text = data!.text!);
    }
  }

  void _createRoom() async {
    if (_linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please paste the Drive link first!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Ensure Anonymous Auth (Invisible to user)
      await AuthService().signInAnonymously();

      // 2. Extract File ID from link (Simple regex)
      final link = _linkController.text;
      String fileId = '';
      final regExp = RegExp(r'[-\w]{25,}');
      final match = regExp.firstMatch(link);
      if (match != null) {
        fileId = match.group(0)!;
      } else {
        throw Exception('Invalid Google Drive link format');
      }

      // 3. Create Room in Firebase
      final roomId = await RoomService().createRoom(
        fileId: fileId,
        fileName: _selectedVideo!.title,
        videoUrl: link, // The actual share link
        isDriveFile: true,
      );

      if (mounted) {
        Navigator.pop(context); // Close setup sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => RoomLobbySheet(
            roomId: roomId,
            roomTitle: _selectedVideo!.title,
            movieId: fileId,
            hostName: AuthService().currentUser?.displayName ?? 'Host',
            onCancel: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
