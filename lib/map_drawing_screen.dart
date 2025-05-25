// map_drawing_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'google_maps_search.dart'; // ไฟล์ที่มี SearchLocationWidget

class MapDrawingScreen extends StatefulWidget {
  final String? plotName;
  final String? plotId;

  const MapDrawingScreen({
    Key? key,
    this.plotName,
    this.plotId,
  }) : super(key: key);

  @override
  _MapDrawingScreenState createState() => _MapDrawingScreenState();
}

class _MapDrawingScreenState extends State<MapDrawingScreen> {
  GoogleMapController? _mapController;

  // ตำแหน่งเริ่มต้น (ขอนแก่น)
  final LatLng _initialPosition = LatLng(16.4322, 102.8236);

  // จุดที่วาด
  List<LatLng> _polygonPoints = [];
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};

  // โหมดการทำงาน
  bool _isDrawingMode = false;
  bool _isSearchMode = false;
  bool _isSaving = false;

  // ข้อมูลพื้นที่
  double _area = 0.0;
  String _centerAddress = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 17,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _onMapTapped(LatLng position) {
    if (!_isDrawingMode) return;

    setState(() {
      _polygonPoints.add(position);
      _updatePolygon();
      _updateMarkers();
    });
  }

  void _updatePolygon() {
    if (_polygonPoints.length >= 3) {
      setState(() {
        _polygons = {
          Polygon(
            polygonId: PolygonId('plot'),
            points: _polygonPoints,
            strokeColor: Color(0xFF34D396),
            strokeWidth: 3,
            fillColor: Color(0xFF34D396).withOpacity(0.2),
          ),
        };
        _area = _calculateArea(_polygonPoints);
      });
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};
    for (int i = 0; i < _polygonPoints.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: _polygonPoints[i],
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          onDragEnd: (newPosition) {
            setState(() {
              _polygonPoints[i] = newPosition;
              _updatePolygon();
            });
          },
        ),
      );
    }
    setState(() {
      _markers = markers;
    });
  }

  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0;

    double area = 0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = area.abs() / 2;

    // แปลงเป็นตารางเมตร (โดยประมาณ)
    return area * 111319.9 * 111319.9 * 0.6;
  }

  LatLng _getCenterPoint() {
    if (_polygonPoints.isEmpty) return _initialPosition;

    double lat = 0;
    double lng = 0;
    for (var point in _polygonPoints) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / _polygonPoints.length, lng / _polygonPoints.length);
  }

  void _clearDrawing() {
    setState(() {
      _polygonPoints.clear();
      _polygons.clear();
      _markers.clear();
      _area = 0;
      _isDrawingMode = false;
    });
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
        _updatePolygon();
        _updateMarkers();
      });
    }
  }

  Future<void> _savePlotToMongoDB() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาวาดพื้นที่อย่างน้อย 3 จุด')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // เตรียมข้อมูล
      final center = _getCenterPoint();
      _centerAddress = await GooglePlacesService.getAddressFromLatLng(center);

      final plotData = {
        'plotId': widget.plotId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'plotName': widget.plotName ?? 'แปลงที่ ${DateTime.now().millisecondsSinceEpoch}',
        'coordinates': _polygonPoints.map((point) => {
          'lat': point.latitude,
          'lng': point.longitude,
        }).toList(),
        'center': {
          'lat': center.latitude,
          'lng': center.longitude,
        },
        'area': _area,
        'address': _centerAddress,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // ส่งข้อมูลไปยัง MongoDB (ปรับ URL ตาม backend ของคุณ)
      final response = await http.post(
        Uri.parse('https://your-backend-url.com/api/plots'), // เปลี่ยนเป็น URL ของคุณ
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(plotData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกแปลงเรียบร้อยแล้ว'),
            backgroundColor: Color(0xFF34D396),
          ),
        );
        Navigator.pop(context, plotData);
      } else {
        throw Exception('Failed to save plot');
      }
    } catch (e) {
      print('Error saving plot: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSearchLocation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'ค้นหาตำแหน่ง',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SearchLocationWidget(
                onLocationSelected: (LatLng location) {
                  Navigator.pop(context);
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: location,
                        zoom: 17,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plotName ?? 'วาดแปลง'),
        backgroundColor: Color(0xFF34D396),
        actions: [
          if (_isDrawingMode && _polygonPoints.isNotEmpty)
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: _undoLastPoint,
            ),
          if (_polygonPoints.length >= 3)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _savePlotToMongoDB,
            ),
        ],
      ),
      body: Stack(
        children: [
          // แผนที่
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
            polygons: _polygons,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.hybrid,
          ),

          // แถบแสดงข้อมูล
          if (_area > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'พื้นที่: ${(_area / 1600).toStringAsFixed(2)} ไร่',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '(${_area.toStringAsFixed(0)} ตร.ม.)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (_isDrawingMode)
                      Text(
                        'แตะบนแผนที่เพื่อวาดแปลง',
                        style: TextStyle(
                          color: Color(0xFF34D396),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // ปุ่มควบคุม
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // ปุ่มค้นหา
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 80),
                  child: ElevatedButton.icon(
                    onPressed: _showSearchLocation,
                    icon: Icon(Icons.search),
                    label: Text('ค้นหาตำแหน่ง'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF34D396),
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Color(0xFF34D396)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // ปุ่มวาด/ล้าง
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isDrawingMode = !_isDrawingMode;
                            });
                          },
                          icon: Icon(_isDrawingMode ? Icons.stop : Icons.edit),
                          label: Text(_isDrawingMode ? 'หยุดวาด' : 'เริ่มวาดแปลง'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDrawingMode ? Colors.orange : Color(0xFF34D396),
                            minimumSize: Size(0, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_polygonPoints.isNotEmpty) ...[
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _clearDrawing,
                          icon: Icon(Icons.clear),
                          label: Text('ล้าง'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size(100, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม My Location
          Positioned(
            right: 16,
            bottom: 150,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Color(0xFF34D396)),
              mini: true,
            ),
          ),

          // Loading
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF34D396)),
                    SizedBox(height: 16),
                    Text(
                      'กำลังบันทึกข้อมูล...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}