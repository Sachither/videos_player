import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class RoomView extends StatelessWidget {
  final bool isDark;

  const RoomView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildFeaturedCard(),
                    _buildSectionHeader('Live Rooms'),
                    _buildLiveRoomsList(),
                    _buildCreateRoomPlaceholder(),
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
        children: [
          Icon(Icons.arrow_back_ios_new,
              size: 20, color: isDark ? Colors.white : AppColors.textDarkLight),
          Expanded(
            child: Center(
              child: Text(
                'Find a Room',
                style: GoogleFonts.splineSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDarkLight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40), // Placeholder to balance arrow
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF323118) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: isDark ? null : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Icon(Icons.search, color: Color(0xFF8C8B5F), size: 24),
            ),
            Expanded(
              child: TextField(
                style: GoogleFonts.splineSans(
                  color: isDark ? Colors.white : AppColors.textDarkLight,
                ),
                decoration: InputDecoration(
                  hintText: 'Search room ID or paste link...',
                  hintStyle: GoogleFonts.splineSans(
                    color:
                        isDark ? Colors.grey.shade500 : const Color(0xFF8C8B5F),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.content_paste,
                    color: Color(0xFF181811), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuA40gseHbiioWpGQounCDc_1ZP7WRMQ-FtKqMlmyabTtLSpNBEEanRlcMoviT4kUzUlW63snGqQu4vK7m3s2cxGb9j3CNjPOS6CSiJunWb6_ofMq1r9CL8ptjqHkeGTNfExQlarBWDuYy7dz3KNGl53p0Ilh-U3jLm4j0rBbTOLCV4JC9SNUdadv1YsvvhsB3Pjhd8qcZqVfmZYaulqVU5Zx-VRS3dhE_7JU3vKk4YyIptejEky5XQG0h9X5B2FeJ1axx8U-8rOrdTA'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEW RELEASE',
                style: GoogleFonts.splineSans(
                  color: AppColors.primaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dune: Part Two',
                style: GoogleFonts.splineSans(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Watch the exclusive trailer now',
                style: GoogleFonts.splineSans(
                  color: Colors.grey.shade300,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildPageIndicator(false),
                  const SizedBox(width: 4),
                  _buildPageIndicator(false),
                  const SizedBox(width: 4),
                  _buildPageIndicator(false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool active) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : Colors.white.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.splineSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDarkLight,
            ),
          ),
          Text(
            'View All',
            style: GoogleFonts.splineSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRoomsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        final List<Map<String, String>> roomData = [
          {
            'title': 'Interstellar - 4k Local',
            'time': '02:49:00 left',
            'user': '@MovieBuff99',
            'image':
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCcFLQ2I11LNEWRc_pf02UW1dy59RP_Be4SOzFo9oQK5nCpkZswSejFZWwTQn4Z_-dDcc3i_i3lsIHeoEldt9uF-c1esj_B6LuSh8i3iYZIYfqQuN_29F3J11pg3G5jGvCCzJN7k4RHYaUzqzI8rkHGERkJGa69zSpCxzRj2lE3JsNZvuIjwH1d3vVu84SOjALQA-syUhudl3-nAKK3lzti98WX5RTnjEgSFqQwZaB9-aTArIDm-7JoB4gbIJ0Z5J6esurQu3rdEyj7',
            'avatar':
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDHZtpMeaKH1BeX_Fd7nIuDhtIa5c3radVF_eIHqJPHYaEEsmBmRUH-FwmQZisiG_w-mPpKwUZb332CoFC1ESPeoZrZ4dvSncGjWE6cLzHDd7dRs7_j6R4akeH1lJJbg4ggpqDRRzxO19XrMMkUkwo1HFOmcOPhxKat3FUYnEDdZKqNdwVQ8jNL_4i6yPUH19xHT6BcPT_e4-2poN0neCly7qLV9WYy-fc7YQR6HRnClBJGHh91_xpXNuoqKVqUpb-6zCIZut4pexPl',
            'status': 'LIVE',
          },
          {
            'title': 'Friday Night Anime Marathon',
            'time': '12/20',
            'user': '@SarahJ',
            'image':
                'https://lh3.googleusercontent.com/aida-public/AB6AXuB_NqTzu5t-EPXpWuOAk7JpWvCdtkVFQGhereDkAKBwWdELtv4HP2cv5AK8BFGL5jB6mpE6HKdMHbEaqjdkBsmXNTEKcah2u3nUwvv0aERixwKbXJDR4CR06_MulZzVfP-KWVdzR7fBjZgCKjFVYztFebfkvA0ExEn3kRPZn86lRUDAMRCAqtLjSTvepQtpXhZhxBBp_KNEdLi4ABVVeEk79CI37dK67oFYtUpo6BbyyfQFEpTK4crJ1gg_ONOnnbVBXnGltNAjcKQh',
            'avatar':
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCr2cR8nQUl3fwfQlXTzbW-YM1ImUgm8HkHmTl_G9zIWRaqE8igL4PZXAgtZzXffQ-lviNUPUaHOGK2tBVF98vWKhu6GU42Rhx9VAeb4kcX6n5xbBPEW9Th4s9w_KBdEdpPt1LBGQHaBq_iyy3gbwB4V0qQKHw4VhHDoXqjXDHwsn0gRpsROzxYgnRemGWnREiNGjevBxDZ6UGjTKrlYf7d4HkvdJHX_Gz39psVTB542_hliHkWLskp-fLNIl-qioGTOuV0d_B3-1j1',
            'status': 'STARTING',
          },
          {
            'title': 'Horror Classics Only',
            'time': '01:15:20 left',
            'user': '@SpookyMike',
            'image':
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBBLKomCXMnihgPZ0GxqNRkb7PG--SRQR7BkSZutnj-Ku2VGhtzu-9wg82jP5hStv_1wjEspV-0BW7m_KVX2norObJocBD3QnQcKie8u_rziGsXYVZhlC3XQA7avHNsYSC-W0Fklw_ZUFIg4hpHQNZAhEof2s4eOPb42QAM2kXO074vMOg3E4xyajWOZ-JLylUH3hImnec-niyzMqciOapsVVuA1FKFCb5NvwnXMKPOnpkvOMKK4LXLvvhXxzCsK0e_u-mC7D_M_7xj',
            'avatar':
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAFDGDCgzlr-mrFM0o9u7pZqYtdM1JYy8ZDHNc3tvJ5NIPGA3c1JkEGkfzPuNNAKsqsPpOGckCAGpE4vPmvbyvxjSxqN5-LPntnX51UdLb-ADy3R6sVZUN-E5HQUhmmmm59XJl1RE9GwyqmMKdwU3LwyAUMt9Xtpr4ZnufJMtUXXlvfqJVOebf8pE75erDpNftKoTjKAcgaJJtV0qMIlk8FIHK1il_PTojYrnioel8pgpgCkB-9rxrZ9oU64OlVb_OiOuhqe71FYyRd',
            'status': 'JOIN',
          }
        ];

        final room = roomData[index];
        return _buildRoomItem(room);
      },
    );
  }

  Widget _buildRoomItem(Map<String, String> room) {
    bool isStarting = room['status'] == 'STARTING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? null : Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(room['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (room['status'] != 'JOIN')
                Positioned(
                  bottom: -8,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isStarting
                          ? const Color(0xFF2D2D2D)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isDark ? AppColors.cardDark : Colors.white,
                          width: 2),
                    ),
                    child: Text(
                      room['status']!,
                      style: GoogleFonts.splineSans(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color:
                            isStarting ? Colors.white : const Color(0xFF181811),
                      ),
                    ),
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
                  room['title']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.splineSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDarkLight,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStarting ? Icons.group : Icons.schedule,
                        size: 10,
                        color: const Color(0xFF8C8B5F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        room['time']!,
                        style: GoogleFonts.splineSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8C8B5F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundImage: NetworkImage(room['avatar']!),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        room['user']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.splineSans(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isStarting
                  ? (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200)
                  : AppColors.primaryLight,
              foregroundColor: isStarting
                  ? (isDark ? Colors.white : AppColors.textDarkLight)
                  : const Color(0xFF181811),
              elevation: isStarting ? 0 : 2,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              isStarting ? 'Full' : 'Join',
              style: GoogleFonts.splineSans(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRoomPlaceholder() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.screen_share,
                  color: AppColors.primaryLight, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              "Can't find what you're looking for?\nCreate your own room!",
              textAlign: TextAlign.center,
              style: GoogleFonts.splineSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
