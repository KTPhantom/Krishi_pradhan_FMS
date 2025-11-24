import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // You might need to add this package to your pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String selectedCrop = 'Spinach';
  late DateTime selectedDate;

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

  // key: crop, value: map of ISO date -> list of task maps
  Map<String, Map<String, List<Map<String, String>>>> persistedCropTasks = {};

  @override
  void initState() {
    super.initState();
    // Initialize selectedDate to today's date (no time)
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    _loadPersistedTasks();
  }

  Future<void> _loadPersistedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('calendar_tasks_v1');
    if (raw == null) return;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final Map<String, Map<String, List<Map<String, String>>>> parsed = {};
      for (final cropEntry in decoded.entries) {
        final dateMapDynamic = cropEntry.value as Map<String, dynamic>;
        final Map<String, List<Map<String, String>>> dateMap = {};
        for (final dateEntry in dateMapDynamic.entries) {
          final listDynamic = dateEntry.value as List<dynamic>;
          dateMap[dateEntry.key] = listDynamic
              .map((e) => Map<String, String>.from(e as Map))
              .toList();
        }
        parsed[cropEntry.key] = dateMap;
      }
      setState(() {
        persistedCropTasks = parsed;
      });
    } catch (_) {
      // ignore parse errors silently
    }
  }

  Future<void> _persistTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendar_tasks_v1', json.encode(persistedCropTasks));
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<Map<String, String>> _tasksFor(String crop, DateTime date) {
    final defaults = cropSchedules[crop] ?? const [];
    final savedForDate = persistedCropTasks[crop]?[_dateKey(date)] ?? const [];
    // Merge defaults first, then saved tasks appended
    return [...defaults, ...savedForDate];
  }

  Future<void> _showAddTaskDialog() async {
    TimeOfDay? pickedTime;
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    String formatTime(TimeOfDay t) {
      final dt = DateTime(0, 1, 1, t.hour, t.minute);
      return DateFormat('HH:mm').format(dt);
    }

    try {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Add Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final now = TimeOfDay.now();
                          final res = await showTimePicker(
                            context: context,
                            initialTime: now,
                          );
                          if (res != null) {
                            setState(() {
                              pickedTime = res;
                            });
                          }
                        },
                        child: Text(pickedTime == null
                            ? 'Pick time'
                            : formatTime(pickedTime!)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (pickedTime == null || titleController.text.trim().isEmpty) {
                    return;
                  }
                  final task = {
                    'time': formatTime(pickedTime!),
                    'title': titleController.text.trim(),
                    'subtitle': subtitleController.text.trim(),
                  };
                  final cropMap = persistedCropTasks[selectedCrop] ?? {};
                  final dateKey = _dateKey(selectedDate);
                  final existing = List<Map<String, String>>.from(cropMap[dateKey] ?? []);
                  existing.add(task);
                  cropMap[dateKey] = existing;
                  setState(() {
                    persistedCropTasks[selectedCrop] = cropMap;
                  });
                  await _persistTasks();
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    } finally {
      // Dispose controllers to prevent memory leaks
      titleController.dispose();
      subtitleController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasksFor(selectedCrop, selectedDate);
    // Calculate the start of the week (Monday)
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    // Get current day index (0 for Monday, 6 for Sunday)
    final currentDayIndex = selectedDate.weekday - 1;

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
            // Wrap the row in a SingleChildScrollView or adjust flex to avoid overflow on small screens
            // But Row with Flexible children usually handles it well if flex is used correctly
            // RenderFlex overflow happens if children take more than available width
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final dayDate = startOfWeek.add(Duration(days: index));
                final dayName = DateFormat('E').format(dayDate); // Short day name e.g., "Mon"
                final dateNumber = DateFormat('d').format(dayDate); // Day number e.g., "16"
                final isSelected = index == currentDayIndex;

                return Flexible(
                  fit: FlexFit.tight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        selectedDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
                      });
                    },
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
                                    ? Colors.white // Corrected color for selected date number
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              )),
                        )
                      ],
                    ),
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
                  // Check if dark mode is needed based on the card color logic
                  // The original code set text color to white if 'dark' is true
                  // But for general dark mode support, we should check Theme.of(context).brightness
                  final bool isCardDark = task['title']!.contains('Spray') || task['title']!.contains('Weed');
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TaskTile(
                      time: task['time']!,
                      title: task['title']!,
                      subtitle: task['subtitle']!,
                      color: isCardDark
                          ? Colors.green
                          : Colors.white,
                      dark: isCardDark,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Raised to avoid being hidden by dock
        child: FloatingActionButton(
          onPressed: _showAddTaskDialog,
          backgroundColor: Colors.green,
          child: const Icon(Icons.add, color: Colors.white),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isCardDark = dark || isDarkMode;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(time,
              style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w500, 
                  color: isDarkMode ? Colors.white70 : Colors.black54)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? color : (isDarkMode ? Colors.grey[800] : color),
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
                        color: isCardDark ? Colors.white : Colors.black)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: isCardDark ? Colors.white70 : Colors.grey.shade700)),
              ],
            ),
          ),
        )
      ],
    );
  }
}
