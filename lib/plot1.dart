import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:typed_data';

void main() {
  runApp(PlotApp());
}

class PlotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color(0xFF34D396),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF34D396),
          secondary: Color(0xFF25624B),
        ),
      ),
      home: Plot1Screen(),
    );
  }
}

class Plot1Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แปลงปลูก'),
        backgroundColor: Color(0xFF34D396),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Positioned(
              top: 300,
              left: 140,
              child: GestureDetector(
                onTap: () {
                  // เปิด Google Maps เพื่อวาดพื้นที่
                  _navigateToMapScreen(context);
                },
                child: Container(
                  width: 90,
                  height: 85,
                  decoration: ShapeDecoration(
                    color: Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 680,
              left: 10,
              right: 10,
              child: Container(
                width: 363,
                height: 73,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(83.50),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x7F646464),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              top: 690,
              left: 25,
              child: Container(
                width: 50,
                height: 45,
                decoration: ShapeDecoration(
                  color: Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: Icon(
                  Icons.home,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 690,
              right: 25,
              child: Container(
                width: 50,
                height: 45,
                decoration: ShapeDecoration(
                  color: Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
            ),
            Center(
              child: Text(
                'กดที่ปุ่ม + เพื่อสร้างแปลง',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF25624B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMapScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapDrawingScreen(),
      ),
    );
  }

  // Original popup methods kept for later use
  void _showFirstPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 359,
            height: 427,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(45),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x7F646464),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'พืชไร่ชนิดที่ปลูก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25624B),
                  ),
                ),
                SizedBox(height: 40),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg'),
                        _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg'),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg'),
                        _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg'),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('ย้อนกลับ'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSecondPopup(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF34D396),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('ถัดไป'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSecondPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 359,
            height: 427,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(45),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x7F646464),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'พืชไร่ชนิดที่ปลูก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25624B),
                  ),
                ),
                SizedBox(height: 40),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg'),
                        _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg'),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg'),
                        _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg'),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('ย้อนกลับ'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showthreePopup(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF34D396),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('ถัดไป'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showthreePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 359,
            height: 427,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(45),
              ),
              shadows: [
                BoxShadow(
                  color: Color(0x7F646464),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 20),
                Text(
                  'แหล่งน้ำที่ใช้ปลูก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25624B),
                  ),
                ),
                SizedBox(height: 40),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('ขุดสระ', 'assets/พืชไร่.jpg'),
                        _buildPopupItem('น้ำบาดาล', 'assets/พืชสวน.jpg'),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('แหล่งน้ำธรรมชาติ', 'assets/ผลไม้.jpg'),
                        _buildPopupItem('น้ำชลประธาน', 'assets/พืชผัก.jpg'),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('ย้อนกลับ'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF34D396),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('บันทึกข้อมูล'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupItem(String label, String imagePath) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 63,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color(0x7F646464),
                blurRadius: 4,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// หน้าแผนที่สำหรับวาดพื้นที่แปลง
class MapDrawingScreen extends StatefulWidget {
  @override
  _MapDrawingScreenState createState() => _MapDrawingScreenState();
}

class _MapDrawingScreenState extends State<MapDrawingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  List<LatLng> _points = [];
  bool _isDrawing = false;
  int _polygonIdCounter = 1;
  double _areaInSquareMeters = 0.0;
  Uint8List? _mapSnapshot;

  // ตำแหน่งเริ่มต้น (กรุงเทพฯ)
  final CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(13.736717, 100.523186),
    zoom: 15,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('วาดแปลงเกษตร'),
        backgroundColor: Color(0xFF34D396),
        actions: [
          if (_points.isNotEmpty && !_isDrawing)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetDrawing,
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            mapType: MapType.satellite,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: _markers,
            polygons: _polygons,
            onTap: _isDrawing ? _addPoint : null,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_areaInSquareMeters > 0)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'พื้นที่: ${_areaInSquareMeters.toStringAsFixed(2)} ตร.ม.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!_isDrawing && _points.isEmpty)
                      ElevatedButton.icon(
                        onPressed: _startDrawing,
                        icon: Icon(Icons.edit),
                        label: Text('เริ่มวาดพื้นที่'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                        ),
                      ),
                    if (_isDrawing)
                      ElevatedButton.icon(
                        onPressed: _completeDrawing,
                        icon: Icon(Icons.check),
                        label: Text('เสร็จสิ้น'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                        ),
                      ),
                    if (!_isDrawing && _points.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _saveAreaAndContinue,
                        icon: Icon(Icons.save),
                        label: Text('บันทึกและไปต่อ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _points = [];
      _polygons = {};
      _markers = {};
    });
  }

  void _addPoint(LatLng point) {
    setState(() {
      _points.add(point);

      // เพิ่ม marker ที่จุดที่กด
      _markers.add(
        Marker(
          markerId: MarkerId('point_${_points.length}'),
          position: point,
        ),
      );

      // อัพเดทเส้น polygon เพื่อแสดงเส้นที่กำลังวาด
      if (_points.length > 1) {
        _updatePolygon();
      }
    });
  }

  void _updatePolygon() {
    final String polygonId = 'polygon_$_polygonIdCounter';

    _polygons.clear();
    _polygons.add(
      Polygon(
        polygonId: PolygonId(polygonId),
        points: _points,
        strokeWidth: 2,
        strokeColor: Color(0xFF34D396),
        fillColor: Color(0x3034D396),
      ),
    );
  }

  void _completeDrawing() {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาวาดอย่างน้อย 3 จุดเพื่อสร้างพื้นที่'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDrawing = false;
      _points.add(_points.first); // ปิดพื้นที่ด้วยการเชื่อมจุดสุดท้ายกับจุดแรก
      _updatePolygon();
      _calculateArea();
      _captureMapSnapshot();
    });
  }

  void _resetDrawing() {
    setState(() {
      _points = [];
      _markers = {};
      _polygons = {};
      _areaInSquareMeters = 0;
      _mapSnapshot = null;
    });
  }

  void _calculateArea() {
    // คำนวณพื้นที่ในตารางเมตรโดยใช้ Shoelace formula (Gauss's area formula)
    if (_points.length < 3) return;

    double area = 0;
    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p2 = _points[i + 1];

      // แปลงเป็นหน่วยเมตรก่อนคำนวณ
      double lat1Rad = p1.latitude * (pi / 180);
      double lon1Rad = p1.longitude * (pi / 180);
      double lat2Rad = p2.latitude * (pi / 180);
      double lon2Rad = p2.longitude * (pi / 180);

      // Earth radius in meters
      const double earthRadius = 6371000;

      // Convert to Cartesian coordinates
      double x1 = earthRadius * cos(lat1Rad) * cos(lon1Rad);
      double y1 = earthRadius * cos(lat1Rad) * sin(lon1Rad);

      double x2 = earthRadius * cos(lat2Rad) * cos(lon2Rad);
      double y2 = earthRadius * cos(lat2Rad) * sin(lon2Rad);

      // Accumulate area with cross product
      area += (x1 * y2 - x2 * y1);
    }

    _areaInSquareMeters = abs(area) / 2.0;
  }

  Future<void> _captureMapSnapshot() async {
    try {
      final controller = _mapController;
      if (controller != null) {
        final Uint8List? snapshot = await controller.takeSnapshot();
        setState(() {
          _mapSnapshot = snapshot;
        });
      }
    } catch (e) {
      print('Error capturing map snapshot: $e');
    }
  }

  void _saveAreaAndContinue() {
    // จำลองการบันทึกรูปภาพและข้อมูลพื้นที่
    // ในการใช้งานจริงควรบันทึกข้อมูลลงฐานข้อมูลหรือ shared preferences

    // แสดง dialog บอกว่าบันทึกสำเร็จ
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('บันทึกสำเร็จ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('บันทึกพื้นที่ ${_areaInSquareMeters.toStringAsFixed(2)} ตร.ม. เรียบร้อยแล้ว'),
              SizedBox(height: 10),
              if (_mapSnapshot != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Image.memory(_mapSnapshot!, fit: BoxFit.cover),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // ไปยังหน้าถัดไปเพื่อเลือกพืชที่ปลูก
                _navigateToNextScreen(context);
              },
              child: Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToNextScreen(BuildContext context) {
    // ปิดหน้า map แล้วกลับไปที่หน้าแรก
    Navigator.pop(context);

    // เปิด popup เพื่อเลือกชนิดพืชที่ปลูก
    Plot1Screen().\_showFirstPopup(context);
  }
}