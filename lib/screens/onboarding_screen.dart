import 'package:agrimatketapp/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../widgets/onboarding_page.dart';
import '../widgets/page_indicator.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < onboardingPages.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.jumpToPage(onboardingPages.length - 1);
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF2A5A2A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: onboardingPages.length,
                itemBuilder: (context, index) {
                  final page = onboardingPages[index];
                  return OnboardingPage(
                    title: page.title,
                    description: page.description,
                    imagePath: page.imagePath,
                    isLastPage: page.isLastPage,
                    isLottie: page.isLottie,
                  );
                },
              ),
            ),
            PageIndicator(
              currentPage: _currentPage,
              totalPages: onboardingPages.length,
            ),
            const SizedBox(height: 30),
            if (_currentPage == onboardingPages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Get Started',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>const LoginScreen()));
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Create Account',
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      isOutlined: true,
                      textColor: Colors.black,
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),       
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}