import 'package:flutter/material.dart';

enum PasswordStrength { none, weak, medium, strong }

class PasswordStrengthEvaluator {
  PasswordStrengthEvaluator._();

  static final _hasLetter = RegExp(r'[a-zA-Z]');
  static final _hasNumber = RegExp(r'\d');
  static final _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/;~`]');

  static PasswordStrength evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    final hasLetter = _hasLetter.hasMatch(password);
    final hasNumber = _hasNumber.hasMatch(password);
    final hasSpecial = _hasSpecial.hasMatch(password);
    final typeCount = [hasLetter, hasNumber, hasSpecial].where((v) => v).length;

    if (typeCount == 3 && password.length >= 8) {
      return PasswordStrength.strong;
    }
    if (typeCount >= 2 && password.length >= 6) {
      return PasswordStrength.medium;
    }
    return PasswordStrength.weak;
  }

  static bool isStrongEnough(String password) {
    return evaluate(password) == PasswordStrength.strong;
  }

  static String hint(PasswordStrength strength) {
    return switch (strength) {
      PasswordStrength.none => 'Use 8+ characters with letters, numbers, and symbols',
      PasswordStrength.weak => 'Weak — add letters, numbers, and special characters',
      PasswordStrength.medium => 'Fair — include letters, numbers, and a symbol for a strong password',
      PasswordStrength.strong => 'Strong password',
    };
  }

  static Color color(PasswordStrength strength) {
    return switch (strength) {
      PasswordStrength.none => const Color(0xFFBDBDBD),
      PasswordStrength.weak => const Color(0xFFD32F2F),
      PasswordStrength.medium => const Color(0xFFF9A825),
      PasswordStrength.strong => const Color(0xFF2E7D32),
    };
  }
}
