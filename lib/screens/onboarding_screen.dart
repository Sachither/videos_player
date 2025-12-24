import 'package:flutter/material.dart';
import '../../models/onboarding_page.dart';
import '../../widgets/onboarding_page_widget.dart';
import '../../widgets/onboarding_controls.dart';
import 'cta_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _showCTA = false;

  final List<OnboardingPage> pages = [
    // First Page - With profile images and chat bubble
    OnboardingPage(
      title: "Watching movies has become more fun",
      subtitle: "",
      description:
          "Watch movies with friends from anywhere. Share your screen and talk in real-time.",
      heroImage:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuAU2rEL5jI2Elf6cmf8qkIVBKQtub3xy8VS5Hm-UOliqxLwClp4nhyOvnpY3_TqwrVoWuhnFUCgrFre4h5Ak-i2GZ6MnzBgn_uBCTwBSVQnK4nFxM1g3G6MfTAKzLEeezggbHXcVXxy_zuSQdos6hrHLs_RnowtHlYyAyg1PHxXNF43EN9ypCGS5RUsvUY_w2FmVNQGqcRnfbOou6MgOomXquI54jpEkXmhBHGAxuwnZPJBz1zB_-fWI2hwjaTq9qaez6ZfbIO6RXeb",
      profileImages: [
        "https://lh3.googleusercontent.com/aida-public/AB6AXuALLjZBRRu9_jg-lLNgY2DCXLISIB_iq7hbygxs5BGp4pURkH_7xFEIuMqRSxxksAYaZR_Sm3OWhSuemm4TQZ5rCoZwLyvHP42uN2cpsrc9asSyMxil7VtLAvSYjthI0qagcwrzpLYHkVJiYiPS2FIQ686I6HZShwBkaNKM4nnCSKIX5Ni_w4qr_5MyFJXJM_1XLnB_NqIsgvkoSNtVFhdbhBRTEweIkAU0EHuMgXnpvd8_H_a26JhJJoDKcIHviNIsweGQc7hn-p7-",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuCAO3JArhOUOu7YwnC93P64GUHX2jnu9C7k5GH8-ihJSIvEsfLrz19-g79ZW2dyaplGnT6IiOCmKG4OnxsTEsfwNxAzZcbZ_8sri__MWFr8jRd5VS_Xia4sFv1id0ut8P8KtWY1a4FtyNlBzG4HaYyP93-DXk3cPb4GEEeIKYcK-fgOCetw-aiJ_TymFWx68GvdZ2jggsdVJ7Qbw1pTrAFD5DJDLj7eaZYjn-wSURjZBKYwb6fZL3GJZ-wujQx5On2D-wwxh-8uLVB-"
      ],
      chatBubble: "OMG! 😱",
      showProfileImages: true,
      showChatBubble: true,
    ),
    // Second Page - Cinema in your Pocket
    OnboardingPage(
      title: "Cinema in your",
      subtitle: "Pocket",
      description:
          "Stream your local movie files and sync playback instantly with friends anywhere.",
      heroImage:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuC1jJccV0ont6lqydc5wpgnOTG9K_NMqXaFDAgliIo27ApxATe08YOVbpQE6RWCv00juR_enPVD1L1X1g13oCuzVmpkdYAJMs6LGoriCZ_X-4_DYWBIDV2UtFvr616ksfkc-cgYG7c2oyvgKppTdYhPr3sFULjFgd8tZ9pxXz_egxp_BoSc_exJJFU7ZFKOvyDoPvUtxoSnRGMJsNoTdW-GMexvFO1Hy5R1M2buZIGjY4eLCG0YBhMZ_Ikwi40z7YtU5Mm0zdwe41nm",
      showProfileImages: false,
      showChatBubble: false,
    ),
    // Third Page - Laugh Together
    OnboardingPage(
      title: "Laugh",
      subtitle: "Together",
      description:
          "Crystal clear voice chat lets you react, discuss, and laugh in real-time while you watch.",
      heroImage:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuD46CXtWD-6yh5N_PEV5iBH7o7GQo2rQ2_Oo6VNwuepPexe30VzVO3csud2ITq5x7qfXJnko2WP-6H-xXihA5o6lEle_VYOSQuAfEI42VcNTpx1N2tvmzms2cFk98iqkkTQwvKEUCwbtbWiZHqcBWVsDFiEAiY-9o46r4IjffS0oX0Py_gjNEpXUmyVw7gSXDentWx_rdgdentuq7RqBRmnWqt6IgBAe35ntH-QbJlekePXzDwh3JY1fa7QJYp1nEm2r-V_LH45VWzC",
      showProfileImages: false,
      showChatBubble: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Show CTA screen after last page
      setState(() {
        _showCTA = true;
      });
    }
  }

  void _skipOnboarding() {
    setState(() {
      _showCTA = true;
    });
  }

  void _onGuestStart() {
    // TODO: Navigate to home screen as guest
  }

  void _onSignUpLogin() {
    // TODO: Navigate to auth screen
  }

  @override
  Widget build(BuildContext context) {
    if (_showCTA) {
      return CTAScreen(
        onGuestStart: _onGuestStart,
        onSignUpLogin: _onSignUpLogin,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF23220F) : const Color(0xFFF8F8F5),
      body: Column(
        children: [
          // Page View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return OnboardingPageWidget(page: pages[index]);
              },
            ),
          ),
          // Bottom Controls
          OnboardingControls(
            currentPage: _currentPage,
            totalPages: pages.length,
            onNext: _goToNextPage,
            onSkip: _skipOnboarding,
          ),
        ],
      ),
    );
  }
}
