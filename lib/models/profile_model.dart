class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? region;
  final String? woreda;
  final String? farmLocation;
  final double? farmSize;
  final String? tinNumber;
  final String? avatarUrl;

  const UserProfile({
    this.id = '',
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.region,
    this.woreda,
    this.farmLocation,
    this.farmSize,
    this.tinNumber,
    this.avatarUrl,
  });

  bool get isTrader => role.toLowerCase() == 'trader';
  bool get isFarmer => role.toLowerCase() == 'farmer';

  String get displaySubtitle {
    if (isFarmer) {
      return farmLocation ?? [woreda, region].where((v) => v != null && v.isNotEmpty).join(', ');
    }
    return [woreda, region].where((v) => v != null && v.isNotEmpty).join(', ');
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString(),
      region: json['region']?.toString(),
      woreda: json['woreda']?.toString(),
      farmLocation: json['farmLocation']?.toString(),
      farmSize: _parseDouble(json['farmSize']),
      tinNumber: json['tinNumber']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ??
          json['avatar']?.toString() ??
          json['profileImage']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
