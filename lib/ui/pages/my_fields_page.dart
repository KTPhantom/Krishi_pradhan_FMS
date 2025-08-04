import 'package:flutter/material.dart';

class MyFieldsPage extends StatelessWidget {
  const MyFieldsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for field cards
    final List<Map<String, String>> fields = [
      {
        "crop": "Spinach",
        "area": "2 acres",
        "waterSource": "Well",
        "id": "SF001"
      },
      {
        "crop": "Tomato",
        "area": "1.5 acres",
        "waterSource": "Canal",
        "id": "TF002"
      },
      {
        "crop": "Wheat",
        "area": "5 acres",
        "waterSource": "Borewell",
        "id": "WF003"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Consistent background
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 64, 24, 100), // Consistent padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Fields",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200, // Placeholder height for the map
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400)
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "Map Area Placeholder",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text("Draw Your Field"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // TODO: Implement draw field functionality
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Your Registered Fields",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return _FieldCard(
                    cropName: field['crop']!,
                    area: field['area']!,
                    waterSource: field['waterSource']!,
                    fieldId: field['id']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String cropName;
  final String area;
  final String waterSource;
  final String fieldId;

  const _FieldCard({
    required this.cropName,
    required this.area,
    required this.waterSource,
    required this.fieldId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$cropName Field ($fieldId)",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.grass, color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Text("Crop: $cropName", style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.square_foot_outlined, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Text("Area: $area", style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.water_drop_outlined, color: Colors.lightBlue.shade600, size: 18),
                const SizedBox(width: 8),
                Text("Water Source: $waterSource", style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.history, size: 18),
                label: const Text("View History", style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                onPressed: () {
                  // TODO: Implement view field history
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
