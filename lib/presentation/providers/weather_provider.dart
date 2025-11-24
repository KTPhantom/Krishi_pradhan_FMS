import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/services/weather_service.dart';
import '../../core/utils/result.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  final dio = ref.watch(dioProvider);
  return WeatherService(dio);
});

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  final result = await service.getCurrentWeather();
  
  return result.when(
    success: (weather) => weather,
    failure: (_) => WeatherData(
      temperature: 24.0,
      condition: 'Sunny',
      high: 46.0,
      low: 52.0,
      humidity: 65.0,
      windSpeed: 2.0,
    ),
  );
});

