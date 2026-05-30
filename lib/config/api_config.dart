class ApiConfig {
  ApiConfig._();

  static const baseUrl = 'https://agrimarket-gc00.onrender.com/api';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const checkEmail = '/auth/check-email';
  static const logout = '/auth/logout';
  static const me = '/auth/me';

  // User
  static const profile = '/user/profile';
  static const updatePassword = '/user/password';

  // Products
  static const products = '/products';
  static const myProducts = '/products/my-products';

  // Farms
  static const farms = '/farms';
  static String farm(String id) => '$farms/$id';

  // AgriAI
  static const recommendCrop = '/agriai/recommend/crop';
  static const predictPrice = '/agriai/predict/price';
  static const priceForecasterMetadata = '/agriai/price-forecaster/metadata';
}
