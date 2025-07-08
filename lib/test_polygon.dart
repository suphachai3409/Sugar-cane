import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ไฟล์ทดสอบการทำงานของ Polygon
class PolygonTest extends StatefulWidget {
  @override
  _PolygonTestState createState() => _PolygonTestState();
}

class _PolygonTestState extends State<PolygonTest> {
  Set<Polygon> _polygons = {};
  List<LatLng> _testPoints = [
    LatLng(16.4322, 102.8236), // ขอนแก่น
    LatLng(16.4422, 102.8336),
    LatLng(16.4222, 102.8336),
    LatLng(16.4222, 102.8136),
  ];

  @override
  void initState() {
    super.initState();
    _createTestPolygon();
  }

  void _createTestPolygon() {
    setState(() {
      _polygons = {
        Polygon(
          polygonId: PolygonId('test_polygon'),
          points: _testPoints,
          fillColor: Color(0xFF34D396).withOpacity(0.4),
          strokeColor: Color(0xFF34D396),
          strokeWidth: 3,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ทดสอบ Polygon'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(16.4322, 102.8236),
          zoom: 15,
        ),
        polygons: _polygons,
      ),
    );
  }
} 