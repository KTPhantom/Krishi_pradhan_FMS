import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'controllers/auth_controller.dart';
import 'views/app_shell.dart';
import 'views/auth/login_page.dart';
import 'views/common/widgets/loading_widget.dart';
import 'core/utils/app_state.dart';
import 'core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Catch platform errors (unhandled async exceptions)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true;
  };

  await EnvConfig.load();

  try {
    await initAppState();
  } catch (e) {
    debugPrint('Warning: Failed to initialize app state: $e');
  }

  runApp(
    const ProviderScope(
      child: KrishiPradhanApp(),
    ),
  );
}

class KrishiPradhanApp extends ConsumerWidget {
  const KrishiPradhanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (context, themeMode, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Krishi Pradhan',
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: Colors.white,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.green, brightness: Brightness.dark),
              ),
              themeMode: themeMode,
              locale: locale,
              supportedLocales: const [
                Locale('en'), // English
                Locale('hi'), // Hindi
                Locale('bn'), // Bengali
                Locale('ta'), // Tamil
                Locale('te'), // Telugu
                Locale('mr'), // Marathi
                Locale('gu'), // Gujarati
                Locale('kn'), // Kannada
                Locale('ml'), // Malayalam
                Locale('pa'), // Punjabi
                Locale('ur'), // Urdu
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              localeResolutionCallback: (deviceLocale, supported) {
                if (locale != null) return locale;
                if (deviceLocale != null) {
                  for (final l in supported) {
                    if (l.languageCode == deviceLocale.languageCode) return l;
                  }
                }
                return const Locale('en');
              },
              home: authState.isLoading
                  ? const LoadingWidget(
                      message: 'Checking authentication...')
                  : authState.isAuthenticated
                      ? const GlassDockWrapper()
                      : const LoginPage(),
            );
          },
        );
      },
    );
  }
}
