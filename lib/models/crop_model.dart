class Crop {
  final String name;
  final String imageUrl;
  final double profitMargin; // percentage
  final double avgPricePerQuintal;
  final String season;
  final String region;
  final bool isRecommended;

  Crop({
    required this.name,
    required this.imageUrl,
    required this.profitMargin,
    required this.avgPricePerQuintal,
    required this.season,
    required this.region,
    this.isRecommended = false,
  });
}

// Mock data for top profitable crops
final List<Crop> topProfitableCrops = [
  Crop(
    name: 'Teff (White)',
    imageUrl: 'assets/images/teff.jpg',
    profitMargin: 35.5,
    avgPricePerQuintal: 4500,
    season: 'Meher',
    region: 'All Regions',
    isRecommended: true,
  ),
  Crop(
    name: 'Coffee (Arabica)',
    imageUrl: 'assets/images/coffee.jpg',
    profitMargin: 42.0,
    avgPricePerQuintal: 12000,
    season: 'Year Round',
    region: 'Oromia, SNNPR',
    isRecommended: true,
  ),
  Crop(
    name: 'Maize (Hybrid)',
    imageUrl: 'assets/images/maize.jpg',
    profitMargin: 28.5,
    avgPricePerQuintal: 2800,
    season: 'Belg',
    region: 'All Regions',
    isRecommended: false,
  ),
  Crop(
    name: 'Sesame',
    imageUrl: 'assets/images/sesame.jpg',
    profitMargin: 38.0,
    avgPricePerQuintal: 6500,
    season: 'Meher',
    region: 'Amhara, Tigray',
    isRecommended: true,
  ),
  Crop(
    name: 'Haricot Beans',
    imageUrl: 'assets/images/beans.jpg',
    profitMargin: 32.0,
    avgPricePerQuintal: 3800,
    season: 'Belg',
    region: 'Oromia, Amhara',
    isRecommended: false,
  ),
];