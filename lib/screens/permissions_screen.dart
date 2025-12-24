import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onGrantPermissions;
  final VoidCallback onMaybeLater;

  const PermissionsScreen({
    super.key,
    required this.onGrantPermissions,
    required this.onMaybeLater,
  });

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _localStorageEnabled = false;
  bool _microphoneEnabled = false;
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      Map<Permission, PermissionStatus> statuses = {};

      // 1. Determine which Storage permissions to request based on Android version
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ requires granular permissions
          if (_localStorageEnabled) {
            final videoStatus = await Permission.videos.request();
            statuses[Permission.videos] = videoStatus;

            // Getting photos often helps if videos are mixed or for thumbnails
            final photosStatus = await Permission.photos.request();
            statuses[Permission.photos] = photosStatus;
          }
        } else {
          // Android 12 and below use generic STORAGE permission
          if (_localStorageEnabled) {
            final storageStatus = await Permission.storage.request();
            statuses[Permission.storage] = storageStatus;
          }
        }
      }

      // 2. Request Microphone permission
      if (_microphoneEnabled) {
        final micStatus = await Permission.microphone.request();
        statuses[Permission.microphone] = micStatus;
      }

      // 3. Check results
      bool allGranted = true;
      bool anyPermanentlyDenied = false;

      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
        if (status.isPermanentlyDenied) {
          anyPermanentlyDenied = true;
        }
      });

      if (!mounted) return;

      if (allGranted) {
        // Save onboarding state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOnboardingComplete', true);

        if (!mounted) return;

        // Success!
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
          (route) => false,
        );
      } else {
        // Failure
        if (anyPermanentlyDenied) {
          _showSettingsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Permissions declined. Please accept permissions to proceed.',
                style: GoogleFonts.splineSans(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissions Required',
            style: GoogleFonts.splineSans(fontWeight: FontWeight.bold)),
        content: Text(
          'We cannot function without these permissions. Please open settings to grant them manually.',
          style: GoogleFonts.splineSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      "https://lh3.googleusercontent.com/aida-public/AB6AXuC_-usJhNbcEDDuZFdFV76OT7TdwkjK15cccSmMZ08vbcSK02aMB369EcF22ZtMCxi1ar3OvmEjVkcrs_Z2o43gqqE-T8OfBle4MeK1HF6jdAGKw1u0KS1YM5mjiuD8FPQId3-QIc5l9P_mMibzNiwiHO_YYybAlAiODMzzeeA60oz25Kt0fKLIutqIogJNguhMgGu5MfBwAx-u1jvTqqsnMBE_2Fem_ILt54lOWyuOOvOJhtcSkxVEn1MmRUBiRqw3owGMhhyEh-3e",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark
                              ? const Color(0xFF333226)
                              : Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image_not_supported),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark
                                    ? AppColors.backgroundDark
                                    : AppColors.backgroundLight)
                                .withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Headline
                      Text(
                        "Let's get set up",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.splineSans(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: isDark
                              ? AppColors.textLightDark
                              : AppColors.textDarkLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "To watch together and chat, we need access to a few things on your device.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.splineSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: isDark
                              ? AppColors.textGreyDark
                              : AppColors.textGreyLightAlt,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Permission Items
                      _buildPermissionItem(
                        context,
                        icon: Icons.storage,
                        title: "Local Storage",
                        description:
                            "Required to load your movie files so you can watch them.",
                        enabled: _localStorageEnabled,
                        onChanged: (value) {
                          setState(() {
                            _localStorageEnabled = value;
                          });
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildPermissionItem(
                        context,
                        icon: Icons.mic,
                        title: "Microphone",
                        description:
                            "Required to talk with your friends while watching movies together.",
                        enabled: _microphoneEnabled,
                        onChanged: (value) {
                          setState(() {
                            _microphoneEnabled = value;
                          });
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_localStorageEnabled && _microphoneEnabled)
                                ? AppColors.primaryLight
                                : const Color(0xFFD3D3D3),
                        foregroundColor:
                            (_localStorageEnabled && _microphoneEnabled)
                                ? AppColors.textDarkLight
                                : const Color(0xFF999999),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: (_localStorageEnabled && _microphoneEnabled)
                            ? 2
                            : 0,
                      ),
                      onPressed: (_localStorageEnabled &&
                              _microphoneEnabled &&
                              !_isRequesting)
                          ? _requestPermissions
                          : null,
                      child: _isRequesting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black54))
                          : Text(
                              'Grant Permissions',
                              style: GoogleFonts.splineSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF333226) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF444338) : const Color(0xFFE5E5E5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.2),
            ),
            child: Center(
              child: Icon(
                icon,
                color:
                    isDark ? AppColors.primaryLight : AppColors.textDarkLight,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textLightDark
                        : AppColors.textDarkLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.splineSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textGreyDark
                        : AppColors.textGreyLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Toggle Switch
          _buildToggleSwitch(
            value: enabled,
            onChanged: onChanged,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.5),
          color: value
              ? AppColors.primaryLight
              : (isDark ? const Color(0xFF444338) : const Color(0xFFD3D3D3)),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
}
