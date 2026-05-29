class ProductFarmer {
  final String id;
  final String name;
  final String? phone;
  final String? region;
  final String? woreda;

  ProductFarmer({
    required this.id,
    required this.name,
    this.phone,
    this.region,
    this.woreda,
  });

  factory ProductFarmer.fromJson(Map<String, dynamic> json) {
    return ProductFarmer(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown farmer',
      phone: json['phone'],
      region: json['region'],
      woreda: json['woreda'],
    );
  }
}

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String unit;
  final String category;
  final int stock;
  final List<String> images;
  final String location;
  final bool isOrganic;
  final String harvestDate;
  final String? expiryDate;
  final String farmerId;
  final bool isAvailable;
  final ProductFarmer? farmer;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.stock,
    required this.images,
    required this.location,
    required this.isOrganic,
    required this.harvestDate,
    this.expiryDate,
    required this.farmerId,
    this.isAvailable = true,
    this.farmer,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
  // Safe parser for num/double values
  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Handle string that might be "12" or "12.5"
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Safe parser for int values
  int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  return Product(
    id: json['id'] ?? json['_id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'],
    price: parseDouble(json['price']),  // ← FIXED: handles String and num
    unit: json['unit'] ?? 'KG',
    category: json['category'] ?? '',
    stock: parseInt(json['stock']),     // ← FIXED: handles String and num
    images: json['images'] != null ? List<String>.from(json['images']) : [],
    location: json['location'] ?? '',
    isOrganic: json['isOrganic'] ?? false,
    harvestDate: json['harvestDate'] ?? '',
    expiryDate: json['expiryDate'],
    farmerId: json['farmerId'] ?? '',
    isAvailable: json['isAvailable'] ?? true,
    farmer: json['farmer'] != null
        ? ProductFarmer.fromJson(json['farmer'] as Map<String, dynamic>)
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'category': category,
      'stock': stock,
      'images': images,
      'location': location,
      'isOrganic': isOrganic,
      'harvestDate': harvestDate,
      'expiryDate': expiryDate,
    };
  }

  /// Payload for POST /products (farmer create product).
  Map<String, dynamic> toCreateJson() {
    final payload = <String, dynamic>{
      'name': name,
      'price': price,
      'unit': unit,
      'category': category,
      'stock': stock,
      'images': images,
      'location': location,
      'isOrganic': isOrganic,
      'harvestDate': harvestDate,
    };

    if (description != null && description!.trim().isNotEmpty) {
      payload['description'] = description!.trim();
    }
    if (expiryDate != null && expiryDate!.trim().isNotEmpty) {
      payload['expiryDate'] = expiryDate;
    }

    return payload;
  }

  /// Payload for PUT /products/:id (farmer update product).
  Map<String, dynamic> toUpdateJson() => toCreateJson();
}

// Mock products for marketplace
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'White Teff',
    description: 'High quality white teff grain',
    price: 4800,
    unit: 'KG',
    category: 'GRAINS',
    stock: 25,
    images: ['assets/images/teff_product.jpg'],
    location: 'Ada\'a, Oromia',
    isOrganic: true,
    harvestDate: '2024-12-15',
    farmerId: 'f1',
  ),
  Product(
    id: '2',
    name: 'Arabica Coffee',
    description: 'Premium arabica coffee beans',
    price: 12500,
    unit: 'KG',
    category: 'BEVERAGES',
    stock: 12,
    images: ['assets/images/coffee_product.jpg'],
    location: 'Yirgacheffe, SNNPR',
    isOrganic: true,
    harvestDate: '2024-11-20',
    farmerId: 'f2',
  ),
  Product(
    id: '3',
    name: 'Maize',
    description: 'Fresh maize crop',
    price: 2900,
    unit: 'KG',
    category: 'GRAINS',
    stock: 50,
    images: ['assets/images/maize_product.jpg'],
    location: 'Bako, Oromia',
    isOrganic: false,
    harvestDate: '2024-10-10',
    farmerId: 'f3',
  ),
];
