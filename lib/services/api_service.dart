import 'package:agrimatketapp/config/api_config.dart';
import 'package:agrimatketapp/config/env_config.dart';
import 'package:agrimatketapp/data/agriai_metadata.dart';
import 'package:agrimatketapp/models/agriai_model.dart';
import 'package:agrimatketapp/models/farm_model.dart';
import 'package:agrimatketapp/models/product_model.dart';
import 'package:agrimatketapp/models/profile_model.dart';
import 'package:agrimatketapp/services/mistral_ai_service.dart';
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
    if (path.contains(ApiConfig.login) ||
        path.contains(ApiConfig.register) ||
        path.contains(ApiConfig.checkEmail)) {
      return false;
    }
    final token = await TokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Dio> _getDio() async {
    if (!_isInitialized) await _init();
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

  Future<Response> put(String endpoint, dynamic data) async {
    final client = await _getDio();
    return client.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) async {
    final client = await _getDio();
    return client.delete(endpoint);
  }

  // ?? Auth ????????????????????????????????????????????????????????????????

  Future<AuthResult> register(Map<String, dynamic> payload) async {
    try {
      final response = await post(ApiConfig.register, payload);
      return _parseAuthResponse(response);
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        message: _messageFromDio(e) ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  AuthResult _parseAuthResponse(Response response) {
    final data = response.data;
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data is Map<String, dynamic> &&
        data['success'] == true) {
      return AuthResult(
        success: true,
        statusCode: response.statusCode,
        raw: data,
      );
    }
    return AuthResult(
      success: false,
      statusCode: response.statusCode,
      message: _messageFromBody(data) ?? 'Request failed',
      raw: data is Map<String, dynamic> ? data : null,
    );
  }

  Future<void> logout() async {
    try {
      final client = await _getDio();
      await client.post(ApiConfig.logout);
    } catch (_) {
      // Clear local session even if logout fails.
    } finally {
      await TokenStorage.clear();
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return false;
    return getProfile() != null;
  }

  // ?? Profile ?????????????????????????????????????????????????????????????

  Future<UserProfile?> getProfile() async {
    try {
      final client = await _getDio();
      for (final endpoint in [ApiConfig.profile, ApiConfig.me]) {
        final response = await client.get(endpoint);
        final profile = _parseProfileResponse(response.data);
        if (profile != null) return profile;
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

  // ?? Products ????????????????????????????????????????????????????????????

  Future<ProductsListResult> fetchMyProducts({
    String? category,
    bool? available,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await getMyProducts(
        category: category,
        available: available,
        page: page,
        limit: limit,
      );
      final status = response.statusCode ?? 0;
      final body = response.data;

      if (status == 401) {
        return const ProductsListResult(
          success: false,
          message: 'Session expired. Please log in again.',
          unauthorized: true,
        );
      }

      if (status == 200 && body is Map<String, dynamic>) {
        final success = body['success'] == true || body['success'] == null;
        if (success) {
          return ProductsListResult(
            success: true,
            products: _parseProductsList(body['data']),
          );
        }
        return ProductsListResult(
          success: false,
          message: _messageFromBody(body) ?? 'Failed to load products',
        );
      }

      return ProductsListResult(
        success: false,
        message: _messageFromBody(body) ?? 'Failed to load products ($status)',
      );
    } catch (_) {
      return const ProductsListResult(
        success: false,
        message: 'Could not load your products. Check your connection.',
      );
    }
  }

  List<Product> _parseProductsList(dynamic raw) {
    if (raw is! List) return [];
    final products = <Product>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        try {
          products.add(Product.fromJson(item));
        } catch (_) {}
      }
    }
    return products;
  }

  bool _isProductMutationSuccess(Response response) {
    final status = response.statusCode ?? 0;
    if (status == 401) return false;
    if (status == 200 || status == 201) {
      final body = response.data;
      if (body is! Map) return true;
      return body['success'] != false;
    }
    return false;
  }

  Future<ProductMutationResult> createProductParsed(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await createProduct(data);
      if (response.statusCode == 401) {
        return const ProductMutationResult(
          success: false,
          message: 'Session expired. Please log in again.',
          unauthorized: true,
        );
      }
      if (_isProductMutationSuccess(response)) {
        return const ProductMutationResult(success: true);
      }
      return ProductMutationResult(
        success: false,
        message: _messageFromBody(response.data) ?? 'Failed to add product',
      );
    } catch (e) {
      return ProductMutationResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<ProductMutationResult> updateProductParsed(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await updateProduct(id, data);
      if (response.statusCode == 401) {
        return const ProductMutationResult(
          success: false,
          message: 'Session expired. Please log in again.',
          unauthorized: true,
        );
      }
      if (_isProductMutationSuccess(response)) {
        return const ProductMutationResult(success: true);
      }
      return ProductMutationResult(
        success: false,
        message: _messageFromBody(response.data) ?? 'Failed to update product',
      );
    } catch (e) {
      return ProductMutationResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
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

  Future<ProductsListResult> fetchProducts({
    String? category,
    bool? available,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await getProducts(
        category: category,
        available: available,
        page: page,
        limit: limit,
      );
      final status = response.statusCode ?? 0;
      final body = response.data;

      if (status == 401) {
        return const ProductsListResult(
          success: false,
          message: 'Session expired. Please log in again.',
          unauthorized: true,
        );
      }

      if (status == 200 && body is Map<String, dynamic>) {
        final success = body['success'] == true || body['success'] == null;
        if (success) {
          return ProductsListResult(
            success: true,
            products: _parseProductsList(body['data']),
          );
        }
        return ProductsListResult(
          success: false,
          message: _messageFromBody(body) ?? 'Failed to load products',
        );
      }

      return ProductsListResult(
        success: false,
        message: _messageFromBody(body) ?? 'Failed to load products ($status)',
      );
    } catch (_) {
      return const ProductsListResult(
        success: false,
        message: 'Could not load products. Check your connection.',
      );
    }
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

  Future<Response> createProduct(Map<String, dynamic> data) async {
    return post(ApiConfig.products, data);
  }

  Future<Response> updateProduct(String id, Map<String, dynamic> data) async {
    return put('${ApiConfig.products}/$id', data);
  }

  Future<Response> deleteProduct(String id) async {
    return delete('${ApiConfig.products}/$id');
  }

  // ?? Farms ???????????????????????????????????????????????????????????????

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
        return FarmsListResult(success: true, farms: []);
      }

      return FarmsListResult(
        success: false,
        message: _messageFromBody(response.data) ?? 'Failed to load farms',
      );
    } catch (_) {
      return FarmsListResult(
        success: false,
        message: 'Could not connect. Pull to refresh.',
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
      return FarmMutationResult(
        success: false,
        message: 'Network error. Please try again.',
      );
    }
  }

  // ?? AgriAI ????????????????????????????????????????????????????????????

  /// Crop recommendations via Mistral AI (.env) or backend AgriAI fallback.
  Future<Map<String, dynamic>> recommendCrop(Map<String, dynamic> payload) async {
    if (EnvConfig.useMistralAi) {
      return MistralAiService().recommendCrop(payload);
    }
    final response = await post(ApiConfig.recommendCrop, payload);
    final data = _unwrapData(response);
    if (data != null) return data;
    throw Exception(_errorMessage(response, 'Failed to get crop recommendation'));
  }

  /// Used by crop insights screen ? default soil/weather values.
  Future<AgriAIRecommendResult> recommendCropWithDefaults({
    int nitrogen = 50,
    int phosphorus = 30,
    int potassium = 20,
    double temperature = 25,
    double humidity = 60,
    double ph = 6.5,
    double rainfall = 100,
    String soilColor = 'brown',
    String? region,
  }) async {
    try {
      final data = await recommendCrop({
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'ph': ph,
        'rainfall': rainfall,
        'soil_color': soilColor,
        if (region != null && region.isNotEmpty) 'region': region,
      });
      final list = <CropRecommendationItem>[];
      final recs = data['recommendations'];
      if (recs is List) {
        for (final item in recs) {
          if (item is Map<String, dynamic>) {
            list.add(CropRecommendationItem.fromJson(item));
          }
        }
      }
      return AgriAIRecommendResult(success: true, recommendations: list);
    } catch (e) {
      return AgriAIRecommendResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Map<String, dynamic>> predictPrice(Map<String, dynamic> payload) async {
    if (EnvConfig.useMistralAi) {
      return MistralAiService().predictPrice(payload);
    }
    final response = await post(ApiConfig.predictPrice, payload);
    final data = _unwrapData(response);
    if (data != null) return data;
    throw Exception(_errorMessage(response, 'Failed to get price forecast'));
  }

  Future<AgriAIPriceResult> predictCropPrice({
    required String cropName,
    required String region,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    try {
      final data = await predictPrice({
        'crop_name': cropName,
        'region': region,
        'year': year ?? now.year,
        'month': month ?? now.month,
      });
      return AgriAIPriceResult(
        success: true,
        forecast: CropPriceForecast.fromJson(data),
      );
    } catch (e) {
      return AgriAIPriceResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<Map<String, dynamic>> getPriceForecasterMetadata() async {
    if (EnvConfig.useMistralAi) {
      return AgriAiMetadata.toMap();
    }
    final response = await get(ApiConfig.priceForecasterMetadata);
    final data = _unwrapData(response);
    if (data != null) return data;
    throw Exception(_errorMessage(response, 'Failed to load forecast options'));
  }

  // ?? Helpers ?????????????????????????????????????????????????????????????

  Map<String, dynamic>? _unwrapData(Response response) {
    if (response.statusCode != 200) return null;
    final body = response.data;
    if (body is! Map<String, dynamic>) return null;
    if (body['success'] != true) return null;
    final data = body['data'];
    return data is Map<String, dynamic> ? data : null;
  }

  String _errorMessage(Response response, String fallback) {
    return _messageFromBody(response.data) ?? fallback;
  }

  String? _messageFromBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString();
    }
    return null;
  }

  String? _messageFromDio(DioException e) {
    return _messageFromBody(e.response?.data);
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? raw;

  const AuthResult({
    required this.success,
    this.message,
    this.statusCode,
    this.raw,
  });
}

class FarmsListResult {
  final bool success;
  final List<Farm> farms;
  final String? message;

  FarmsListResult({
    required this.success,
    this.farms = const [],
    this.message,
  });
}

class FarmMutationResult {
  final bool success;
  final String? message;

  FarmMutationResult({required this.success, this.message});
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

class AgriAIRecommendResult {
  final bool success;
  final String? message;
  final List<CropRecommendationItem> recommendations;

  const AgriAIRecommendResult({
    required this.success,
    this.message,
    this.recommendations = const [],
  });
}

class AgriAIPriceResult {
  final bool success;
  final String? message;
  final CropPriceForecast? forecast;

  const AgriAIPriceResult({
    required this.success,
    this.message,
    this.forecast,
  });
}

class ProductsListResult {
  final bool success;
  final List<Product> products;
  final String? message;
  final bool unauthorized;

  const ProductsListResult({
    required this.success,
    this.products = const [],
    this.message,
    this.unauthorized = false,
  });
}

class ProductMutationResult {
  final bool success;
  final String? message;
  final bool unauthorized;

  const ProductMutationResult({
    required this.success,
    this.message,
    this.unauthorized = false,
  });
}
