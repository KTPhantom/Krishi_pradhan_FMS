import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../data/services/api_service.dart';
import '../../core/utils/kml_processor.dart';
import 'field_detail_page.dart';

/// Field List Page — matches FarmERP HomeScreen (admin view).
/// Shows all fields with name, location, size.
/// Admins can add new fields via a bottom sheet with KML & multi-crop support.
class MyFieldsPage extends ConsumerStatefulWidget {
  const MyFieldsPage({super.key});

  @override
  ConsumerState<MyFieldsPage> createState() => _MyFieldsPageState();
}

class _MyFieldsPageState extends ConsumerState<MyFieldsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _fields = [];
  List<dynamic> _cropTypes = [];
  bool _loading = true;
  bool _hasError = false;

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
        _api.getFields(),
        _api.getCropTypes(),
      ]);
      setState(() {
        _fields = results[0];
        _cropTypes = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  // ─── KML FILE PICKER ────────────────────────────────────────
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
      return {
        'fileName': file.name,
        'content': content,
      };
    } catch (e) {
      return null;
    }
  }

  // ─── ADD FIELD SHEET (FarmERP HomeScreen flow) ───────────────
  void _showAddFieldSheet() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();

    // KML state
    String? kmlFileName;
    String? kmlContent;

    // Multi-crop list (FarmERP allows multiple crops before saving)
    List<Map<String, dynamic>> newCrops = [];

    // Temp crop form
    String? selectedCropTypeId;
    String selectedCropName = '';
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
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _handleBar(),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel',
                              style: TextStyle(fontSize: 17, color: Color(0xFF2563EB))),
                        ),
                        const Text('Add Field',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Field name is required')));
                              return;
                            }
                            final Map<String, dynamic> data = {
                              'name': name,
                              'location': locationCtrl.text.trim(),
                              'sizeAcres': sizeCtrl.text.trim(),
                              if (kmlFileName != null) 'kml_file_name': kmlFileName,
                              if (kmlContent != null) 'kml_content': kmlContent,
                              if (newCrops.isNotEmpty) 'crops': newCrops,
                            };
                            try {
                              await _api.createField(data);
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadData();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Error saving field: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Save',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Form
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── FIELD INFO SECTION ──
                        _sectionCard([
                          _inputRow('Field Name', nameCtrl, 'Enter name'),
                          _divider(),
                          // KML picker (FarmERP: Name → KML → Location)
                          GestureDetector(
                            onTap: () async {
                              final result = await _pickKmlFile();
                              if (result != null) {
                                final processed = KmlProcessor.processKml(result['content']);
                                setSheetState(() {
                                  kmlFileName = result['fileName'];
                                  kmlContent = result['content'];
                                  if (processed != null) {
                                    sizeCtrl.text = processed.calculatedArea.toString();
                                  }
                                });
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('KML loaded successfully')),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('KML', style: TextStyle(fontSize: 16)),
                                  Text(
                                    kmlFileName ?? 'Upload KML',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: kmlFileName != null
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _divider(),
                          _inputRow('Location', locationCtrl, 'e.g. North Block'),
                          _divider(),
                          _inputRow('Size (acres)', sizeCtrl, '0.0',
                              keyboard: TextInputType.number),
                        ]),

                        const SizedBox(height: 16),

                        // ── ADDED CROPS LIST (FarmERP multi-crop) ──
                        if (newCrops.isNotEmpty) ...[
                          _sectionHeader('ADDED CROPS (${newCrops.length})'),
                          const SizedBox(height: 8),
                          _sectionCard([
                            ...newCrops.asMap().entries.map((entry) {
                              final i = entry.key;
                              final c = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c['name']?.toString() ?? 'Crop',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${c['bedCount'] ?? 0} beds · ${c['plantSpacing'] ?? '0'}ft plant / ${c['bedSpacing'] ?? '0'}ft bed',
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          setSheetState(() => newCrops.removeAt(i)),
                                      child: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ]),
                          const SizedBox(height: 16),
                        ],

                        // ── CROP FORM SECTION ──
                        _sectionHeader('ADD CROP'),
                        const SizedBox(height: 8),
                        _sectionCard([
                          _pickerRow(
                            'Crop Type',
                            selectedCropName.isEmpty ? 'Select' : selectedCropName,
                            () {
                              _showPickerDialog(
                                ctx,
                                'Select Crop Type',
                                _cropTypes
                                    .map((c) => {
                                          'id': c['id'],
                                          'label': c['name']?.toString() ?? ''
                                        })
                                    .toList(),
                                (item) {
                                  setSheetState(() {
                                    selectedCropTypeId = item['id'];
                                    selectedCropName = item['label'] ?? '';
                                  });
                                },
                              );
                            },
                          ),
                          if (selectedCropTypeId != null) ...[
                            _divider(),
                            _inputRow('Plant Spacing (ft)', plantSpacingCtrl, '1.5',
                                keyboard: TextInputType.number),
                            _divider(),
                            _inputRow('Bed Spacing (ft)', bedSpacingCtrl, '4',
                                keyboard: TextInputType.number),
                            _divider(),
                            _inputRow('Number of Beds', bedCountCtrl, '0',
                                keyboard: TextInputType.number),
                            _divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Double Sided',
                                      style: TextStyle(fontSize: 16)),
                                  Switch(
                                    value: isDoubleSided,
                                    onChanged: (v) =>
                                        setSheetState(() => isDoubleSided = v),
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                            ),
                            if (isDoubleSided) ...[
                              _divider(),
                              _inputRow('Left Side (ft)', leftCtrl, '0',
                                  keyboard: TextInputType.number),
                              _divider(),
                              _inputRow('Right Side (ft)', rightCtrl, '0',
                                  keyboard: TextInputType.number),
                            ] else ...[
                              _divider(),
                              _inputRow('Bed Length (ft)', bedLengthCtrl, '0',
                                  keyboard: TextInputType.number),
                            ],
                          ],
                          // ── "ADD CROP TO LIST" always visible ──
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: GestureDetector(
                              onTap: () {
                                if (selectedCropTypeId == null) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                        content: Text('Please select a crop type first')));
                                  return;
                                }
                                setSheetState(() {
                                  newCrops.add({
                                    'id': const Uuid().v4(),
                                    'name': selectedCropName,
                                    'crop_type_id': selectedCropTypeId,
                                    'plantSpacing': plantSpacingCtrl.text.trim(),
                                    'bedSpacing': bedSpacingCtrl.text.trim(),
                                    'bedCount': bedCountCtrl.text.trim(),
                                    'bedLength': bedLengthCtrl.text.trim(),
                                    'isDoubleSided': isDoubleSided,
                                    'leftSide': leftCtrl.text.trim(),
                                    'rightSide': rightCtrl.text.trim(),
                                    'datePlanted': DateTime.now().toIso8601String().split('T')[0],
                                  });
                                  // Reset crop form
                                  selectedCropTypeId = null;
                                  selectedCropName = '';
                                  plantSpacingCtrl.clear();
                                  bedSpacingCtrl.clear();
                                  bedCountCtrl.clear();
                                  bedLengthCtrl.clear();
                                  isDoubleSided = false;
                                  leftCtrl.clear();
                                  rightCtrl.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: selectedCropTypeId != null
                                      ? const Color(0xFFDBEAFE)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text('+ Add Crop to List',
                                      style: TextStyle(
                                          color: selectedCropTypeId != null
                                              ? const Color(0xFF2563EB)
                                              : Colors.grey.shade400,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                ),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPickerDialog(BuildContext ctx, String title,
      List<Map<String, dynamic>> items, Function(Map<String, dynamic>) onSelect) {
    showModalBottomSheet(
      context: ctx,
      builder: (innerCtx) {
        return SafeArea(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAdmin = authState.isAdmin;

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
                  const Text('Farm Fields',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  if (isAdmin)
                    GestureDetector(
                      onTap: _showAddFieldSheet,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Admin / Worker toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 16,
                    color: isAdmin
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAdmin ? 'Admin View' : 'Worker View',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isAdmin
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Switch Role', style: TextStyle(fontSize: 12)),
                    onPressed: () =>
                        ref.read(authStateProvider.notifier).toggleRole(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Field List / Error / Loading
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: _fields.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height * 0.5,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.landscape_outlined,
                                                size: 64,
                                                color: Colors.grey.shade300),
                                            const SizedBox(height: 16),
                                            Text('No Fields Yet',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade400)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 8, 16, 100),
                                  itemCount: _fields.length,
                                  itemBuilder: (_, i) {
                                    final field = _fields[i];
                                    return _FieldCard(
                                      field: field,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                FieldDetailPage(field: field),
                                          ),
                                        );
                                        _loadData();
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

  // ─── ERROR STATE ──────────────────────────────────────────────
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
            const Text('Unable to Load Fields',
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

  // ─── HELPER WIDGETS ────────────────────────────────────────

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

  Widget _sectionHeader(String title) {
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
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _divider() {
    return Divider(
        height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200);
  }
}

class _FieldCard extends StatelessWidget {
  final Map<String, dynamic> field;
  final VoidCallback onTap;

  const _FieldCard({required this.field, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = field['name'] ?? 'Unnamed Field';
    final location = field['location'] ?? '';
    final size = field['size_acres'] ?? field['sizeAcres'] ?? 0;
    final hasKml = field['kml_content'] != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasKml
                    ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                    : const Color(0xFF6B7280).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasKml ? Icons.map : Icons.landscape_outlined,
                color: hasKml
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF6B7280),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.toString(),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (location.toString().isNotEmpty) location,
                      '$size acres',
                    ].join(' • '),
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFC7C7CC), size: 22),
          ],
        ),
      ),
    );
  }
}
