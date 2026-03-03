import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../data/services/api_service.dart';

/// Crop Detail Page — matches FarmERP CropDetailScreen.
/// Shows crop overview, configuration, edit, delete.
class CropDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> crop;
  const CropDetailPage({super.key, required this.crop});

  @override
  ConsumerState<CropDetailPage> createState() => _CropDetailPageState();
}

class _CropDetailPageState extends ConsumerState<CropDetailPage> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _crop;
  List<dynamic> _cropTypes = [];

  @override
  void initState() {
    super.initState();
    _crop = Map<String, dynamic>.from(widget.crop);
    _loadCropTypes();
  }

  Future<void> _loadCropTypes() async {
    try {
      _cropTypes = await _api.getCropTypes();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  String _val(String key, {String fallback = 'N/A'}) {
    final v = _crop[key];
    if (v == null || v.toString().isEmpty || v.toString() == '0') return fallback;
    return v.toString();
  }

  bool get _isDouble =>
      _crop['isDoubleSided'] == 1 || _crop['isDoubleSided'] == true;

  void _showEditSheet() {
    final cropTypes = _cropTypes;
    String? selectedTypeId = _crop['crop_type_id']?.toString();
    String selectedTypeName = _crop['name']?.toString() ?? '';
    final plantSpCtrl = TextEditingController(text: _val('plantSpacing', fallback: ''));
    final bedSpCtrl = TextEditingController(text: _val('bedSpacing', fallback: ''));
    final bedCountCtrl = TextEditingController(
        text: (_crop['numberOfBeds'] ?? _crop['number_of_beds'] ?? '').toString());
    final bedLenCtrl = TextEditingController(text: _val('bedLength', fallback: ''));
    bool isDouble = _isDouble;
    final leftCtrl = TextEditingController(
        text: (_crop['leftSideLength'] ?? _crop['left_side_length'] ?? '').toString());
    final rightCtrl = TextEditingController(
        text: (_crop['rightSideLength'] ?? _crop['right_side_length'] ?? '').toString());
    final datePlantedCtrl = TextEditingController(
        text: _crop['datePlanted']?.toString() ?? '');
    final harvestDateCtrl = TextEditingController(
        text: _crop['harvestDate']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _handleBar(),
              _sheetHeader(ctx, 'Edit Crop', () async {
                try {
                  await _api.updateCrop(_crop['id'], {
                    'name': selectedTypeName,
                    'crop_type_id': selectedTypeId,
                    'datePlanted': datePlantedCtrl.text.trim().isEmpty
                        ? null
                        : datePlantedCtrl.text.trim(),
                    'harvestDate': harvestDateCtrl.text.trim().isEmpty
                        ? null
                        : harvestDateCtrl.text.trim(),
                    'plantSpacing': plantSpCtrl.text.trim(),
                    'bedSpacing': bedSpCtrl.text.trim(),
                    'bedCount': bedCountCtrl.text.trim(),
                    'bedLength': bedLenCtrl.text.trim(),
                    'isDoubleSided': isDouble,
                    'leftSide': leftCtrl.text.trim(),
                    'rightSide': rightCtrl.text.trim(),
                  });
                  setState(() {
                    _crop['name'] = selectedTypeName;
                    _crop['plantSpacing'] = plantSpCtrl.text.trim();
                    _crop['bedSpacing'] = bedSpCtrl.text.trim();
                    _crop['numberOfBeds'] = bedCountCtrl.text.trim();
                    _crop['bedLength'] = bedLenCtrl.text.trim();
                    _crop['isDoubleSided'] = isDouble ? 1 : 0;
                    _crop['leftSideLength'] = leftCtrl.text.trim();
                    _crop['rightSideLength'] = rightCtrl.text.trim();
                    _crop['datePlanted'] = datePlantedCtrl.text.trim();
                    _crop['harvestDate'] = harvestDateCtrl.text.trim();
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
                    _sectionLabel('OVERVIEW'),
                    const SizedBox(height: 8),
                    _card([
                      _pickerRow('Crop Type', selectedTypeName, () {
                        _showPicker(
                          ctx,
                          'Select Crop Type',
                          cropTypes
                              .map((c) => {'id': c['id'], 'label': c['name']?.toString() ?? ''})
                              .toList(),
                          (item) {
                            setSheetState(() {
                              selectedTypeId = item['id'];
                              selectedTypeName = item['label'] ?? '';
                            });
                          },
                        );
                      }),
                      _div(),
                      _dateRow(ctx, 'Planted', datePlantedCtrl),
                      _div(),
                      _dateRow(ctx, 'Harvest', harvestDateCtrl),
                    ]),
                    const SizedBox(height: 16),
                    _sectionLabel('CONFIGURATION'),
                    const SizedBox(height: 8),
                    _card([
                      _inputRow('Plant Spacing', plantSpCtrl, '1.5 ft',
                          keyboard: TextInputType.number),
                      _div(),
                      _inputRow('Bed Spacing', bedSpCtrl, '4 ft',
                          keyboard: TextInputType.number),
                      _div(),
                      _inputRow('Beds', bedCountCtrl, '0',
                          keyboard: TextInputType.number),
                      _div(),
                      _switchRow('Double Sided', isDouble, (v) {
                        setSheetState(() => isDouble = v);
                      }),
                      if (isDouble) ...[
                        _div(),
                        _inputRow('Left (ft)', leftCtrl, '0',
                            keyboard: TextInputType.number),
                        _div(),
                        _inputRow('Right (ft)', rightCtrl, '0',
                            keyboard: TextInputType.number),
                      ] else ...[
                        _div(),
                        _inputRow('Bed Length', bedLenCtrl, '0 ft',
                            keyboard: TextInputType.number),
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

  Future<void> _deleteCrop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Crop'),
        content: const Text('Are you sure you want to delete this crop type?'),
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
        await _api.deleteCrop(_crop['id']);
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
    final name = _crop['name'] ?? 'Crop';
    final beds = _crop['numberOfBeds'] ?? _crop['number_of_beds'] ?? 0;

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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overview
                  _sectionLabel('OVERVIEW'),
                  const SizedBox(height: 8),
                  _card([
                    _infoRow(Icons.calendar_today, 'Planted',
                        _crop['datePlanted']?.toString() ?? 'N/A'),
                    _div(),
                    _infoRow(Icons.calendar_today, 'Harvest Date',
                        _crop['harvestDate']?.toString() ?? 'N/A'),
                  ]),
                  const SizedBox(height: 16),

                  // Configuration
                  _sectionLabel('CONFIGURATION'),
                  const SizedBox(height: 8),
                  _card([
                    _infoRow(Icons.tag, 'Number of Beds', '$beds'),
                    _div(),
                    _infoRow(Icons.straighten, 'Plant Spacing',
                        '${_val('plantSpacing')} ${_val('plantSpacing') != 'N/A' ? 'ft' : ''}'),
                    _div(),
                    _infoRow(Icons.swap_horiz, 'Bed Spacing',
                        '${_val('bedSpacing')} ${_val('bedSpacing') != 'N/A' ? 'ft' : ''}'),
                    _div(),
                    _infoRow(Icons.straighten, 'Bed Length',
                        '${_val('bedLength')} ft'),
                    if (_isDouble) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 48, bottom: 12, right: 16),
                        child: Text(
                          'Double Sided (L: ${_crop['leftSideLength'] ?? 0} ft / R: ${_crop['rightSideLength'] ?? 0} ft)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 24),

                  // Delete
                  if (isAdmin)
                    GestureDetector(
                      onTap: _deleteCrop,
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
                            Text('Delete Crop Type',
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
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF2563EB))),
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

  Widget _dateRow(
      BuildContext ctx, String label, TextEditingController ctrl) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          ctrl.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          // Trigger rebuild
          (ctx as Element).markNeedsBuild();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              ctrl.text.isEmpty ? 'Select' : ctrl.text,
              style: TextStyle(
                fontSize: 16,
                color: ctrl.text.isEmpty
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
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
