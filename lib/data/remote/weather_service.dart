import 'package:dio/dio.dart';
import '../../core/config/env_config.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final double high;
  final double low;
  final double humidity;
  final double windSpeed;
  final String? description;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.high,
    required this.low,
    required this.humidity,
    required this.windSpeed,
    this.description,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>?;

    return WeatherData(
      temperature: (main['temp'] as num).toDouble() - 273.15, // Convert from Kelvin
      condition: weather['main'] as String,
      high: (main['temp_max'] as num).toDouble() - 273.15,
      low: (main['temp_min'] as num).toDouble() - 273.15,
      humidity: (main['humidity'] as num).toDouble(),
      windSpeed: (wind?['speed'] as num?)?.toDouble() ?? 0.0,
      description: weather['description'] as String?,
    );
  }
}

class WeatherService {
  final Dio _dio;

  WeatherService(this._dio);

  Future<Result<WeatherData>> getCurrentWeather({
    double? latitude,
    double? longitude,
    String? cityName,
  }) async {
    try {
      if (EnvConfig.weatherApiKey.isEmpty) {
        // Return mock data if API key not configured
        return Result.success(WeatherData(
          temperature: 24.0,
          condition: 'Sunny',
          high: 46.0,
          low: 52.0,
          humidity: 65.0,
          windSpeed: 2.0,
          description: 'Clear sky',
        ));
      }

      final queryParams = <String, dynamic>{
        'appid': EnvConfig.weatherApiKey,
        'units': 'metric',
      };

      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude;
        queryParams['lon'] = longitude;
      } else if (cityName != null) {
        queryParams['q'] = cityName;
      } else {
        // Default to a common location
        queryParams['q'] = 'Mumbai,IN';
      }

      final response = await _dio.get(
        '${EnvConfig.weatherApiUrl}/weather',
        queryParameters: queryParams,
      );

      final weatherData = WeatherData.fromJson(response.data);
      return Result.success(weatherData);
    } on DioException catch (e) {
      return Result.failure(
        Failure.network(message: e.message ?? 'Failed to fetch weather data'),
      );
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }

  Future<Result<List<WeatherData>>> getForecast({
    double? latitude,
    double? longitude,
    String? cityName,
    int days = 5,
  }) async {
    try {
      if (EnvConfig.weatherApiKey.isEmpty) {
        return Result.success([]);
      }

      final queryParams = <String, dynamic>{
        'appid': EnvConfig.weatherApiKey,
        'units': 'metric',
        'cnt': days * 8, // 8 forecasts per day (3-hour intervals)
      };

      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude;
        queryParams['lon'] = longitude;
      } else if (cityName != null) {
        queryParams['q'] = cityName;
      } else {
        queryParams['q'] = 'Mumbai,IN';
      }

      final response = await _dio.get(
        '${EnvConfig.weatherApiUrl}/forecast',
        queryParameters: queryParams,
      );

      final list = (response.data['list'] as List)
          .map((json) => WeatherData.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(list);
    } on DioException catch (e) {
      return Result.failure(
        Failure.network(message: e.message ?? 'Failed to fetch weather forecast'),
      );
    } catch (e) {
      return Result.failure(
        Failure.unknown(message: e.toString()),
      );
    }
  }
}

