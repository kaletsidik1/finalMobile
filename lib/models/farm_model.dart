class Farm {
  final String id;
  final String name;
  final String? description;
  final String? size;
  final String? sizeUnit;
  final String? region;
  final String? woreda;
  final String? kebele;
  final double? latitude;
  final double? longitude;
  final String? soilType;
  final String? soilColor;
  final String? waterSource;
  final List<String> crops;
  final bool isActive;
  final String farmerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Farm({
    required this.id,
    required this.name,
    this.description,
    this.size,
    this.sizeUnit,
    this.region,
    this.woreda,
    this.kebele,
    this.latitude,
    this.longitude,
    this.soilType,
    this.soilColor,
    this.waterSource,
    this.crops = const [],
    this.isActive = true,
    this.farmerId = '',
    this.createdAt,
    this.updatedAt,
  });

  String get locationLabel {
    final parts = <String>[
      if (kebele != null && kebele!.isNotEmpty) kebele!,
      if (woreda != null && woreda!.isNotEmpty) woreda!,
      if (region != null && region!.isNotEmpty) region!,
    ];
    return parts.isEmpty ? 'Location not set' : parts.join(', ');
  }

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      size: json['size']?.toString(),
      sizeUnit: json['sizeUnit']?.toString(),
      region: json['region']?.toString(),
      woreda: json['woreda']?.toString(),
      kebele: json['kebele']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      soilType: json['soilType']?.toString(),
      soilColor: json['soilColor']?.toString(),
      waterSource: json['waterSource']?.toString(),
      crops: _parseStringList(json['crops']),
      isActive: json['isActive'] == true || json['isActive'] == null,
      farmerId: json['farmerId']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
