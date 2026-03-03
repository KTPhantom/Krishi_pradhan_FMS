import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/task_types.dart';
import '../../data/services/api_service.dart';

/// Task Detail Page — matches FarmERP TaskDetailScreen.
/// Shows task info, status toggle, edit, delete. (Materials skipped.)
class TaskDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;
  const TaskDetailPage({super.key, required this.task});

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _task;
  List<dynamic> _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _task = Map<String, dynamic>.from(widget.task);
    _loadPickerData();
  }

  Future<void> _loadPickerData() async {
    try {
      _users = await _api.getUsers();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  bool get _isCompleted => _task['status'] == 'completed';

  Future<void> _toggleStatus() async {
    final newStatus = _isCompleted ? 'pending' : 'completed';
    setState(() => _loading = true);
    try {
      await _api.updateTaskStatus(_task['id'], newStatus);
      setState(() {
        _task['status'] = newStatus;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showEditSheet() {
    String? selectedCategory = _task['category'];
    String? selectedSubtask = _task['subtask'];
    String? selectedWorkerId = _task['assignedTo'];
    String selectedWorkerName = _task['assignedToUsername']?.toString() ?? '';
    final descCtrl = TextEditingController(text: _task['description']?.toString() ?? '');
    DateTime? dueDate;
    if (_task['dueDate'] != null) {
      try {
        dueDate = DateTime.parse(_task['dueDate']);
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final subtasks = selectedCategory != null
              ? taskTypes[selectedCategory] ?? []
              : <String>[];

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _handleBar(),
                _sheetHeader(ctx, 'Edit Task', () async {
                  try {
                    final data = {
                      'description': descCtrl.text.trim(),
                      'category': selectedCategory,
                      'subtask': selectedSubtask,
                      if (selectedWorkerId != null) 'assignedTo': selectedWorkerId,
                      if (dueDate != null)
                        'dueDate': '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                    };
                    await _api.updateTask(_task['id'], data);
                    setState(() {
                      _task['description'] = descCtrl.text.trim();
                      _task['category'] = selectedCategory;
                      _task['subtask'] = selectedSubtask;
                      _task['assignedTo'] = selectedWorkerId;
                      _task['assignedToUsername'] = selectedWorkerName;
                      if (dueDate != null) {
                        _task['dueDate'] = '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}';
                      }
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionLabel('TASK TYPE'),
                      const SizedBox(height: 8),
                      _card([
                        _pickerRow(
                          'Category',
                          selectedCategory != null
                              ? formatTaskKey(selectedCategory!)
                              : 'Select',
                          () {
                            _showListPicker(
                              ctx,
                              'Select Category',
                              taskTypes.keys
                                  .where((k) => !materialTaskCategories.contains(k))
                                  .map((k) => {'id': k, 'label': formatTaskKey(k)})
                                  .toList(),
                              (item) {
                                setSheetState(() {
                                  selectedCategory = item['id'];
                                  selectedSubtask = null;
                                });
                              },
                            );
                          },
                        ),
                        if (subtasks.isNotEmpty) ...[
                          _div(),
                          _pickerRow(
                            'Sub-task',
                            selectedSubtask != null
                                ? formatTaskKey(selectedSubtask!)
                                : 'Select',
                            () {
                              _showListPicker(
                                ctx,
                                'Select Sub-task',
                                subtasks
                                    .map((s) =>
                                        {'id': s, 'label': formatTaskKey(s)})
                                    .toList(),
                                (item) {
                                  setSheetState(
                                      () => selectedSubtask = item['id']);
                                },
                              );
                            },
                          ),
                        ],
                      ]),
                      const SizedBox(height: 16),
                      _sectionLabel('DESCRIPTION'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Description...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionLabel('ASSIGNMENT'),
                      const SizedBox(height: 8),
                      _card([
                        _pickerRow(
                          'Worker',
                          selectedWorkerName.isEmpty
                              ? 'Select'
                              : selectedWorkerName,
                          () {
                            _showListPicker(
                              ctx,
                              'Select Worker',
                              _users.map((u) => {
                                    'id': u['id']?.toString() ?? '',
                                    'label': u['username']?.toString() ?? ''
                                  }).toList(),
                              (item) {
                                setSheetState(() {
                                  selectedWorkerId = item['id'];
                                  selectedWorkerName = item['label'] ?? '';
                                });
                              },
                            );
                          },
                        ),
                        _div(),
                        _datePickerRow(ctx, 'Due Date', dueDate, (d) {
                          setSheetState(() => dueDate = d);
                        }),
                      ]),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.deleteTask(_task['id']);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    final desc = _task['description']?.toString() ?? 'Task';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Task Detail',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                  if (isAdmin)
                    GestureDetector(
                      onTap: _showEditSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.edit,
                            size: 18, color: Color(0xFF2563EB)),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Task info card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: _isCompleted
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF2563EB),
                          width: 4,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isCompleted
                                ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                                : const Color(0xFFFBBF24).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isCompleted ? 'COMPLETED' : 'PENDING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _isCompleted
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFD97706),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Details
                  _sectionLabel('DETAILS'),
                  const SizedBox(height: 8),
                  _card([
                    _infoRow(Icons.calendar_today_outlined, 'Due Date',
                        _task['dueDate']?.toString() ?? 'N/A'),
                    _div(),
                    _infoRow(Icons.person_outline, 'Worker',
                        _task['assignedToUsername']?.toString() ?? 'Unassigned'),
                    _div(),
                    _infoRow(Icons.landscape_outlined, 'Field',
                        _task['fieldName']?.toString() ?? 'N/A'),
                    _div(),
                    _infoRow(Icons.eco_outlined, 'Crop',
                        _task['cropName']?.toString() ?? 'N/A'),
                  ]),
                  const SizedBox(height: 24),

                  // Toggle status button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _toggleStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCompleted
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isCompleted
                                  ? 'Mark as Pending'
                                  : 'Mark as Complete',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delete
                  if (isAdmin)
                    GestureDetector(
                      onTap: _deleteTask,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Text('Delete Task',
                                style: TextStyle(
                                    color: Colors.red.shade500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED WIDGETS ─────────────────────────────────────────

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(title,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.8)),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _div() {
    return Divider(
        height: 1, indent: 48, endIndent: 16, color: Colors.grey.shade200);
  }

  Widget _handleBar() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _sheetHeader(BuildContext ctx, String title, VoidCallback onSave) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 17, color: Color(0xFF2563EB))),
          ),
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: onSave,
            child: const Text('Save',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _pickerRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        color: value == 'Select'
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF2563EB))),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFF9CA3AF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerRow(BuildContext ctx, String label, DateTime? date,
      Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              date == null
                  ? 'Select'
                  : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 16,
                color: date == null
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showListPicker(BuildContext ctx, String title,
      List<Map<String, dynamic>> items, Function(Map<String, dynamic>) onSelect) {
    showModalBottomSheet(
      context: ctx,
      builder: (innerCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            ...items.map((item) => ListTile(
                  title: Text(item['label'] ?? ''),
                  onTap: () {
                    onSelect(item);
                    Navigator.pop(innerCtx);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
