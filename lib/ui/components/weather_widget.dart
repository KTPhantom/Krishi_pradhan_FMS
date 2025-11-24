// lib/ui/components/weather_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../presentation/providers/weather_provider.dart';
import '../../data/services/weather_service.dart';

class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsyncValue = ref.watch(weatherProvider);

    return weatherAsyncValue.when(
      data: (weather) => _buildWeatherCard(weather),
      loading: () => _buildLoadingCard(),
      error: (err, stack) => _buildErrorCard(err.toString()),
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade100.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${weather.temperature.toStringAsFixed(0)}°C",
                style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                weather.condition,
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.black54),
              ),
              Text(
                "H:${weather.high.toStringAsFixed(0)}°C  L:${weather.low.toStringAsFixed(0)}°C",
                style: GoogleFonts.nunito(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
          _getWeatherIcon(weather.condition),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          "Weather unavailable",
          style: GoogleFonts.nunito(color: Colors.red.shade300),
        ),
      ),
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;
    Color color;

    final conditionLower = condition.toLowerCase();
    if (conditionLower.contains('cloud')) {
      iconData = Icons.cloud;
      color = Colors.grey;
    } else if (conditionLower.contains('rain')) {
      iconData = Icons.water_drop;
      color = Colors.blue;
    } else if (conditionLower.contains('clear') || conditionLower.contains('sun')) {
      iconData = Icons.wb_sunny_rounded;
      color = Colors.orangeAccent;
    } else if (conditionLower.contains('snow')) {
      iconData = Icons.ac_unit;
      color = Colors.lightBlueAccent;
    } else if (conditionLower.contains('thunder')) {
      iconData = Icons.flash_on;
      color = Colors.amber;
    } else {
      iconData = Icons.wb_sunny_rounded;
      color = Colors.orangeAccent;
    }

    return Icon(iconData, size: 42, color: color);
  }
}
