import 'dart:convert';

import 'package:http/http.dart' as http;

class SoilClimateData {
  final double? nitrogen;
  final double? phosphorus;
  final double? potassium;
  final double? ph;
  final double? temperature;
  final double? humidity;
  final double? rainfall;
  final String? error;

  const SoilClimateData({
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.ph,
    this.temperature,
    this.humidity,
    this.rainfall,
    this.error,
  });

  bool get hasData => error == null && (nitrogen != null || temperature != null);
}

class SoilClimateService {
  SoilClimateService._();

  static const _openMeteoUrl =
      'https://api.open-meteo.com/v1/forecast';
  static const _soilGridsUrl =
      'https://rest.isric.org/soilgrids/v2.0/properties/query';

  static Future<SoilClimateData> fetch(double lat, double lng) async {
    try {
      final results = await Future.wait([
        _fetchWeather(lat, lng),
        _fetchSoil(lat, lng),
      ]);

      final weather = results[0] as Map<String, dynamic>;
      final soil = results[1] as Map<String, dynamic>;

      return SoilClimateData(
        nitrogen: _soilValue(soil, 'nitrogen'),
        ph: _soilValue(soil, 'phh2o'),
        temperature: _numValue(weather['temperature']),
        humidity: _numValue(weather['humidity']),
        rainfall: _numValue(weather['rainfall']),
      );
    } catch (e) {
      return SoilClimateData(
        error: 'Could not fetch soil data: ${e.toString().replaceFirst("Exception: ", "")}',
      );
    }
  }

  static Future<Map<String, dynamic>> _fetchWeather(double lat, double lng) async {
    final uri = Uri.parse(_openMeteoUrl).replace(queryParameters: {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lng.toStringAsFixed(4),
      'current': 'temperature_2m,relative_humidity_2m,precipitation',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Weather API returned ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final current = body['current'] as Map<String, dynamic>?;

    return {
      'temperature': current?['temperature_2m'],
      'humidity': current?['relative_humidity_2m'],
      'rainfall': current?['precipitation'],
    };
  }

  static Future<Map<String, dynamic>> _fetchSoil(double lat, double lng) async {
    final uri = Uri.parse(_soilGridsUrl).replace(queryParameters: {
      'lon': lng.toStringAsFixed(4),
      'lat': lat.toStringAsFixed(4),
      'property': ['nitrogen', 'phh2o'],
      'depth': '0-5cm',
      'value': 'mean',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('SoilGrids API returned ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final layers = _dig(body, ['properties', 'layers']) as List? ?? [];

    final result = <String, double>{};

    for (final layer in layers) {
      if (layer is! Map) continue;
      final name = layer['name']?.toString();
      final depths = layer['depths'] as List? ?? [];
      if (name == null) continue;

      for (final depth in depths) {
        if (depth is! Map) continue;
        final values = depth['values'] as Map?;
        if (values == null) continue;
        final mean = values['mean'];
        if (mean is num) {
          if (name == 'nitrogen') {
            result[name] = (mean * 1000); // convert g/kg → mg/kg
          } else {
            result[name] = mean.toDouble();
          }
        }
        break;
      }
    }

    return result;
  }

  static double? _soilValue(Map<String, dynamic> soil, String key) {
    return soil[key]?.toDouble();
  }

  static double? _numValue(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static dynamic _dig(Map<String, dynamic> map, List<String> keys) {
    dynamic current = map;
    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
