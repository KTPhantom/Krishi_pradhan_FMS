import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  final List<LatLng> _currentPolygonPoints = [];
  
  // Initial position (India)
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629),
    zoom: 5,
  );

  bool _isDrawing = false;

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onTap(LatLng point) {
    if (_isDrawing) {
      setState(() {
        _currentPolygonPoints.add(point);
        _markers.add(
          Marker(
            markerId: MarkerId(point.toString()),
            position: point,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      });
    }
  }

  void _toggleDrawing() {
    if (_isDrawing && _currentPolygonPoints.length > 2) {
      // Complete polygon
      setState(() {
        final polygonId = PolygonId(DateTime.now().toString());
        _polygons.add(
          Polygon(
            polygonId: polygonId,
            points: List.from(_currentPolygonPoints),
            fillColor: Colors.green.withOpacity(0.3),
            strokeColor: Colors.green,
            strokeWidth: 2,
          ),
        );
        _currentPolygonPoints.clear();
        _markers.clear();
        _isDrawing = false;
      });
    } else if (!_isDrawing) {
      // Start drawing
      setState(() {
        _isDrawing = true;
        _currentPolygonPoints.clear();
        _markers.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Map'),
        actions: [
          if (_isDrawing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _currentPolygonPoints.length > 2 ? _toggleDrawing : null,
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: _kInitialPosition,
            onMapCreated: _onMapCreated,
            polygons: _polygons,
            markers: _markers,
            onTap: _onTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: _toggleDrawing,
                label: Text(_isDrawing ? 'Finish Drawing' : 'Draw Field'),
                icon: Icon(_isDrawing ? Icons.check : Icons.edit_location_alt),
                backgroundColor: _isDrawing ? Colors.green : Colors.white,
                foregroundColor: _isDrawing ? Colors.white : Colors.green,
              ),
            ),
          ),
          if (_isDrawing)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tap on the map to add points for your field boundary.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
