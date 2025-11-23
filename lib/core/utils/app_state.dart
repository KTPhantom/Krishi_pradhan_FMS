import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app locale state
final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);

/// Global app theme mode state
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

/// Initialize locale and theme from SharedPreferences
Future<void> initAppState() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  // Load locale preference
  final code = prefs.getString('preferred_locale_code');
  if (code != null && code.isNotEmpty) {
    appLocale.value = Locale(code);
  }
  
  // Load theme mode preference
  final mode = prefs.getString('preferred_theme_mode');
  if (mode != null) {
    switch (mode) {
      case 'light':
        appThemeMode.value = ThemeMode.light;
        break;
      case 'dark':
        appThemeMode.value = ThemeMode.dark;
        break;
      default:
        appThemeMode.value = ThemeMode.system;
    }
  }
}

