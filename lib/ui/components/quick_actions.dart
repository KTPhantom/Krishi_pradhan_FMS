// lib/ui/components/quick_actions.dart
import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _ActionButton(icon: Icons.add_task, label: 'Add Task'),
        _ActionButton(icon: Icons.currency_rupee, label: 'Add Expense'),
        _ActionButton(icon: Icons.calendar_today, label: 'Calendar'),
        _ActionButton(icon: Icons.mic, label: 'Voice'),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
