import 'dart:convert';

import 'package:agrimatketapp/config/env_config.dart';
import 'package:dio/dio.dart';

class MistralAiService {
  static final MistralAiService _instance = MistralAiService._internal();
  factory MistralAiService() => _instance;
  MistralAiService._internal();

  static const _baseUrl = 'https://api.mistral.ai/v1';

  Dio? _dio;

  Dio get _client {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Authorization': 'Bearer ${EnvConfig.mistralApiKey}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    return _dio!;
  }

  void _ensureConfigured() {
    if (!EnvConfig.useMistralAi) {
      throw Exception(
        'Mistral API key missing. Add MISTRAL_API_KEY to your .env file.',
      );
    }
  }

  Future<Map<String, dynamic>> recommendCrop(Map<String, dynamic> payload) async {
    _ensureConfigured();

    final nitrogen = payload['nitrogen'];
    final phosphorus = payload['phosphorus'];
    final potassium = payload['potassium'];
    final temperature = payload['temperature'];
    final humidity = payload['humidity'];
    final ph = payload['ph'];
    final rainfall = payload['rainfall'];
    final soilColor = payload['soil_color'] ?? payload['soilColor'] ?? 'brown';
    final region = payload['region']?.toString();

    final regionLine = region != null && region.isNotEmpty
        ? '- Region: $region\n'
        : '';

    final prompt = '''
You are an agricultural advisor for Ethiopian smallholder farmers.
Given soil and climate inputs, recommend the top 5 crops suited for cultivation.
Focus on crops commonly grown in Ethiopia (teff, wheat, maize, barley, sorghum, coffee, etc.).

Soil & climate inputs:
- Nitrogen (N): $nitrogen
- Phosphorus (P): $phosphorus
- Potassium (K): $potassium
- Temperature (°C): $temperature
- Humidity (%): $humidity
- Soil pH: $ph
$regionLine- Rainfall (mm): $rainfall
- Soil color: $soilColor

Respond with ONLY valid JSON (no markdown), exactly this shape:
{
  "recommendations": [
    {"crop": "teff", "confidence": "0.92"},
    {"crop": "wheat", "confidence": "0.78"}
  ]
}
Use crop names in lowercase. confidence is a decimal string between 0 and 1 (higher = better match).
Include exactly 5 recommendations, sorted by confidence descending.
''';

    final json = await _chatJson(prompt);
    final recs = json['recommendations'];
    if (recs is! List || recs.isEmpty) {
      throw Exception('Mistral returned no crop recommendations');
    }
    return json;
  }

  Future<Map<String, dynamic>> predictPrice(Map<String, dynamic> payload) async {
    _ensureConfigured();

    final cropName = payload['crop_name']?.toString() ?? 'teff';
    final region = payload['region']?.toString() ?? 'Oromia';
    final year = payload['year'] ?? DateTime.now().year;
    final month = payload['month'] ?? DateTime.now().month;

    final prompt = '''
You are an Ethiopian agricultural market analyst.
Estimate a plausible wholesale/farm-gate price forecast in Ethiopian Birr (ETB) per kg for the given crop, region, and month.
Use realistic 2024–2026 Ethiopian market patterns; this is guidance for farmers, not financial advice.

Crop: $cropName
Region: $region
Year: $year
Month: $month

Respond with ONLY valid JSON (no markdown), exactly this shape:
{
  "crop_name": "$cropName",
  "region": "$region",
  "year": $year,
  "month": $month,
  "predicted_price": 42.5,
  "trend": "up",
  "trend_percentage": 4.2,
  "confidence_interval": [38.0, 47.0]
}
trend must be one of: "up", "down", "stable".
predicted_price and confidence_interval values are numbers in ETB per kg.
''';

    return _chatJson(prompt);
  }

  /// Free-form farming assistant chat (used by farmer chat screen).
  Future<String> chat({
    required String userMessage,
    List<Map<String, String>> history = const [],
    String? region,
  }) async {
    _ensureConfigured();

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _farmingSystemPrompt(region)},
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': userMessage},
    ];

    return _chatCompletion(messages: messages, temperature: 0.6);
  }

  static String _farmingSystemPrompt(String? region) {
    final regionLine = region != null && region.isNotEmpty
        ? 'The farmer is based in $region, Ethiopia.'
        : 'The farmer is in Ethiopia.';

    return '''
You are AgriMarket AI, a practical farming assistant for Ethiopian smallholder farmers.
$regionLine

Guidelines:
- Give clear, actionable advice on crops (teff, wheat, maize, barley, coffee, etc.), soil, rainfall seasons, pests, and local practices.
- Use short paragraphs and bullet lists when helpful. Stay under 200 words unless the user asks for detail.
- Mention prices in Ethiopian Birr (ETB) only as rough guidance, not guarantees.
- For precise crop rankings from soil lab data, tell them to use the menu: "Get Crop Recommendation".
- For market price forecasts by month/region, tell them to use "Get Price Forecast" in the menu.
- If unsure, say what you know and what data would help.
- Be warm and supportive; avoid jargon.
''';
  }

  Future<Map<String, dynamic>> _chatJson(String userPrompt) async {
    final content = await _chatCompletion(
      messages: [
        {
          'role': 'system',
          'content':
              'You respond only with valid JSON objects. No prose, no markdown fences.',
        },
        {'role': 'user', 'content': userPrompt},
      ],
      temperature: 0.3,
      jsonMode: true,
    );
    return _parseJsonContent(content);
  }

  Future<String> _chatCompletion({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.5,
    bool jsonMode = false,
  }) async {
    final data = <String, dynamic>{
      'model': EnvConfig.mistralModel,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': 1024,
    };
    if (jsonMode) {
      data['response_format'] = {'type': 'json_object'};
    }

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/chat/completions',
        data: data,
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        final msg = _errorFromBody(response.data);
        throw Exception(msg ?? 'Mistral API error ($status)');
      }

      return _extractMessageContent(response.data);
    } on DioException catch (e) {
      final msg = _errorFromBody(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Network error contacting Mistral');
    }
  }

  String _extractMessageContent(Map<String, dynamic>? body) {
    if (body == null) {
      throw Exception('Empty response from Mistral');
    }
    final choices = body['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content']?.toString();
          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
      }
    }
    throw Exception('Unexpected Mistral response format');
  }

  Map<String, dynamic> _parseJsonContent(String content) {
    var trimmed = content.trim();
    if (trimmed.startsWith('```')) {
      trimmed = trimmed.replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
      trimmed = trimmed.replaceFirst(RegExp(r'\s*```\s*$'), '');
    }
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    throw Exception('Mistral response was not a JSON object');
  }

  String? _errorFromBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
    }
    return null;
  }
}
