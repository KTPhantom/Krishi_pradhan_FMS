// lib/ui/components/weather_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
              Text("24°C", style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Sunny", style: GoogleFonts.nunito(fontSize: 16, color: Colors.black54)),
              Text("H:46°C  L:52°C", style: GoogleFonts.nunito(fontSize: 12, color: Colors.black45)),
            ],
          ),
          const Icon(Icons.wb_sunny_rounded, size: 42, color: Colors.orangeAccent),
        ],
      ),
    );
  }
}
