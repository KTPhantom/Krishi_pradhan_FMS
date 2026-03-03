import 'dart:math';

/// KML coordinate point.
class KmlPoint {
  final double latitude;
  final double longitude;

  const KmlPoint({required this.latitude, required this.longitude});
}

/// Result of processing a KML file.
class KmlResult {
  final List<KmlPoint> boundary;
  final double calculatedArea; // in acres

  const KmlResult({required this.boundary, required this.calculatedArea});
}

/// Processes KML files to extract polygon boundaries and calculate area.
/// Ported from FarmERP's KMLProcessor.js.
class KmlProcessor {
  /// Parse KML content string and extract polygon boundary + area in acres.
  /// Returns null if parsing fails or no valid polygon found.
  static KmlResult? processKml(String? kmlContent) {
    if (kmlContent == null || kmlContent.isEmpty) return null;

    try {
      // Look for coordinates inside a Polygon tag first
      final polygonRegex = RegExp(
        r'<Polygon>[\s\S]*?<coordinates>([\s\S]*?)</coordinates>',
        caseSensitive: false,
      );
      var match = polygonRegex.firstMatch(kmlContent);

      // Fallback: try generic coordinates tag
      if (match == null) {
        final coordRegex = RegExp(
          r'<coordinates>([\s\S]*?)</coordinates>',
          caseSensitive: false,
        );
        match = coordRegex.firstMatch(kmlContent);
      }

      if (match == null) return null;

      final coordString = match.group(1)!.trim();
      // Split by whitespace (space, newline, tab)
      final points = coordString.split(RegExp(r'\s+'));

      final boundary = <KmlPoint>[];

      for (final point in points) {
        final parts = point.split(',');
        if (parts.length >= 2) {
          final lon = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          if (lat != null && lon != null) {
            boundary.add(KmlPoint(latitude: lat, longitude: lon));
          }
        }
      }

      // Need at least 3 points for a polygon
      if (boundary.length < 3) return null;

      final calculatedArea = _calculatePolygonArea(boundary);

      return KmlResult(boundary: boundary, calculatedArea: calculatedArea);
    } catch (e) {
      return null;
    }
  }

  /// Calculate polygon area in acres using the geodesic Shoelace formula.
  static double _calculatePolygonArea(List<KmlPoint> coordinates) {
    final area = _geodesicArea(coordinates);
    final areaInAcres = area * 0.000247105; // sq meters → acres
    return double.parse(areaInAcres.toStringAsFixed(2));
  }

  /// Approximate area for earth coordinates in square meters.
  static double _geodesicArea(List<KmlPoint> coords) {
    const radius = 6378137.0; // Earth radius in meters
    double area = 0;
    final len = coords.length;

    if (len > 2) {
      for (int i = 0; i < len; i++) {
        final p1 = coords[i];
        final p2 = coords[(i + 1) % len];
        area += (_rad(p2.longitude) - _rad(p1.longitude)) *
            (2 + sin(_rad(p1.latitude)) + sin(_rad(p2.latitude)));
      }
      area = area * radius * radius / 2;
    }
    return area.abs();
  }

  static double _rad(double num) => num * pi / 180;
}
