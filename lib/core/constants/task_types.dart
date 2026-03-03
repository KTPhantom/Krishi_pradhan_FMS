/// TASK_TYPES mapping — mirrors FarmERP taskData.js
/// Categories with empty sub-task lists are "material tasks" (skipped for now).
const Map<String, List<String>> taskTypes = {
  'cat_bedPrep': [
    'sub_discHarrow',
    'sub_cultivators',
    'sub_mdPlough',
    'sub_laserLeveler',
    'sub_bedMaker',
    'sub_manualBed',
  ],
  'cat_drip': [
    'sub_fullDrip',
    'sub_spreadDrip',
    'sub_checkDrip',
  ],
  'cat_fertigation': [],
  'cat_mulching': [
    'sub_manualMulch',
    'sub_spreadMulch',
    'sub_soilingManual',
    'sub_holeDigging',
  ],
  'cat_sowing': [
    'sub_manualSowing',
  ],
  'cat_transplanting': [
    'sub_manualTransplant',
  ],
  'cat_watering': [
    'sub_frequentIrrigation',
  ],
  'cat_drenching': [],
  'cat_weeding': [
    'sub_manualWeeding',
    'sub_weedicide',
  ],
  'cat_soiling': [
    'sub_fertilizer',
    'sub_insecticide',
    'sub_fungicide',
  ],
  'cat_spraying': [],
  'cat_stacking': [
    'sub_manualStacking',
  ],
  'cat_harvesting': [
    'sub_sorting',
    'sub_grading',
    'sub_packing',
  ],
  'cat_logistics': [
    'sub_loading',
    'sub_transporting',
  ],
};

/// Material task categories (empty sub-task lists)
const Set<String> materialTaskCategories = {
  'cat_fertigation',
  'cat_drenching',
  'cat_spraying',
};

/// Format a task key into human-readable text
/// e.g. 'cat_bedPrep' → 'Bed Prep', 'sub_discHarrow' → 'Disc Harrow'
String formatTaskKey(String key) {
  return key
      .replaceAll('cat_', '')
      .replaceAll('sub_', '')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
