class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;
  final bool isLastPage;
  final bool isLottie;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isLastPage = false,
    this.isLottie = false,
  });
}
 List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Welcome to AgriMarket',
    description: 'Your smart farming assistant for better yields and profits',
    imagePath: 'assets/lotties/welcome.json',
    isLastPage: false,
    isLottie: true,
  ),
  OnboardingPageData(
    title: 'AI-Powered Insights',
    description: 'Get personalized crop recommendations and market forecasts',
    imagePath: 'assets/lotties/Farmers.json',
    isLastPage: false,
    isLottie: true,
  ),
  OnboardingPageData(
    title: 'Connect & Grow',
    description: 'Directly connect with verified traders and maximize your profits',
    imagePath: 'assets/images/connect.png',
    isLastPage: true,
    isLottie: false,
  ),
];