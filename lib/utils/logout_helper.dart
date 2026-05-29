import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../services/api_service.dart';

Future<void> logoutAndRedirect(BuildContext context) async {
  await ApiService().logout();

  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
