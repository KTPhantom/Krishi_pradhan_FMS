import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/task_types.dart';
import '../../data/services/api_service.dart';
import 'task_detail_page.dart';

/// Task List Page — matches FarmERP TaskListScreen.
/// Shows task list with pending/all filter, create task bottom sheet.
class TaskManagementPage extends ConsumerStatefulWidget {
  const TaskManagementPage({super.key});

  @override
  ConsumerState<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends ConsumerState<TaskManagementPage> {
  final ApiService _api = ApiService();
  List<dynamic> _tasks = [];
  List<dynamic> _fields = [];
  List<dynamic> _crops = [];
  List<dynamic> _users = [];
  bool _loading = true;
  bool _hasError = false;
  String _filter = 'pending'; // 'pending' or 'all'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _api.getTasks(),
        _api.getFields(),
        _api.getAllCrops(),
        _api.getUsers(),
      ]);
      setState(() {
        _tasks = results[0];
        _fields = results[1];
        _crops = results[2];
        _users = results[3];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  List<dynamic> get _filteredTasks {
    final authState = ref.read(authStateProvider);
    List<dynamic> tasks = _tasks;

    // Workers only see their tasks
    if (!authState.isAdmin) {
      tasks = tasks.where((t) => t['assignedTo'] == authState.userId).toList();
    }

    if (_filter == 'pending') {
      return tasks.where((t) => t['status'] != 'completed').toList();
    }
    return tasks;
  }

  void _showCreateTaskSheet() {
    String? selectedCategory;
    String? selectedSubtask;
    List<String> selectedCropIds = [];
    List<String> selectedFieldIds = [];
    String? selectedWorkerId;
    String selectedWorkerName = '';
    DateTime? dueDate;
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final subtasks = selectedCategory != null
              ? taskTypes[selectedCategory] ?? []
              : <String>[];

          // Filter fields by selected crops
          final availableFields = selectedCropIds.isEmpty
              ? _fields
              : _fields.where((f) {
                  return _crops.any(
                      (c) => c['fieldId'] == f['id'] && selectedCropIds.contains(c['id']));
                }).toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _handleBar(),
                _sheetHeader(ctx, 'Assign Task', () async {
                  if (selectedCategory == null) return;
                  final desc = descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : '${formatTaskKey(selectedCategory!)}${selectedSubtask != null ? ' - ${formatTaskKey(selectedSubtask!)}' : ''}';

                  for (final cropId in selectedCropIds.isEmpty ? [''] : selectedCropIds) {
                    for (final fieldId in selectedFieldIds.isEmpty ? [''] : selectedFieldIds) {
                      final data = {
                        'id': const Uuid().v4(),
                        'description': desc,
                        'category': selectedCategory,
                        'subtask': selectedSubtask,
                        'status': 'pending',
                        if (cropId.isNotEmpty) 'cropId': cropId,
                        if (fieldId.isNotEmpty) 'fieldId': fieldId,
                        if (selectedWorkerId != null) 'assignedTo': selectedWorkerId,
                        if (dueDate != null)
                          'dueDate': '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                      };
                      try {
                        await _api.createTask(data);
                      } catch (_) {}
                    }
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                }),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Category
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
                          _divider(),
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
                                    .map((s) => {'id': s, 'label': formatTaskKey(s)})
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

                      // Description
                      _sectionLabel('DESCRIPTION (optional)'),
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
                            hintText: 'Optional description...',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Crop selection
                      _sectionLabel('CROP'),
                      const SizedBox(height: 8),
                      _card([
                        _multiSelectRow(
                          'Crops',
                          selectedCropIds.isEmpty
                              ? 'Select'
                              : '${selectedCropIds.length} selected',
                          () {
                            _showMultiSelect(
                              ctx,
                              'Select Crops',
                              _crops
                                  .map((c) => {
                                        'id': c['id']?.toString() ?? '',
                                        'label': c['name']?.toString() ?? ''
                                      })
                                  .toList(),
                              selectedCropIds,
                              (ids) {
                                setSheetState(() => selectedCropIds = ids);
                              },
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Field selection
                      _sectionLabel('FIELD'),
                      const SizedBox(height: 8),
                      _card([
                        _multiSelectRow(
                          'Fields',
                          selectedFieldIds.isEmpty
                              ? 'Select'
                              : '${selectedFieldIds.length} selected',
                          () {
                            _showMultiSelect(
                              ctx,
                              'Select Fields',
                              availableFields
                                  .map((f) => {
                                        'id': f['id']?.toString() ?? '',
                                        'label': f['name']?.toString() ?? ''
                                      })
                                  .toList(),
                              selectedFieldIds,
                              (ids) {
                                setSheetState(() => selectedFieldIds = ids);
                              },
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Worker + Due Date
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
                              _users
                                  .map((u) => {
                                        'id': u['id']?.toString() ?? '',
                                        'label': u['username']?.toString() ?? ''
                                      })
                                  .toList(),
                              (item) {
                                setSheetState(() {
                                  selectedWorkerId = item['id'];
                                  selectedWorkerName = item['label'] ?? '';
                                });
                              },
                            );
                          },
                        ),
                        _divider(),
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

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tasks',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  if (isAdmin)
                    GestureDetector(
                      onTap: _showCreateTaskSheet,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  _filterChip('Pending', _filter == 'pending', () {
                    setState(() => _filter = 'pending');
                  }),
                  const SizedBox(width: 8),
                  _filterChip('All Tasks', _filter == 'all', () {
                    setState(() => _filter = 'all');
                  }),
                  const Spacer(),
                  // Role indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                          : const Color(0xFF16A34A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : 'Worker',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Task list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? _buildErrorState()
                      : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _filteredTasks.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.task_alt,
                                              size: 64,
                                              color: Colors.grey.shade300),
                                          const SizedBox(height: 16),
                                          Text(
                                            _filter == 'pending'
                                                ? 'No Pending Tasks'
                                                : 'No Tasks',
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade400),
                                          ),
                                        ],
                                      ),
                                    )),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 100),
                              itemCount: _filteredTasks.length,
                              itemBuilder: (_, i) {
                                final task = _filteredTasks[i];
                                return _TaskCard(
                                  task: task,
                                  isAdmin: isAdmin,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskDetailPage(task: task),
                                      ),
                                    );
                                    _loadData();
                                  },
                                  onDelete: () async {
                                    try {
                                      await _api.deleteTask(task['id']);
                                      _loadData();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')));
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ERROR STATE ──────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  size: 48, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            const Text('Unable to Load Tasks',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection or make sure the server is running.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED WIDGETS ─────────────────────────────────────────

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

  Widget _multiSelectRow(String label, String value, VoidCallback onTap) {
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

  Widget _divider() {
    return Divider(
        height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200);
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF6B7280))),
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

  void _showMultiSelect(BuildContext ctx, String title,
      List<Map<String, dynamic>> items, List<String> selected,
      Function(List<String>) onDone) {
    final localSelected = List<String>.from(selected);

    showModalBottomSheet(
      context: ctx,
      builder: (innerCtx) => StatefulBuilder(
        builder: (innerCtx, setInnerState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(innerCtx),
                      child: const Text('Cancel'),
                    ),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () {
                        onDone(localSelected);
                        Navigator.pop(innerCtx);
                      },
                      child: const Text('Done',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB))),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...items.map((item) {
                final isSelected = localSelected.contains(item['id']);
                return ListTile(
                  title: Text(item['label'] ?? ''),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: Color(0xFF2563EB))
                      : const Icon(Icons.radio_button_unchecked,
                          color: Color(0xFFD1D5DB)),
                  onTap: () {
                    setInnerState(() {
                      if (isSelected) {
                        localSelected.remove(item['id']);
                      } else {
                        localSelected.add(item['id']!);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task['status'] == 'completed';
    final desc = task['description']?.toString() ?? 'Task';
    final fieldName = task['fieldName']?.toString() ?? '';
    final cropName = task['cropName']?.toString() ?? '';
    final sub = [
      if (fieldName.isNotEmpty) fieldName,
      if (cropName.isNotEmpty) cropName,
    ].join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isCompleted
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFD1D5DB),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(desc,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF1F2937),
                      )),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (isAdmin)
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close,
                    size: 18, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}
