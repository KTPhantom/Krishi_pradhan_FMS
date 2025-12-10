import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'ui/pages/market_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/calendar_page.dart';
import 'ui/pages/finance_page.dart';
import 'ui/pages/my_fields_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/widgets/loading_widget.dart';
import 'core/utils/app_state.dart';
import 'core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await initAppState();
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
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
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
                  ? const LoadingWidget(message: 'Checking authentication...')
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

class GlassDockWrapper extends StatefulWidget {
  const GlassDockWrapper({super.key});

  @override
  State<GlassDockWrapper> createState() => _GlassDockWrapperState();
}

class _GlassDockWrapperState extends State<GlassDockWrapper> {
  int _index = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = const [
    HomePage(),
    CalendarPage(),
    FinancePage(),
    MarketPage(),
    MyFieldsPage(),
  ];

  void _onTap(int idx) {
    setState(() => _index = idx);
    _pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe to avoid conflict with glass dock gestures
            onPageChanged: (i) => setState(() => _index = i),
            children: _pages,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    width: 320,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (i) {
                        final icons = [
                          Icons.home_rounded,
                          Icons.calendar_today,
                          Icons.attach_money_rounded,
                          Icons.shopping_cart,
                          Icons.map_sharp,
                        ];
                        return IconButton(
                          icon: Icon(
                            icons[i],
                            size: _index == i ? 28 : 22,
                            color: _index == i ? Colors.green.shade800 : Colors.grey.shade500,
                          ),
                          onPressed: () => _onTap(i),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
