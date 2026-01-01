import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class SettingsView extends StatefulWidget {
  final bool isDark;

  const SettingsView({super.key, required this.isDark});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  bool _micEnabled = true;
  bool _localNetworkEnabled = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Display'),
                    _buildSettingsCard([
                      _buildToggleItem(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        value: _isDarkMode,
                        onChanged: (val) => setState(() => _isDarkMode = val),
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Playback & Social'),
                    _buildSettingsCard([
                      _buildToggleItem(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        value: _notificationsEnabled,
                        onChanged: (val) =>
                            setState(() => _notificationsEnabled = val),
                      ),
                      _buildNavigationItem(
                        icon: Icons.data_usage,
                        title: 'Cellular Data Usage',
                        trailingText: 'High Quality',
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Permissions'),
                    _buildSettingsCard([
                      _buildToggleItem(
                        icon: Icons.mic_none,
                        title: 'Microphone',
                        subtitle: 'Required for voice chat',
                        value: _micEnabled,
                        onChanged: (val) => setState(() => _micEnabled = val),
                      ),
                      _buildToggleItem(
                        icon: Icons.lan_outlined,
                        title: 'Local Network',
                        subtitle: 'Find devices for sharing',
                        value: _localNetworkEnabled,
                        onChanged: (val) =>
                            setState(() => _localNetworkEnabled = val),
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Support'),
                    _buildSettingsCard([
                      _buildNavigationItem(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                      ),
                      _buildNavigationItem(
                        icon: Icons.policy_outlined,
                        title: 'Privacy Policy',
                      ),
                      _buildInfoItem(
                        icon: Icons.info_outline,
                        title: 'Version',
                        trailingText: 'v1.0.4',
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                    const SizedBox(height: 12),
                    _buildFooter(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 20,
                color: widget.isDark ? Colors.white : AppColors.textDarkLight),
            onPressed: () {},
          ),
          Text(
            'Settings',
            style: GoogleFonts.splineSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppColors.textDarkLight,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Done',
              style: GoogleFonts.splineSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: widget.isDark
            ? null
            : Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuB0AUCUwm-v3Zloyefv4buAB9AIUmZICKzThA64m-24xQ2mXr8OaqPXShkKIJ8UodXa9iTvhahbSgCyrZ55WCITpchvZ439AmY95PcHfBkhmML7z4hjnOy0_wEC8voTyCqd7PRhskC8ETXZzmpBG3Ia5lgtsiSSYHLc3JyNAI7xdgL16zMCfO1cBIrFeOcXheDLtYgMfwVMGcBAnUIC8UtY79qU4cdJR04BgEep4uqkAFZpr8zyP9WaAS2VYfC-dL-9wQdFPxOsEvI1'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color:
                            widget.isDark ? AppColors.cardDark : Colors.white,
                        width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 10, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alex Johnson',
                  style: GoogleFonts.splineSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDark ? Colors.white : AppColors.textDarkLight,
                  ),
                ),
                Text(
                  'alex.j@example.com',
                  style: GoogleFonts.splineSans(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.splineSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: widget.isDark
            ? null
            : Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildIcon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.splineSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark
                            ? Colors.white
                            : AppColors.textDarkLight,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.splineSans(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryLight,
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primaryLight;
                  }
                  return Colors.grey.shade700;
                }),
              ),
            ],
          ),
        ),
        if (!isLast) _buildDivider(),
      ],
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    String? trailingText,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildIcon(icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.splineSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark
                          ? Colors.white
                          : AppColors.textDarkLight,
                    ),
                  ),
                ),
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: GoogleFonts.splineSans(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) _buildDivider(),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String trailingText,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildIcon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        widget.isDark ? Colors.white : AppColors.textDarkLight,
                  ),
                ),
              ),
              Text(
                trailingText,
                style: GoogleFonts.splineSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) _buildDivider(),
      ],
    );
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          color: widget.isDark ? Colors.white : AppColors.textDarkLight,
          size: 20),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: widget.isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: GoogleFonts.splineSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'AppID: 883-292-10 • Server: US-East-1',
        style: GoogleFonts.splineSans(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
