/// Model for onboarding page data
class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final String heroImage;
  final List<String>? profileImages;
  final String? chatBubble;
  final bool showProfileImages;
  final bool showChatBubble;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.heroImage,
    this.profileImages,
    this.chatBubble,
    this.showProfileImages = false,
    this.showChatBubble = false,
  });
}
