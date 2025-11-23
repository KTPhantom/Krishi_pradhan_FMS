class ApiConstants {
  // Base URLs - will be replaced with environment variables
  static const String baseUrl = 'https://api.farmverse.com/v1';
  
  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  
  static const String products = '/products';
  static const String productById = '/products';
  
  static const String fields = '/fields';
  static const String fieldById = '/fields';
  
  static const String tasks = '/tasks';
  static const String taskById = '/tasks';
  
  static const String transactions = '/transactions';
  static const String orders = '/orders';
  
  static const String weather = '/weather';
  static const String userProfile = '/user/profile';
  
  // Headers
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}

