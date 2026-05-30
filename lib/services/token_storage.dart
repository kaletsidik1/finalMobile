import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _userNameKey = 'user_name';
  static const _farmSubtitleKey = 'farm_subtitle';
  static const _farmerLatKey = 'farmer_lat';
  static const _farmerLngKey = 'farmer_lng';
  static const _readNotificationsKey = 'read_notification_ids';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<bool> isFarmer() async {
    final role = await getRole();
    return role?.toLowerCase() == 'farmer';
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name.trim());
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> saveFarmSubtitle(String subtitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_farmSubtitleKey, subtitle.trim());
  }

  static Future<String?> getFarmSubtitle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_farmSubtitleKey);
  }

  static Future<void> saveFarmerLocation({
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_farmerLatKey, lat);
    await prefs.setDouble(_farmerLngKey, lng);
  }

  static Future<(double? lat, double? lng)> getFarmerLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_farmerLatKey), prefs.getDouble(_farmerLngKey));
  }

  static Future<Set<String>> getReadNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readNotificationsKey) ?? const []).toSet();
  }

  static Future<void> markNotificationRead(String id) async {
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_readNotificationsKey) ?? [];
    if (!ids.contains(id)) {
      ids.add(id);
      await prefs.setStringList(_readNotificationsKey, ids);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_farmSubtitleKey);
    await prefs.remove(_farmerLatKey);
    await prefs.remove(_farmerLngKey);
    await prefs.remove(_readNotificationsKey);
  }
}
