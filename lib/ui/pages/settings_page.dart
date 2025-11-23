import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString('preferred_theme_mode', 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString('preferred_theme_mode', 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString('preferred_theme_mode', 'system');
        break;
    }
    appThemeMode.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _FuturisticToggle(
            options: const ['Light', 'System', 'Dark'],
            icons: const [Icons.light_mode, Icons.auto_awesome, Icons.dark_mode],
            onChanged: (index) {
              if (index == 0) _setThemeMode(ThemeMode.light);
              if (index == 1) _setThemeMode(ThemeMode.system);
              if (index == 2) _setThemeMode(ThemeMode.dark);
            },
            initialIndex: () {
              switch (appThemeMode.value) {
                case ThemeMode.light:
                  return 0;
                case ThemeMode.system:
                  return 1;
                case ThemeMode.dark:
                  return 2;
              }
            }(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Language', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _LangChip('English', 'en'),
              _LangChip('हिन्दी', 'hi'),
              _LangChip('বাংলা', 'bn'),
              _LangChip('தமிழ்', 'ta'),
              _LangChip('తెలుగు', 'te'),
              _LangChip('मराठी', 'mr'),
              _LangChip('ગુજરાતી', 'gu'),
              _LangChip('ಕನ್ನಡ', 'kn'),
              _LangChip('മലയാളം', 'ml'),
              _LangChip('ਪੰਜਾਬੀ', 'pa'),
              _LangChip('اردو', 'ur'),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            title: const Text('Enable push notifications'),
            subtitle: const Text('Receive alerts about tasks, orders, and weather'),
          ),
        ],
      ),
    );
  }
}

class _FuturisticToggle extends StatefulWidget {
  final List<String> options;
  final List<IconData>? icons;
  final int initialIndex;
  final ValueChanged<int> onChanged;

  const _FuturisticToggle({required this.options, required this.initialIndex, required this.onChanged, this.icons});

  @override
  State<_FuturisticToggle> createState() => _FuturisticToggleState();
}

class _FuturisticToggleState extends State<_FuturisticToggle> with SingleTickerProviderStateMixin {
  late int _index;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    // keep controller for smoothness if needed later
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setIndex(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    _controller.forward(from: 0);
    widget.onChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.options.length;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / count;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: segmentWidth * _index,
                top: 4,
                bottom: 4,
                width: segmentWidth - 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green, Colors.green.shade700]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.35), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(count, (i) {
                  final active = i == _index;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _setIndex(i),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icons != null) ...[
                              Icon(widget.icons![i], size: 18, color: active ? Colors.white : Colors.black54),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              widget.options[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final String code;
  const _LangChip(this.label, this.code);

  Future<void> _updateLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_locale_code', code);
    appLocale.value = Locale(code);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = appLocale.value?.languageCode == code || (appLocale.value == null && code == 'en');
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      selectedColor: Colors.green.shade50,
      onSelected: (_) => _updateLocale(code),
      labelStyle: TextStyle(color: isActive ? Colors.green.shade800 : Colors.black87),
      side: BorderSide(color: isActive ? Colors.green : Colors.grey.shade300),
    );
  }
}


