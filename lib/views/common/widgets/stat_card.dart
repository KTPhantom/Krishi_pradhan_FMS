// lib/ui/components/stat_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 24,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
