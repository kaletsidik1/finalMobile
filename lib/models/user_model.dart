enum UserRole { farmer, trader }

class BaseUser {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String region;
  final String woreda;

  BaseUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.region,
    required this.woreda,
  });
}

class Farmer extends BaseUser {
  final String farmLocation;
  final double farmSize;
  final List<String> crops;
  final String experience; // Beginner, Intermediate, Advanced, Expert

  Farmer({
    required super.name,
    required super.email,
    required super.phone,
    required super.password,
    required super.region,
    required super.woreda,
    required this.farmLocation,
    required this.farmSize,
    required this.crops,
    required this.experience,
  });
}

class Trader extends BaseUser {
  final String tinNumber; // Tax Identification Number

  Trader({
    required super.name,
    required super.email,
    required super.phone,
    required super.password,
    required super.region,
    required super.woreda,
    required this.tinNumber,
  });
}