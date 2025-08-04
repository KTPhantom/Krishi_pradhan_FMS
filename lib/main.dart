import 'dart:ui';
import 'package:flutter/material.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/calendar_page.dart';
import 'ui/pages/finance_page.dart';
import 'ui/pages/market_page.dart';
import 'ui/pages/my_fields_page.dart';

void main() {
  runApp(const FarmVerseApp());
}

class FarmVerseApp extends StatelessWidget {
  const FarmVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmVerse',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const GlassDockWrapper(),
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
    Center(child: Text('Market')),
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView(
          controller: _pageController,
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
    );
  }
}
