/// Ethiopian mobile: country code 251 + 9 digits starting with 9 (e.g. 912345678).
class EthiopianPhone {
  EthiopianPhone._();

  static const countryCode = '251';
  static const localLength = 9;

  static final _localPattern = RegExp(r'^9\d{8}$');
  static final _internationalPattern = RegExp(r'^2519\d{8}$');

  /// Validates the 9-digit local part (user input after +251).
  static bool isValidLocal(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return _localPattern.hasMatch(digits);
  }

  /// Builds full international number: 251 + 9 local digits.
  static String toInternational(String localInput) {
    final digits = localInput.replaceAll(RegExp(r'\D'), '');
    return '$countryCode$digits';
  }

  static String? validateLocal(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length != localLength) {
      return 'Enter exactly 9 digits';
    }
    if (!digits.startsWith('9')) {
      return 'Number must start with 9';
    }
    if (!_localPattern.hasMatch(digits)) {
      return 'Enter a valid mobile number (9XXXXXXXX)';
    }
    return null;
  }
}
