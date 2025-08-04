// lib/ui/components/task_list.dart
import 'package:flutter/material.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today’s Tasks",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(
          children: const [
            _TaskItem(title: "Irrigation – Field A", time: "08:00 AM"),
            _TaskItem(title: "Spray – Field B", time: "10:30 AM"),
            _TaskItem(title: "Harvest – Field C", time: "04:00 PM"),
          ],
        ),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String time;

  const _TaskItem({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.agriculture_outlined, color: Colors.green),
        title: Text(title),
        subtitle: Text(time),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
