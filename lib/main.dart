import 'package:agrimatketapp/screens/auth/login_screen.dart';
import 'package:agrimatketapp/screens/farmer/farmer_dashboard.dart';
import 'package:agrimatketapp/screens/trader/trader_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:agrimatketapp/theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/farmer_signup_screen.dart';
import 'screens/trader_signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriMarket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/signup': (context) => const SignupScreen(),
        '/farmer-signup': (context) => const FarmerSignupScreen(),
        '/trader-signup': (context) => const TraderSignupScreen(),
        '/login': (context) => const LoginScreen(),
        '/farmer-dashboard': (context) => const FarmerDashboard(),
        '/trader-dashboard': (context) => const TraderDashboard(),
      },
      home: const OnboardingScreen(),
    );
  }
}
