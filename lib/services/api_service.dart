import 'package:agrimatketapp/config/api_config.dart';
import 'package:agrimatketapp/models/farm_model.dart';
import 'package:agrimatketapp/models/profile_model.dart';
import 'package:agrimatketapp/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio dio;
  bool _isInitialized = false;

  ApiService._internal() {
    _init();
  }

  Future<void> _init() async {
    if (_isInitialized) return;

    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    if (kIsWeb) {
      dio.options.extra['withCredentials'] = true;
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (await _shouldAttachToken(options.path)) {
          final token = await TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        if (kDebugMode) {
          // ignore: avoid_print
          print('REQUEST: ${options.method} ${options.uri}');
        }

        return handler.next(options);
      },
    ));

    _isInitialized = true;
  }

  Future<bool> _shouldAttachToken(String path) async {
    if (path.contains(ApiConfig.login)) return false;

    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return false;

    if (await TokenStorage.isFarmer()) return true;

    return path.contains(ApiConfig.profile) ||
        path.contains(ApiConfig.me) ||
        path.contains(ApiConfig.updatePassword) ||
        path.contains(ApiConfig.logout);
  }

  Future<Dio> _getDio() async {
    if (!_isInitialized) {
      await _init();
    }
    return dio;
  }

  Future<Response> post(String endpoint, dynamic data) async {
    final client = await _getDio();
    return client.post(endpoint, data: data);
  }

  Future<Response> get(String endpoint) async {
    final client = await _getDio();
    return client.get(endpoint);
  }

  Future<Response> getMyProducts({
    String? category,
    bool? available,
    int page = 1,
    int limit = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (available != null) {
      params['available'] = available.toString();
    }

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return get('${ApiConfig.myProducts}?$query');
  }

  Future<Response> getProducts({
    String? category,
    bool? available,
    int page = 1,
    int limit = 10,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (available != null) {
      params['available'] = available.toString();
    }

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return get('${ApiConfig.products}?$query');
  }

  Future<Response> put(String endpoint, dynamic data) async {
    final client = await _getDio();
    return client.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) async {
    final client = await _getDio();
    return client.delete(endpoint);
  }

  Future<Response> createProduct(Map<String, dynamic> data) async {
    return post(ApiConfig.products, data);
  }

  Future<Response> updateProduct(String id, Map<String, dynamic> data) async {
    return put('${ApiConfig.products}/$id', data);
  }

  Future<Response> deleteProduct(String id) async {
    return delete('${ApiConfig.products}/$id');
  }

  Future<void> logout() async {
    try {
      final client = await _getDio();
      await client.post(ApiConfig.logout);
    } catch (_) {
      // Still clear local session even if logout request fails.
    } finally {
      await TokenStorage.clear();
    }
  }

  Future<UserProfile?> getProfile() async {
    try {
      final client = await _getDio();
      for (final endpoint in [ApiConfig.me, ApiConfig.profile]) {
        final response = await client.get(endpoint);
        if (response.statusCode == 200) {
          final profile = _parseProfileResponse(response.data);
          if (profile != null) return profile;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  UserProfile? _parseProfileResponse(dynamic data) {
    if (data is! Map<String, dynamic> || data['success'] != true) {
      return null;
    }
    final user = data['user'] ?? data['data'];
    if (user is Map<String, dynamic>) {
      return UserProfile.fromJson(user);
    }
    return null;
  }

  Future<ProfileMutationResult> updateProfile(Map<String, dynamic> payload) async {
    try {
      final response = await put(ApiConfig.profile, payload);
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        final user = data['data'];
        if (user is Map<String, dynamic>) {
          final profile = UserProfile.fromJson(user);
          if (profile.name.isNotEmpty) {
            await TokenStorage.saveUserName(profile.name);
          }
          final subtitle = profile.displaySubtitle;
          if (subtitle.isNotEmpty) {
            await TokenStorage.saveFarmSubtitle(subtitle);
          }
          return ProfileMutationResult(
            success: true,
            profile: profile,
            message: 'Profile updated',
          );
        }
        return const ProfileMutationResult(success: true, message: 'Profile updated');
      }
      return ProfileMutationResult(
        success: false,
        message: _messageFromBody(data) ?? 'Failed to update profile',
      );
    } catch (_) {
      return const ProfileMutationResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<ProfileMutationResult> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await put(ApiConfig.updatePassword, {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        return ProfileMutationResult(
          success: true,
          message: data['message']?.toString() ?? 'Password updated',
        );
      }
      return ProfileMutationResult(
        success: false,
        message: _messageFromBody(data) ?? 'Failed to update password',
      );
    } catch (_) {
      return const ProfileMutationResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return false;
    return (await getProfile()) != null;
  }

  Map<String, dynamic>? _unwrapData(Response response) {
    if (response.statusCode != 200) return null;
    final body = response.data;
    if (body is! Map<String, dynamic>) return null;
    if (body['success'] != true) return null;
    final data = body['data'];
    return data is Map<String, dynamic> ? data : null;
  }

  String _errorMessage(Response response, String fallback) {
    final body = response.data;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    return fallback;
  }

  Future<Map<String, dynamic>> recommendCrop(Map<String, dynamic> payload) async {
    final response = await post(ApiConfig.recommendCrop, payload);
    final data = _unwrapData(response);
    if (data != null) return data;
    throw Exception(_errorMessage(response, 'Failed to get crop recommendation'));
  }

  Future<Map<String, dynamic>> predictPrice(Map<String, dynamic> payload) async {
    final response = await post(ApiConfig.predictPrice, payload);
    final data = _unwrapData(response);
    if (data != null) return data;
    throw Exception(_errorMessage(response, 'Failed to get price forecast'));
  }

  Future<Map<String, dynamic>> getPriceForecasterMetadata() async {
    final response = await get(ApiConfig.priceForecasterMetadata);
    final data = _unwrapData(response);
    if (data != null) return data;
    throw Exception(_errorMessage(response, 'Failed to load forecast options'));
  }

  List<Farm> _extractFarmsFromResponse(dynamic data) {
    final farms = <Farm>[];
    dynamic raw = data;
    if (data is Map<String, dynamic>) {
      raw = data['data'] ?? data['farms'];
    }
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          farms.add(Farm.fromJson(item));
        }
      }
    }
    return farms;
  }

  Future<FarmsListResult> getFarms() async {
    try {
      final response = await get(ApiConfig.farms);
      final status = response.statusCode ?? 0;

      if (status == 200) {
        return FarmsListResult(
          success: true,
          farms: _extractFarmsFromResponse(response.data),
        );
      }

      if (status == 404) {
        return const FarmsListResult(success: true, farms: []);
      }

      return FarmsListResult(
        success: false,
        message: _messageFromBody(response.data) ?? 'Failed to load farms',
      );
    } catch (_) {
      return const FarmsListResult(
        success: false,
        message: 'Could not connect. Pull to refresh.',
      );
    }
  }

  Future<CropRecommendResult> getCropRecommendations({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
    String? soilColor,
  }) async {
    try {
      final response = await post(ApiConfig.recommendCrop, {
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'ph': ph,
        'rainfall': rainfall,
        if (soilColor != null && soilColor.isNotEmpty) 'soil_color': soilColor,
      });
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        final payload = data['data'];
        final recommendations = <CropRecommendationItem>[];
        if (payload is Map<String, dynamic>) {
          final raw = payload['recommendations'];
          if (raw is List) {
            for (final item in raw) {
              if (item is Map<String, dynamic>) {
                recommendations.add(CropRecommendationItem.fromJson(item));
              }
            }
          }
        }
        return CropRecommendResult(success: true, recommendations: recommendations);
      }
      return CropRecommendResult(
        success: false,
        message: _messageFromBody(data) ?? 'Failed to get recommendations',
      );
    } catch (_) {
      return const CropRecommendResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  Future<FarmMutationResult> createFarm(Map<String, dynamic> payload) async {
    try {
      final response = await post(ApiConfig.farms, payload);
      final data = response.data;
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data is Map<String, dynamic> && data['success'] == true) {
          return FarmMutationResult(
            success: true,
            message: data['message']?.toString(),
          );
        }
      }
      return FarmMutationResult(
        success: false,
        message: _messageFromBody(data) ?? 'Failed to create farm',
      );
    } catch (_) {
      return const FarmMutationResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  String? _messageFromBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString();
    }
    return null;
  }
}

class FarmsListResult {
  final bool success;
  final List<Farm> farms;
  final String? message;

  const FarmsListResult({
    required this.success,
    this.farms = const [],
    this.message,
  });
}

class FarmMutationResult {
  final bool success;
  final String? message;

  const FarmMutationResult({required this.success, this.message});
}

class CropRecommendationItem {
  final String crop;
  final double confidence;

  const CropRecommendationItem({required this.crop, required this.confidence});

  factory CropRecommendationItem.fromJson(Map<String, dynamic> json) {
    final confRaw = json['confidence'];
    final confidence = confRaw is num
        ? confRaw.toDouble()
        : double.tryParse(confRaw?.toString() ?? '') ?? 0;
    return CropRecommendationItem(
      crop: json['crop']?.toString() ?? '',
      confidence: confidence,
    );
  }
}

class CropRecommendResult {
  final bool success;
  final List<CropRecommendationItem> recommendations;
  final String? message;

  const CropRecommendResult({
    required this.success,
    this.recommendations = const [],
    this.message,
  });
}

class ProfileMutationResult {
  final bool success;
  final String? message;
  final UserProfile? profile;

  const ProfileMutationResult({
    required this.success,
    this.message,
    this.profile,
  });
}
