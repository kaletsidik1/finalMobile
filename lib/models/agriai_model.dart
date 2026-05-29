class CropRecommendationItem {
  final String crop;
  final String confidence;

  CropRecommendationItem({
    required this.crop,
    required this.confidence,
  });

  factory CropRecommendationItem.fromJson(Map<String, dynamic> json) {
    return CropRecommendationItem(
      crop: json['crop']?.toString() ?? 'Unknown',
      confidence: json['confidence']?.toString() ?? '0',
    );
  }

  double? get confidencePercent {
    final value = double.tryParse(confidence);
    if (value == null) return null;
    return value <= 1 ? value * 100 : value;
  }
}

class CropPriceForecast {
  final String cropName;
  final String region;
  final int year;
  final int month;
  final double predictedPrice;
  final String trend;
  final double trendPercentage;

  CropPriceForecast({
    required this.cropName,
    required this.region,
    required this.year,
    required this.month,
    required this.predictedPrice,
    required this.trend,
    required this.trendPercentage,
  });

  factory CropPriceForecast.fromJson(Map<String, dynamic> json) {
    return CropPriceForecast(
      cropName: json['crop_name']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      predictedPrice: (json['predicted_price'] as num?)?.toDouble() ?? 0,
      trend: json['trend']?.toString() ?? 'stable',
      trendPercentage: (json['trend_percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}
