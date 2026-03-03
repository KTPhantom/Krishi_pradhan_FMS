import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../data/services/api_service.dart';
import '../../core/utils/kml_processor.dart';
import 'crop_detail_page.dart';

/// Field Detail Page — matches FarmERP DetailScreen.
/// Shows field overview, crop list, tasks, edit/delete.
class FieldDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> field;
  const FieldDetailPage({super.key, required this.field});

  @override
  ConsumerState<FieldDetailPage> createState() => _FieldDetailPageState();
}

class _FieldDetailPageState extends ConsumerState<FieldDetailPage> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _field;
  List<dynamic> _crops = [];
  List<dynamic> _tasks = [];
  List<dynamic> _cropTypes = [];
  bool _loading = true;
  bool _hasError = false;
  String _taskFilter = 'pending'; // 'pending' or 'all'

  @override
  void initState() {
    super.initState();
    _field = Map<String, dynamic>.from(widget.field);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final fieldId = _field['id'];
      final results = await Future.wait([
        _api.getCropsForField(fieldId),
        _api.getTasks(),
        _api.getCropTypes(),
      ]);
      setState(() {
        _crops = results[0];
        _tasks = results[1]
            .where((t) => t['fieldId'] == fieldId)
            .toList();
        _cropTypes = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<Map<String, String>?> _pickKmlFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;
      if (file.bytes == null) return null;
      final content = utf8.decode(file.bytes!);
      return {'fileName': file.name, 'content': content};
    } catch (e) {
      return null;
    }
  }

  List<dynamic> get _filteredTasks {
    if (_taskFilter == 'pending') {
      return _tasks.where((t) => t['status'] != 'completed').toList();
    }
    return _tasks;
  }

  void _showAddCropSheet() {
    String? selectedTypeId;
    String selectedTypeName = '';
    final plantSpacingCtrl = TextEditingController();
    final bedSpacingCtrl = TextEditingController();
    final bedCountCtrl = TextEditingController();
    final bedLengthCtrl = TextEditingController();
    bool isDoubleSided = false;
    final leftCtrl = TextEditingController();
    final rightCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _handleBar(),
              _sheetHeader(ctx, 'Add Crop', () async {
                if (selectedTypeId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please select a crop type')));
                  return;
                }
                final data = {
                  'id': const Uuid().v4(),
                  'fieldId': _field['id'],
                  'name': selectedTypeName,
                  'crop_type_id': selectedTypeId,
                  'plantSpacing': plantSpacingCtrl.text.trim(),
                  'bedSpacing': bedSpacingCtrl.text.trim(),
                  'bedCount': bedCountCtrl.text.trim(),
                  'bedLength': bedLengthCtrl.text.trim(),
                  'isDoubleSided': isDoubleSided,
                  'leftSide': leftCtrl.text.trim(),
                  'rightSide': rightCtrl.text.trim(),
                  'datePlanted': DateTime.now().toIso8601String().split('T')[0],
                };
                try {
                  await _api.createCrop(data);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
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
                    _sectionCard([
                      _pickerRow('Crop Type',
                          selectedTypeName.isEmpty ? 'Select' : selectedTypeName,
                          () {
                        _showPicker(ctx, 'Select Crop Type',
                            _cropTypes.map((c) => {'id': c['id'], 'label': c['name']?.toString() ?? ''}).toList(),
                            (item) {
                          setSheetState(() {
                            selectedTypeId = item['id'];
                            selectedTypeName = item['label'] ?? '';
                          });
                        });
                      }),
                      if (selectedTypeId != null) ...[
                        _div(),
                        _inputRow('Plant Spacing', plantSpacingCtrl, '1.5 ft',
                            keyboard: TextInputType.number),
                        _div(),
                        _inputRow('Bed Spacing', bedSpacingCtrl, '4 ft',
                            keyboard: TextInputType.number),
                        _div(),
                        _inputRow('Beds', bedCountCtrl, '0',
                            keyboard: TextInputType.number),
                        _div(),
                        _switchRow('Double Sided', isDoubleSided, (v) {
                          setSheetState(() => isDoubleSided = v);
                        }),
                        if (isDoubleSided) ...[
                          _div(),
                          _inputRow('Left (ft)', leftCtrl, '0',
                              keyboard: TextInputType.number),
                          _div(),
                          _inputRow('Right (ft)', rightCtrl, '0',
                              keyboard: TextInputType.number),
                        ] else ...[
                          _div(),
                          _inputRow('Bed Length', bedLengthCtrl, '0 ft',
                              keyboard: TextInputType.number),
                        ],
                      ],
                    ]),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showEditFieldSheet() {
    final nameCtrl = TextEditingController(text: _field['name']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: _field['location']?.toString() ?? '');
    final sizeCtrl = TextEditingController(
        text: (_field['size_acres'] ?? _field['sizeAcres'] ?? '').toString());
    String? editKmlFileName = _field['kml_file_name']?.toString();
    String? editKmlContent = _field['kml_content']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _handleBar(),
              _sheetHeader(ctx, 'Edit Field', () async {
                try {
                  await _api.updateField(_field['id'], {
                    'name': nameCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'sizeAcres': sizeCtrl.text.trim(),
                    'kml_file_name': editKmlFileName,
                    'kml_content': editKmlContent,
                  });
                  setState(() {
                    _field['name'] = nameCtrl.text.trim();
                    _field['location'] = locationCtrl.text.trim();
                    _field['kml_file_name'] = editKmlFileName;
                    _field['kml_content'] = editKmlContent;
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
                    _sectionCard([
                      _inputRow('Name', nameCtrl, 'Field name'),
                      _div(),
                      // KML picker row (matching FarmERP EditField)
                      GestureDetector(
                        onTap: () async {
                          final result = await _pickKmlFile();
                          if (result != null) {
                            final processed = KmlProcessor.processKml(result['content']);
                            setSheetState(() {
                              editKmlFileName = result['fileName'];
                              editKmlContent = result['content'];
                              if (processed != null) {
                                sizeCtrl.text = processed.calculatedArea.toString();
                              }
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Upload KML', style: TextStyle(fontSize: 16)),
                              Flexible(
                                child: editKmlFileName != null
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.description, size: 14, color: Color(0xFF3B82F6)),
                                            const SizedBox(width: 4),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 100),
                                              child: Text(editKmlFileName!,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 14, color: Color(0xFF3B82F6))),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text('Replace',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                                          ],
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.upload_file, size: 16, color: Colors.grey.shade400),
                                          const SizedBox(width: 4),
                                          const Text('Upload KML',
                                              style: TextStyle(fontSize: 16, color: Color(0xFF2563EB))),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _div(),
                      _inputRow('Location', locationCtrl, 'Location'),
                      _div(),
                      _inputRow('Size (acres)', sizeCtrl, '0',
                          keyboard: TextInputType.number),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteField() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Field'),
        content: const Text(
            'This will delete the field and all associated crops and tasks. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.deleteField(_field['id']);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _showTaskDetail(Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['description'] ?? 'Task',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow(Icons.calendar_today, 'Due Date',
                task['dueDate']?.toString() ?? 'N/A'),
            _detailRow(Icons.person_outline, 'Assigned To',
                task['assignedToUsername']?.toString() ?? 'N/A'),
            _detailRow(Icons.location_on_outlined, 'Field',
                task['fieldName']?.toString() ?? 'N/A'),
            _detailRow(Icons.eco_outlined, 'Crop',
                task['cropName']?.toString() ?? 'N/A'),
            _detailRow(
                task['status'] == 'completed'
                    ? Icons.check_circle
                    : Icons.access_time,
                'Status',
                task['status']?.toString().toUpperCase() ?? 'PENDING'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authStateProvider).isAdmin;
    final name = _field['name'] ?? 'Field';
    final location = _field['location'] ?? '';
    final size = _field['size_acres'] ?? _field['sizeAcres'] ?? 0;

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
                  Expanded(
                    child: Text(name.toString(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                  if (isAdmin) ...[
                    GestureDetector(
                      onTap: _showEditFieldSheet,
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
                ],
              ),
            ),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? _buildErrorState()
                      : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Overview (with KML info)
                          _buildSection('OVERVIEW', [
                            _listTile(Icons.location_on_outlined,
                                'Location', location.toString().isEmpty ? 'N/A' : location.toString()),
                            _listTile(Icons.square_foot,
                                'Size', '$size acres'),
                            _listTile(
                                _field['kml_content'] != null ? Icons.map : Icons.map_outlined,
                                'KML',
                                _field['kml_file_name']?.toString() ?? 'No KML'),
                          ]),
                          const SizedBox(height: 16),

                          // Crops
                          _buildSectionWithAction(
                            'CROP TYPES (${_crops.length})',
                            isAdmin
                                ? GestureDetector(
                                    onTap: _showAddCropSheet,
                                    child: const Icon(Icons.add_circle_outline,
                                        size: 20, color: Color(0xFF2563EB)),
                                  )
                                : null,
                            _crops.isEmpty
                                ? [
                                    _emptyState(
                                        Icons.eco_outlined, 'No crops yet')
                                  ]
                                : _crops
                                    .map((crop) => _cropTile(crop))
                                    .toList(),
                          ),
                          const SizedBox(height: 16),

                          // Tasks
                          _buildSectionWithAction(
                            'TASKS',
                            null,
                            [
                              // Filter tabs
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 12, 16, 8),
                                child: Row(
                                  children: [
                                    _filterChip('Pending',
                                        _taskFilter == 'pending', () {
                                      setState(
                                          () => _taskFilter = 'pending');
                                    }),
                                    const SizedBox(width: 8),
                                    _filterChip(
                                        'All', _taskFilter == 'all', () {
                                      setState(() => _taskFilter = 'all');
                                    }),
                                  ],
                                ),
                              ),
                              if (_filteredTasks.isEmpty)
                                _emptyState(Icons.task_alt, 'No tasks')
                              else
                                ..._filteredTasks
                                    .map((task) => _taskTile(task)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Delete
                          if (isAdmin)
                            GestureDetector(
                              onTap: _deleteField,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.red.shade100),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        color: Colors.red.shade400),
                                    const SizedBox(width: 8),
                                    Text('Delete Field',
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
            ),
          ],
        ),
      ),
    );
  }

  // ─── UI HELPERS ─────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSectionWithAction(
      String title, Widget? action, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8)),
              if (action != null) action,
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _listTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }

  Widget _cropTile(Map<String, dynamic> crop) {
    final cropName = crop['name'] ?? 'Crop';
    final beds = crop['numberOfBeds'] ?? crop['number_of_beds'] ?? 0;
    final isDouble = crop['isDoubleSided'] == 1 || crop['isDoubleSided'] == true;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CropDetailPage(crop: crop)),
        );
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, size: 18, color: Color(0xFF16A34A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cropName.toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('$beds beds${isDouble ? ' • Double sided' : ''}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _taskTile(Map<String, dynamic> task) {
    final isCompleted = task['status'] == 'completed';
    return GestureDetector(
      onTap: () => _showTaskDetail(task),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: isCompleted
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFD1D5DB),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['description']?.toString() ?? 'Task',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  Text(
                    '${task['cropName'] ?? ''} • ${task['dueDate'] ?? ''}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _emptyState(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─── SHEET HELPERS ──────────────────────────────────────────

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
            const Text('Unable to Load Data',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(
              'Check your connection or server status.',
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
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600)),
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

  Widget _sectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _inputRow(String label, TextEditingController ctrl, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
              ),
            ),
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
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      color: value == 'Select'
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF2563EB))),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _div() {
    return Divider(
        height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200);
  }

  void _showPicker(BuildContext ctx, String title,
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
