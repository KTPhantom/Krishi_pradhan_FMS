import 'dart:ui';
import 'package:flutter/material.dart';

// Enum for menu choices
enum ProfileMenuChoice { profile, settings, modeLight, modeDark, modeSystem }

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _onMenuSelection(ProfileMenuChoice choice, BuildContext context) {
    // Placeholder actions - replace with actual navigation or theme changes
    switch (choice) {
      case ProfileMenuChoice.profile:
        print("Profile selected");
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
        break;
      case ProfileMenuChoice.settings:
        print("Settings selected");
        // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
        break;
      case ProfileMenuChoice.modeLight:
        print("Light Mode selected");
        // ThemeManager.setTheme(ThemeMode.light);
        break;
      case ProfileMenuChoice.modeDark:
        print("Dark Mode selected");
        // ThemeManager.setTheme(ThemeMode.dark);
        break;
      case ProfileMenuChoice.modeSystem:
        print("System Mode selected");
        // ThemeManager.setTheme(ThemeMode.system);
        break;
    }
  }

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
          // Profile Icon PopupMenuButton
          Positioned(
            top: 40, // Adjust as needed for status bar height
            right: 16,
            child: PopupMenuButton<ProfileMenuChoice>(
              icon: const Icon(Icons.account_circle, size: 32, color: Colors.black54), // Added color and size
              onSelected: (ProfileMenuChoice choice) => _onMenuSelection(choice, context),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<ProfileMenuChoice>>[
                const PopupMenuItem<ProfileMenuChoice>(
                  value: ProfileMenuChoice.profile,
                  child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profile')),
                ),
                const PopupMenuItem<ProfileMenuChoice>(
                  value: ProfileMenuChoice.settings,
                  child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings')),
                ),
                const PopupMenuDivider(),
                // Using SubmenuButton for nested "Mode" options
                PopupMenuItem(
                  child: SubmenuButton(
                     menuChildren: <Widget>[
                        PopupMenuItem<ProfileMenuChoice>(
                          value: ProfileMenuChoice.modeLight,
                          child: ListTile(leading: Icon(Icons.wb_sunny_outlined), title: Text('Light')),
                        ),
                        PopupMenuItem<ProfileMenuChoice>(
                          value: ProfileMenuChoice.modeDark,
                          child: ListTile(leading: Icon(Icons.nightlight_round), title: Text('Dark')),
                        ),
                        PopupMenuItem<ProfileMenuChoice>(
                          value: ProfileMenuChoice.modeSystem,
                          child: ListTile(leading: Icon(Icons.brightness_auto_outlined), title: Text('System')),
                        ),
                     ],
                     child: Text("Mode"),
                   )
                 )
              ],
            ),
          ),
        ],
      ),
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
