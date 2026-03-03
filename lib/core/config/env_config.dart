import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
class EnvConfig {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // If .env file fails to load (e.g., missing from asset bundle on device),
      // fall back to default values defined in the getters below.
      debugPrint('Warning: Failed to load .env file: $e');
    }
  }

  // API Configuration
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.farmverse.com/v1';
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  
  // Weather API
  static String get weatherApiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
  static String get weatherApiUrl => dotenv.env['WEATHER_API_URL'] ?? 'https://api.openweathermap.org/data/2.5';
  
  // Google Maps
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // Environment
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
}

