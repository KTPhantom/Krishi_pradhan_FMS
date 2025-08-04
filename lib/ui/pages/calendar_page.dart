import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // You might need to add this package to your pubspec.yaml

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String selectedCrop = 'Spinach';

  final List<String> cropList = ['Spinach', 'Tomato', 'Wheat', 'Rice'];

  final Map<String, List<Map<String, String>>> cropSchedules = {
    'Spinach': [
      {"time": "08:00", "title": "Irrigation", "subtitle": "Spinach Garden 08"},
      {
        "time": "10:30",
        "title": "Spray Pesticide",
        "subtitle": "Avoid direct sunlight"
      },
      {
        "time": "13:00",
        "title": "Field Inspection",
        "subtitle": "Check for pest damage"
      },
      {"time": "15:00", "title": "Record Keeping", "subtitle": "Update farm log"},
      {"time": "17:30", "title": "Tool Maintenance", "subtitle": "Clean and store tools"},
    ],
    'Tomato': [
      {
        "time": "07:00",
        "title": "Fertilizer Application",
        "subtitle": "Use NPK 10-10-10"
      },
      {
        "time": "11:00",
        "title": "Leaf Curl Check",
        "subtitle": "Look for whiteflies"
      },
    ],
    'Wheat': [
      {"time": "06:30", "title": "Seed Drill Check", "subtitle": "Plot 14"},
      {
        "time": "12:00",
        "title": "Weed Management",
        "subtitle": "Use safe herbicides"
      },
    ],
    'Rice': [
      {
        "time": "08:30",
        "title": "Paddy Water Level",
        "subtitle": "Maintain 2cm standing water"
      },
      {"time": "13:45", "title": "Manual Weed Removal", "subtitle": "Plot B1"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final tasks = cropSchedules[selectedCrop] ?? [];
    final now = DateTime.now();
    // Calculate the start of the week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // Get current day index (0 for Monday, 6 for Sunday)
    final currentDayIndex = now.weekday - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text("Schedule for $selectedCrop",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCrop,
                    borderRadius: BorderRadius.circular(12),
                    items: cropList
                        .map((crop) => DropdownMenuItem(
                              value: crop,
                              child: Text(crop, style: TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCrop = value);
                      }
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final dayDate = startOfWeek.add(Duration(days: index));
                final dayName = DateFormat('E').format(dayDate); // Short day name e.g., "Mon"
                final dateNumber = DateFormat('d').format(dayDate); // Day number e.g., "16"
                final isSelected = index == currentDayIndex;

                return Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    children: [
                      Text(dayName,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: isSelected ? Colors.black : Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(dateNumber,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            )),
                      )
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TaskTile(
                      time: task['time']!,
                      title: task['title']!,
                      subtitle: task['subtitle']!,
                      color: task['title']!.contains('Spray') ||
                              task['title']!.contains('Weed')
                          ? Colors.green
                          : Colors.white,
                      dark: task['title']!.contains('Spray') ||
                          task['title']!.contains('Weed'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final Color color;
  final bool dark;

  const _TaskTile({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.color,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(time,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
               boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 0.5,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: dark ? Colors.white70 : Colors.grey.shade700)),
              ],
            ),
          ),
        )
      ],
    );
  }
}
