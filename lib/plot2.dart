import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'plot_map_fullscreen.dart';
import 'sugarcanedata.dart';
import 'profile.dart';
class Plot2Screen extends StatefulWidget {
  final String userId; // userId ของเจ้าของไร่
  final Map<String, dynamic> farmer; // ข้อมูลลูกไร่
  final String? ownerId; // เพิ่ม ownerId

  Plot2Screen({required this.userId, required this.farmer, this.ownerId});

  @override
  _Plot2ScreenState createState() => _Plot2ScreenState();
}

class _Plot2ScreenState extends State<Plot2Screen> {
  final String apiUrl = 'http://10.0.2.2:3000/pulluser';
  List<Map<String, dynamic>> plotList = [];
  bool isLoading = true;
  LatLng? locationLatLng;
  String? locationAddress;
  String selectedPlant = '';
  String selectedWater = '';
  String selectedSoil = '';
  String plotName = '';
  final TextEditingController _plotNameController = TextEditingController();
  List<LatLng> polygonPoints = [];
  bool _isLoading = false;
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadPlotData();
  }

  Future<void> fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _users = jsonData.cast<Map<String, dynamic>>();
          if (widget.userId.isNotEmpty) {
            _currentUser = _users.firstWhere(
              (user) => user['_id'] == widget.userId,
              orElse: () => _users.isNotEmpty ? _users.first : {},
            );
          } else {
            _currentUser = _users.isNotEmpty ? _users.first : null;
          }
          _isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ดึงข้อมูลแปลงปลูกของลูกไร่จาก database
  Future<void> _loadPlotData() async {
    try {
      // ใช้ userId ของลูกไร่ในการดึงข้อมูลแปลงปลูก
      final String farmerUserId =
          widget.farmer['userId']?['_id'] ?? widget.farmer['_id'];
      print('🔄 กำลังดึงข้อมูลแปลงปลูกของลูกไร่: $farmerUserId');

      // ใช้ endpoint ใหม่สำหรับดึงแปลงของลูกไร่โดยตรง
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/plots/$farmerUserId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> plots = jsonDecode(response.body);
        setState(() {
          plotList = plots.cast<Map<String, dynamic>>();
          isLoading = false;
        });
        print('✅ Loaded ${plots.length} plots for farmer');
      } else {
        print('❌ Error response: ${response.statusCode} - ${response.body}');
        setState(() {
          plotList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading plot data: $e');
      setState(() {
        plotList = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'แปลงปลูกของ ${widget.farmer['userId']?['name'] ?? widget.farmer['name'] ?? 'ลูกไร่'}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        foregroundColor: Color(0xFF25634B),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(width, height),
    );
  }

  Widget _buildBody(double width, double height) {
    // ถ้าไม่มีข้อมูล แสดงข้อความว่าไม่มีแปลงปลูก
    if (plotList.isEmpty) {
      return _buildEmptyState(width, height);
    }
    // ถ้ามีข้อมูล แสดงรายการ
    else {
      return _buildPlotList(width, height);
    }
  }

  // หน้าจอเมื่อไม่มีข้อมูล
  Widget _buildEmptyState(double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // ข้อความกลางจอ
          Positioned(
            top: height * 0.35,
            left: width * 0.1,
            right: width * 0.1,
            child: Column(
              children: [
                Icon(
                  Icons.agriculture_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'ยังไม่มีแปลงปลูก',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ลูกไร่ยังไม่ได้สร้างแปลงปลูก',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomButtons(width, height),
        ],
      ),
    );
  }

  // หน้าจอเมื่อมีข้อมูล
  Widget _buildPlotList(double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // รายการแปลงปลูก
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: height * 0.1,
            child: ListView.builder(
              itemCount: plotList.length,
              itemBuilder: (context, index) {
                final plot = plotList[index];
                return _buildPlotCard(plot, width, height);
              },
            ),
          ),
          // ปุ่มล่างสุด
          _buildBottomButtons(width, height),
        ],
      ),
    );
  }

  // Card แสดงข้อมูลแปลงปลูก
  Widget _buildPlotCard(
      Map<String, dynamic> plot, double width, double height) {
    // ดึง lat/lng จาก plot
    final double? lat = plot['latitude'] is double
        ? plot['latitude']
        : (plot['latitude'] is int
            ? (plot['latitude'] as int).toDouble()
            : null);
    final double? lng = plot['longitude'] is double
        ? plot['longitude']
        : (plot['longitude'] is int
            ? (plot['longitude'] as int).toDouble()
            : null);

    LatLng? plotPosition;
    if (lat != null && lng != null) {
      plotPosition = LatLng(lat, lng);
    }

    // ดึง polygon points
    final List<LatLng> plotPolygon = plot['polygonPoints'] != null
        ? List.from(plot['polygonPoints'])
            .map((p) => LatLng(p['latitude'], p['longitude']))
            .toList()
        : [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => sugarcanedata(
              plotId: plot['_id'],
              userId: widget.farmer['userId']?['_id'] ?? widget.farmer['_id'],
              plotName: plot['plotName'] ?? 'ไม่มีชื่อ',
              plantType: plot['plantType'],
              waterSource: plot['waterSource'],
              soilType: plot['soilType'],
              plotPosition: plotPosition,
              polygonPoints: plotPolygon,
              ownerId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini Google Map
            plotPosition != null
                ? Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: plotPosition,
                              zoom: 14,
                            ),
                            markers: {
                              Marker(
                                markerId:
                                    MarkerId('plot_marker_${plot['_id']}'),
                                position: plotPosition,
                              ),
                            },
                            polygons: plotPolygon.length >= 3
                                ? {
                                    Polygon(
                                      polygonId: PolygonId(
                                          'plot_polygon_${plot['_id']}'),
                                      points: plotPolygon,
                                      fillColor:
                                          Color(0xFF34D396).withOpacity(0.4),
                                      strokeColor: Color(0xFF34D396),
                                      strokeWidth: 3,
                                    ),
                                  }
                                : {},
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            zoomGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: true,
                          ),
                        ),
                        // ปุ่มขยายแผนที่
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(Icons.map, color: Colors.red, size: 20),
                            tooltip: 'ขยายแผนที่',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlotMapFullScreen(
                                    center: plotPosition!,
                                    polygonPoints: plotPolygon,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: Color(0xFF34D396),
                      size: width * 0.08,
                    ),
                  ),
            SizedBox(width: 12),
            // ข้อมูลแปลงปลูก
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plot['plotName'] ?? 'ไม่มีชื่อ',
                    style: TextStyle(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25624B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${plot['plantType']} • ${plot['soilType']}',
                    style: TextStyle(
                      fontSize: width * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        plot['waterSource'] ?? '',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        plotPolygon.length >= 3 ? Icons.map : Icons.location_on,
                        size: 16,
                        color: plotPolygon.length >= 3
                            ? Color(0xFF34D396)
                            : Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        plotPolygon.length >= 3
                            ? 'มีขอบเขตพื้นที่'
                            : 'จุดเดียว',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: plotPolygon.length >= 3
                              ? Color(0xFF34D396)
                              : Colors.grey[500],
                          fontWeight: plotPolygon.length >= 3
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ปุ่มล่างสุด
  Widget _buildBottomButtons(double width, double height) {
    return Stack(
      children: [
        // Container พื้นหลัง
        Positioned(
          bottom: 0,
          left: width * 0.03,
          right: width * 0.03,
          child: Container(
            height: height * 0.07,
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
        // ปุ่มซ้าย
        Positioned(
          bottom: height * 0.01,
          left: width * 0.07,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: width * 0.12,
              height: height * 0.05,
              decoration: ShapeDecoration(
                color: Color(0xFF34D396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: Image.asset(
                    'assets/โฮม.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        //ปุ่มล่างสุด ขวา - Profile Button
        Positioned(
          bottom: height * 0.01,
          right: width * 0.07,
          child: GestureDetector(
            onTap: () {
              if (_currentUser == null && !_isLoading) {
                fetchUserData().then((_) {
                  if (_currentUser != null) {
                    showProfileDialog(context, _currentUser!,
                        refreshUser: fetchUserData);
                  }
                });
              } else if (_currentUser != null) {
                showProfileDialog(context, _currentUser!,
                    refreshUser: fetchUserData);
              }
            },
            child: Container(
              width: width * 0.12,
              height: height * 0.05,
              decoration: ShapeDecoration(
                color: Color(0xFF34D396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: Padding(
                padding:
                    EdgeInsets.all(6), // เพิ่มระยะห่างจากขอบ (ลองปรับค่านี้ได้)
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: _isLoading
                      ? Container(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Image.asset(
                          'assets/โปรไฟล์.png',
                          fit: BoxFit.contain, // แสดงภาพโดยไม่เบียดจนเต็ม
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
