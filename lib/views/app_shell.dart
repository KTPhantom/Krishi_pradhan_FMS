import 'dart:ui';
import 'package:flutter/material.dart';
import 'home/home_page.dart';
import 'tasks/task_management_page.dart';
import 'finance/finance_page.dart';
import 'market/market_page.dart';
import 'fields/fields_map_page.dart';

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
    TaskManagementPage(),
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
            physics: const NeverScrollableScrollPhysics(),
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (i) {
                        final icons = [
                          Icons.home_rounded,
                          Icons.task_alt,
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
