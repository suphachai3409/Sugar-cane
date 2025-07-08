import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlotMapFullScreen extends StatelessWidget {
  final LatLng center;
  final List<LatLng> polygonPoints;

  const PlotMapFullScreen({
    Key? key,
    required this.center,
    required this.polygonPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Set<Polygon> polygons = {};
    if (polygonPoints.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: PolygonId('plot_polygon'),
          points: polygonPoints,
          fillColor: Color(0xFF34D396).withOpacity(0.4),
          strokeColor: Color(0xFF34D396),
          strokeWidth: 3,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('ดูแปลงปลูก')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 16),
        polygons: polygons,
        markers: {
          Marker(markerId: MarkerId('center'), position: center),
        },
      ),
    );
  }
}