class OnboardingPageData {
  const OnboardingPageData({
    required this.imageAsset,
    required this.title,
    required this.body,
  });

  final String imageAsset;
  final String title;
  final String body;
}

const onboardingPages = [
  OnboardingPageData(
    imageAsset: 'assets/images/food_app_onboarding_screen_1.png',
    title: 'Never lose a recipe again',
    body:
        'Share your favorite reels or videos from any platform into your personal culinary library.',
  ),
  OnboardingPageData(
    imageAsset: 'assets/images/food_app_onboarding_screen_2.png',
    title: 'Shopping made simple',
    body:
        'Create organized shopping lists from your recipes so every grocery trip stays easy.',
  ),
  OnboardingPageData(
    imageAsset: 'assets/images/food_app_onboarding_screen_3.png',
    title: 'Start Cooking',
    body:
        'Follow clear steps in your kitchen and bring every dish to the table with confidence.',
  ),
];
