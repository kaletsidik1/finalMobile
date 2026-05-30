import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get mistralApiKey =>
      dotenv.env['MISTRAL_API_KEY']?.trim() ?? '';

  static String get mistralModel =>
      dotenv.env['MISTRAL_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['MISTRAL_MODEL']!.trim()
          : 'mistral-small-latest';

  static bool get useMistralAi => mistralApiKey.isNotEmpty;
}
