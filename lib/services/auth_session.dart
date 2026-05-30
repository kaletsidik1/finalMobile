import 'token_storage.dart';

class AuthSession {
  AuthSession._();

  static String? extractToken(Map<String, dynamic> data) {
    final direct = data['token'] ??
        data['accessToken'] ??
        data['access_token'] ??
        data['jwt'];

    if (direct != null && direct.toString().isNotEmpty) {
      return direct.toString();
    }

    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      return extractToken(nested);
    }

    return null;
  }

  static String? extractRole(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map<String, dynamic> && user['role'] != null) {
      return user['role'].toString();
    }
    if (data['role'] != null) {
      return data['role'].toString();
    }
    return null;
  }

  static String? extractName(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map<String, dynamic> && user['name'] != null) {
      return user['name'].toString();
    }
    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      final nestedUser = nested['user'];
      if (nestedUser is Map<String, dynamic> && nestedUser['name'] != null) {
        return nestedUser['name'].toString();
      }
      if (nested['name'] != null) {
        return nested['name'].toString();
      }
    }
    if (data['name'] != null) {
      return data['name'].toString();
    }
    return null;
  }

  static String? extractFarmSubtitle(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      final location = user['farmLocation']?.toString();
      if (location != null && location.isNotEmpty) return location;
      final parts = [user['woreda'], user['region']]
          .whereType<String>()
          .where((v) => v.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
      final region = user['region']?.toString();
      final woreda = user['woreda']?.toString();
      final farmSize = user['farmSize']?.toString();
      final combined = [woreda, region, farmSize]
          .where((v) => v != null && v.isNotEmpty)
          .join(' • ');
      if (combined.isNotEmpty) return combined;
    }
    return null;
  }

  static Future<void> saveFromLoginResponse(Map<String, dynamic> data) async {
    final token = extractToken(data);
    if (token != null) {
      await TokenStorage.saveToken(token);
    }

    final role = extractRole(data);
    if (role != null) {
      await TokenStorage.saveRole(role);
    }

    final name = extractName(data);
    if (name != null && name.isNotEmpty) {
      await TokenStorage.saveUserName(name);
    }

    final farmSubtitle = extractFarmSubtitle(data);
    if (farmSubtitle != null && farmSubtitle.isNotEmpty) {
      await TokenStorage.saveFarmSubtitle(farmSubtitle);
    }
  }
}
