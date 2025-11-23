import 'package:flutter/material.dart';

/// Enhanced data card with icons, progress indicators, and better visual hierarchy
class EnhancedDataCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color iconColor;
  final double? progress; // For percentage values (0-100)
  final VoidCallback? onTap;

  const EnhancedDataCard({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.iconColor,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                if (progress != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(progress!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(progress!),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(progress!),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress! / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(progress!),
                  ),
                  minHeight: 4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(double value) {
    if (value >= 80) return 'Excellent';
    if (value >= 60) return 'Good';
    return 'Needs Attention';
  }
}

