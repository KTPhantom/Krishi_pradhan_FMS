import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_state.dart';
import 'settings_page.dart';

// Enum for menu choices
enum ProfileMenuChoice { profile, settings, modeLight, modeDark, modeSystem }

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Old popup menu removed; using profile sheet + Settings page instead

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 100), // Adjusted top padding for profile icon
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("24°C", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Sunny", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 2),
                  const Text("H:46°C  L:52°C", style: TextStyle(fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text("Spinach Garden 08", style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        Flexible(child: Text("ID: PL-02J   Area: 200 m²", style: TextStyle(color: Colors.black54, fontSize: 12),textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Today's Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _CalendarPreview(),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2, 
                    children: const [
                      _DataCard(
                        title: "Plant Health",
                        value: "94%",
                        status: "Good",
                        description: "Your plants are thriving and showing excellent health",
                        color: Color(0xFF4CAF50),
                        valueColor: Colors.white,
                      ),
                      _DataCard(title: "Wind", value: "2 m/s", description: "Make sure there is still adequate airflow"),
                      _DataCard(title: "Temperature", value: "19°C", description: "Maintain between 15°C and 20°C"),
                      _DataCard(title: "pH Level", value: "7.6", description: "Add acidic compost to balance pH"),
                      _DataCard(title: "Humidity", value: "82%", description: "Ensure ventilation to prevent mold"),
                      _DataCard(title: "Soil Moisture", value: "65%", description: "Keep monitoring for consistency"),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const _GlassDock(),
          // Profile circle that opens a draggable, scrollable sheet
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => _openProfileSheet(context),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfileSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black26.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      CircleAvatar(radius: 24, backgroundColor: Colors.green, child: Icon(Icons.person, color: Colors.white)),
                      SizedBox(width: 12),
                      Expanded(child: Text('Farmer Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Language', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                  const SizedBox(height: 8),
                  const Text('Extended & Compliance', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _ListTileCard(icon: Icons.verified_user, title: 'KYC', subtitle: 'Verify your identity for services'),
                  _ListTileCard(icon: Icons.shield, title: 'Compliance Status', subtitle: 'View certifications and regulations'),
                  _ListTileCard(icon: Icons.assignment, title: 'Documents', subtitle: 'Manage insurance, land records, etc.'),
                  _ListTileCard(icon: Icons.support_agent, title: 'Support', subtitle: 'Contact support and FAQs'),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _ListTileCard(icon: Icons.settings, title: 'Settings', subtitle: 'Appearance, language, notifications', onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final String value;
  final String? status;
  final String description;
  final Color color;
  final Color valueColor;

  const _DataCard({
    required this.title,
    required this.value,
    required this.description,
    this.status,
    this.color = Colors.white,
    this.valueColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFilled = color != Colors.white;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isFilled ? Colors.white : Colors.black87,
                  )),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
                  if (status != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFilled ? Colors.white : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(status!, style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
            ],
          ),
          Text(description,
              style: TextStyle(fontSize: 11, color: isFilled ? Colors.white70 : Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _GlassDock extends StatelessWidget {
  const _GlassDock();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              width: 260,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.home, color: Colors.green, size: 28),
                  Icon(Icons.grid_view_rounded, color: Colors.grey),
                  Icon(Icons.shopping_cart_outlined, color: Colors.grey),
                  Icon(Icons.person_outline, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
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

class _ListTileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _ListTileCard({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: Icon(icon, color: Colors.green)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _CalendarPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
         boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _TaskRow("8:00 AM", "Irrigation"),
          SizedBox(height: 8),
          _TaskRow("10:30 AM", "Spray Pesticide"),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String time;
  final String task;

  const _TaskRow(this.time, this.task);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(task, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
