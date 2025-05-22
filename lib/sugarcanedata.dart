import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'weather_widget.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('th_TH', null);
  runApp(sugarcanedata());
}

// เพิ่มคลาส PlotInfo ใหม่เพื่อใช้ข้อมูลแปลงจาก plot1.dart
class PlotInfo {
  final String name;
  final double area;
  final List<LatLng> polygonPoints;
  final String? plantType;
  final String? specificPlant;
  final String? waterSource;

  PlotInfo({
    required this.name,
    required this.area,
    required this.polygonPoints,
    this.plantType,
    this.specificPlant,
    this.waterSource,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบจัดการบริหารไร่อ้อย',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Kanit', // ฟอนต์ภาษาไทย
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'), // Thai
        Locale('en', 'US'), // English
      ],
      home: const sugarcanedata(),
    );
  }
}

class SugarcaneData extends StatelessWidget {
  final String plotName;
  final String area;
  final String location;

  const SugarcaneData({
    Key? key,
    required this.plotName,
    required this.area,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ข้อมูลแปลง')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ชื่อแปลง: $plotName', style: TextStyle(fontSize: 18)),
            Text('พื้นที่: $area', style: TextStyle(fontSize: 18)),
            Text('ที่ตั้ง: $location', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// เพิ่มหน้าจอ SugarcaneDataScreenWithPlotInfo ใหม่
class SugarcaneDataScreenWithPlotInfo extends StatefulWidget {
  final PlotInfo plotInfo;

  const SugarcaneDataScreenWithPlotInfo({
    Key? key,
    required this.plotInfo,
  }) : super(key: key);

  @override
  _SugarcaneDataScreenWithPlotInfoState createState() => _SugarcaneDataScreenWithPlotInfoState();
}

class _SugarcaneDataScreenWithPlotInfoState extends State<SugarcaneDataScreenWithPlotInfo> {
  // ตำแหน่งของ Container สีเขียว ซึ่งสามารถปรับได้ด้วยการลากแถบ
  double _greenContainerTop = 0.3;
  // ความสูงของ Container สีเขียว
  double _greenContainerHeight = 0.5;

  // ค่าเริ่มต้นสำหรับ Y offset เมื่อเริ่มการลาก
  double? _startDragYOffset;
  // ค่าเริ่มต้นของตำแหน่ง Container เมื่อเริ่มการลาก
  double? _startDragContainerPosition;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return ChangeNotifierProvider(
      create: (_) => SoilAnalysisProvider(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.plotInfo.specificPlant ?? "แปลงปลูก",
            style: TextStyle(color: Color(0xFF25634B)),
          ),
          actions: [
            TextButton(
              onPressed: () {},
              child: Text(
                "เลิกปลูก",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Positioned(
                top: height * 0.02,
                left: width * 0.05,
                child: const WeatherWidget(),
              ),

              // กล่องสีเขียวหลัก
              Positioned(
                top: height * _greenContainerTop,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // แถบสำหรับลาก (Drag Handle)
                    GestureDetector(
                      onVerticalDragStart: (details) {
                        // บันทึกตำแหน่งเริ่มต้นเมื่อเริ่มลาก
                        _startDragYOffset = details.globalPosition.dy;
                        _startDragContainerPosition = _greenContainerTop;
                      },
                      onVerticalDragUpdate: (details) {
                        if (_startDragYOffset != null && _startDragContainerPosition != null) {
                          // คำนวณระยะที่เปลี่ยนแปลงในแนวดิ่ง
                          final dragDelta = details.globalPosition.dy - _startDragYOffset!;

                          // คำนวณตำแหน่งใหม่ของ Container
                          double newPosition = _startDragContainerPosition! + (dragDelta / height);

                          // จำกัดตำแหน่งไม่ให้เลื่อนเกินขอบเขตที่กำหนด
                          if (newPosition < 0) newPosition = 0; // ไม่เลื่อนขึ้นเกินส่วนบนของหน้าจอ
                          if (newPosition > 0.3) newPosition = 0.3;   // ไม่เลื่อนลงเกินครึ่งหน้าจอ

                          setState(() {
                            _greenContainerTop = newPosition;
                            // ปรับความสูงของ Container ตามตำแหน่ง
                            _greenContainerHeight = 0.8 - newPosition;
                          });
                        }
                      },
                      onVerticalDragEnd: (_) {
                        // รีเซ็ตค่าเริ่มต้นเมื่อสิ้นสุดการลาก
                        _startDragYOffset = null;
                        _startDragContainerPosition = null;
                      },
                      child: Container(
                        width: width * 0.9,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Color(0xFF34D396),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Color(0xFF25634B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ส่วนหลักของ Container สีเขียว
                    Container(
                      width: width * 0.9,
                      height: height * _greenContainerHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D396),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      // แท็บที่จะถูกวางภายใน container นี้
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            // ส่วนควบคุมแท็บ
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TabBar(
                                indicator: BoxDecoration(
                                  color: Color(0xFF25634B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: Color(0xFF25634B),
                                labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                dividerColor: Colors.transparent,
                                tabs: [
                                  Tab(
                                    icon: Icon(Icons.history),
                                    text: "ประวัติ",
                                    iconMargin: EdgeInsets.only(bottom: 4),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.lightbulb),
                                    text: "แนะนำ",
                                    iconMargin: EdgeInsets.only(bottom: 4),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.info),
                                    text: "ข้อมูลแปลง",
                                    iconMargin: EdgeInsets.only(bottom: 4),
                                  ),
                                ],
                              ),
                            ),
                            // มุมมองแท็บ
                            Expanded(
                              child: TabBarView(
                                children: [
                                  HistoryTab(),
                                  SuggestionTab(),
                                  PlotInfoTab(plotInfo: widget.plotInfo), // ส่งข้อมูลแปลงไปยังแท็บ
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Custom bottom navigation bar container (white background)
              Positioned(
                bottom: height * 0.01,
                left: width * 0.03,
                right: width * 0.03,
                child: Container(
                  height: height * 0.07,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(83.50),
                    ),
                    shadows: const [
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

              // ปุ่ม Home
              Positioned(
                bottom: height * 0.018,
                left: width * 0.07,
                child: Container(
                  width: width * 0.12,
                  height: height * 0.055,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                ),
              ),

              // ปุ่ม Settings
              Positioned(
                bottom: height * 0.018,
                right: width * 0.07,
                child: Container(
                  width: width * 0.12,
                  height: height * 0.055,
                  decoration: ShapeDecoration(
                    color: const Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// เพิ่มแท็บ PlotInfoTab ใหม่เพื่อแสดงข้อมูลแปลง
class PlotInfoTab extends StatelessWidget {
  final PlotInfo plotInfo;

  const PlotInfoTab({Key? key, required this.plotInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // การ์ดหัวข้อ
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info, color: Color(0xFF25634B)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ข้อมูลแปลงปลูกของคุณ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // การ์ดข้อมูลพื้นฐาน
          _buildInfoCard(
            'ข้อมูลทั่วไป',
            Icons.eco,
            [
              _buildInfoRow('ชื่อแปลง', plotInfo.name, Icons.label),
              _buildInfoRow('พื้นที่', '${plotInfo.area.toStringAsFixed(2)} ไร่', Icons.crop_square),
              _buildInfoRow('ประเภทพืช', plotInfo.plantType ?? 'ไม่ระบุ', Icons.category),
              _buildInfoRow('ชนิดพืช', plotInfo.specificPlant ?? 'ไม่ระบุ', _getIconForPlantType(plotInfo.plantType ?? '')),
              _buildInfoRow('แหล่งน้ำ', plotInfo.waterSource ?? 'ไม่ระบุ', Icons.water_drop),
            ],
          ),

          SizedBox(height: 16),

          // การ์ดข้อมูลพิกัด
          _buildInfoCard(
            'ข้อมูลพิกัด',
            Icons.location_on,
            [
              _buildInfoRow('จำนวนจุด', '${plotInfo.polygonPoints.length} จุด', Icons.place),
              if (plotInfo.polygonPoints.isNotEmpty)
                _buildInfoRow(
                    'พิกัดกึ่งกลาง',
                    '${_calculateCenterPoint(plotInfo.polygonPoints).latitude.toStringAsFixed(6)}, ${_calculateCenterPoint(plotInfo.polygonPoints).longitude.toStringAsFixed(6)}',
                    Icons.gps_fixed
                ),
            ],
          ),

          SizedBox(height: 16),

          // การ์ดสถิติ
          _buildInfoCard(
            'สถิติแปลง',
            Icons.analytics,
            [
              _buildInfoRow('เส้นรอบรูป', '${_calculatePerimeter(plotInfo.polygonPoints).toStringAsFixed(2)} เมตร', Icons.straighten),
              _buildInfoRow('ขนาดในตารางเมตร', '${(plotInfo.area * 1600).toStringAsFixed(2)} ตร.ม.', Icons.square_foot),
            ],
          ),

          SizedBox(height: 16),

          // ปุ่มดูแผนที่
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showMapDialog(context);
              },
              icon: Icon(Icons.map, color: Colors.white),
              label: Text(
                'ดูแผนที่แปลง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF25634B),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Color(0xFF25634B), size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 16),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF25634B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LatLng _calculateCenterPoint(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);

    double totalLat = 0;
    double totalLng = 0;

    for (LatLng point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  double _calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0;

    double perimeter = 0;
    for (int i = 0; i < points.length; i++) {
      LatLng current = points[i];
      LatLng next = points[(i + 1) % points.length];
      perimeter += _calculateDistance(current, next);
    }

    return perimeter;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // เมตร

    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    double a = (deltaLatRad / 2) * (deltaLatRad / 2) +
        (lat1Rad) * (lat2Rad) * (deltaLngRad / 2) * (deltaLngRad / 2);
    double c = 2 * (a > 1 ? 1 : a); // atan2(sqrt(a), sqrt(1-a))

    return earthRadius * c;
  }

  IconData _getIconForPlantType(String type) {
    switch (type) {
      case 'พืชไร่':
        return Icons.grass;
      case 'พืชสวน':
        return Icons.spa;
      case 'ผลไม้':
        return Icons.emoji_food_beverage;
      case 'พืชผัก':
        return Icons.emoji_nature;
      default:
        return Icons.eco;
    }
  }

  void _showMapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          child: Container(
            height: 400,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'แผนที่แปลง ${plotInfo.name}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _calculateCenterPoint(plotInfo.polygonPoints),
                      zoom: 16,
                    ),
                    polygons: {
                      Polygon(
                        polygonId: PolygonId('plot_area'),
                        points: plotInfo.polygonPoints,
                        fillColor: Color(0xFF34D396).withOpacity(0.3),
                        strokeColor: Color(0xFF34D396),
                        strokeWidth: 3,
                      ),
                    },
                    markers: plotInfo.polygonPoints.map((point) {
                      int index = plotInfo.polygonPoints.indexOf(point);
                      return Marker(
                        markerId: MarkerId('point_$index'),
                        position: point,
                        infoWindow: InfoWindow(
                          title: 'จุดที่ ${index + 1}',
                        ),
                      );
                    }).toSet(),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class sugarcanedata extends StatelessWidget {
  const sugarcanedata({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoilAnalysisProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // แสดงรูปภาพแบบเต็มหน้าจอ
          Center(
            child: Hero(
              tag: 'image_$imagePath',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // ปุ่มปิด
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ยูทิลิตี้คลาสสำหรับไอคอน
class TopicIcons {
  // ไอคอนตามประเภทกิจกรรม
  static IconData getIconForTopic(String topic) {
    if (topic.contains("วิเคราะห์ดิน")) return MdiIcons.microscope;
    if (topic.contains("บำรุงดิน")) return MdiIcons.sprout;
    if (topic.contains("ไถดินดาน")) return MdiIcons.terrain;
    if (topic.contains("ไถดะ")) return MdiIcons.landPlots;
    if (topic.contains("ไถแปร")) return MdiIcons.tractor;
    if (topic.contains("ไถดิน")) return MdiIcons.tractor;
    if (topic.contains("ใส่ปุ๋ยรองพื้น")) return MdiIcons.seedOutline;
    if (topic.contains("ใส่ปุ๋ยทำรุ่น")) return MdiIcons.flowerOutline;
    if (topic.contains("ใส่ปุ๋ยแต่งหน้า")) return MdiIcons.nature;
    if (topic.contains("ปุ๋ย")) return MdiIcons.seedOutline;
    if (topic.contains("ฉีดยาคุมวัชพืช")) return MdiIcons.spray;
    if (topic.contains("ฉีดยาหลังวัชพืชงอก")) return MdiIcons.bottleTonicPlus;
    if (topic.contains("กำจัดวัชพืช")) return MdiIcons.naturePeople;
    if (topic.contains("วัชพืช")) return MdiIcons.spray;
    if (topic.contains("เริ่มเก็บเกี่ยว")) return MdiIcons.contentCut;
    if (topic.contains("เก็บเกี่ยว")) return MdiIcons.contentCut;
    if (topic.contains("ขายผลผลิต")) return MdiIcons.cash;
    if (topic.contains("ขาย")) return MdiIcons.cash;

    // ค่าเริ่มต้นถ้าไม่พบประเภท
    return MdiIcons.sprout;
  }
}

class SoilAnalysis {
  String date;
  File? image;
  String topic;
  String message;

  SoilAnalysis({
    required this.date,
    this.image,
    required this.topic,
    this.message = "",
  });
}

class SoilAnalysisProvider with ChangeNotifier {
  final List<SoilAnalysis> _analyses = [];

  List<SoilAnalysis> get analyses => _analyses;

  // เพิ่มเมธอดเพื่อตรวจสอบว่ามีการบันทึกหัวข้อนั้นไว้แล้วหรือไม่
  bool isTopicSaved(String topic) {
    return _analyses.any((analysis) => analysis.topic == topic);
  }

  // เพิ่มเมธอดเพื่อดึงข้อมูลการวิเคราะห์ตามหัวข้อ
  SoilAnalysis? getAnalysisByTopic(String topic) {
    try {
      return _analyses.firstWhere((analysis) => analysis.topic == topic);
    } catch (e) {
      return null;
    }
  }

  void addAnalysis(SoilAnalysis analysis) {
    _analyses.add(analysis);
    notifyListeners();
  }

  void removeAnalysis(SoilAnalysis analysis) {
    _analyses.remove(analysis);
    notifyListeners();
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ตำแหน่งของ Container สีเขียว ซึ่งสามารถปรับได้ด้วยการลากแถบ
  double _greenContainerTop = 0.3;
  // ความสูงของ Container สีเขียว
  double _greenContainerHeight = 0.5;

  // ค่าเริ่มต้นสำหรับ Y offset เมื่อเริ่มการลาก
  double? _startDragYOffset;
  // ค่าเริ่มต้นของตำแหน่ง Container เมื่อเริ่มการลาก
  double? _startDragContainerPosition;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          "อ้อย",
          style: TextStyle(color: Color(0xFF25634B)),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "เลิกปลูก",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Positioned(
              top: height * 0.02,
              left: width * 0.05,
              child: const WeatherWidget(),
            ),

            // กล่องสีเขียวหลัก
            Positioned(
              top: height * _greenContainerTop,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // แถบสำหรับลาก (Drag Handle)
                  GestureDetector(
                    onVerticalDragStart: (details) {
                      // บันทึกตำแหน่งเริ่มต้นเมื่อเริ่มลาก
                      _startDragYOffset = details.globalPosition.dy;
                      _startDragContainerPosition = _greenContainerTop;
                    },
                    onVerticalDragUpdate: (details) {
                      if (_startDragYOffset != null && _startDragContainerPosition != null) {
                        // คำนวณระยะที่เปลี่ยนแปลงในแนวดิ่ง
                        final dragDelta = details.globalPosition.dy - _startDragYOffset!;

                        // คำนวณตำแหน่งใหม่ของ Container
                        double newPosition = _startDragContainerPosition! + (dragDelta / height);

                        // จำกัดตำแหน่งไม่ให้เลื่อนเกินขอบเขตที่กำหนด
                        if (newPosition < 0) newPosition = 0; // ไม่เลื่อนขึ้นเกินส่วนบนของหน้าจอ
                        if (newPosition > 0.3) newPosition = 0.3;   // ไม่เลื่อนลงเกินครึ่งหน้าจอ

                        setState(() {
                          _greenContainerTop = newPosition;
                          // ปรับความสูงของ Container ตามตำแหน่ง
                          _greenContainerHeight = 0.8 - newPosition;
                        });
                      }
                    },
                    onVerticalDragEnd: (_) {
                      // รีเซ็ตค่าเริ่มต้นเมื่อสิ้นสุดการลาก
                      _startDragYOffset = null;
                      _startDragContainerPosition = null;
                    },
                    child: Container(
                      width: width * 0.9,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(0xFF34D396),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Color(0xFF25634B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ส่วนหลักของ Container สีเขียว
                  Container(
                    width: width * 0.9,
                    height: height * _greenContainerHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D396),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    // แท็บที่จะถูกวางภายใน container นี้
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          // ส่วนควบคุมแท็บ
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TabBar(
                              indicator: BoxDecoration(
                                color: Color(0xFF25634B),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Color(0xFF25634B),
                              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              dividerColor: Colors.transparent,
                              tabs: [
                                Tab(
                                  icon: Icon(Icons.history),
                                  text: "ประวัติ",
                                  iconMargin: EdgeInsets.only(bottom: 4),
                                ),
                                Tab(
                                  icon: Icon(Icons.lightbulb),
                                  text: "แนะนำ",
                                  iconMargin: EdgeInsets.only(bottom: 4),
                                ),
                                Tab(
                                  icon: Icon(Icons.info),
                                  text: "ข้อมูลแปลง",
                                  iconMargin: EdgeInsets.only(bottom: 4),
                                ),
                              ],
                            ),
                          ),
                          // มุมมองแท็บ
                          Expanded(
                            child: TabBarView(
                              children: [
                                HistoryTab(),
                                SuggestionTab(),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "ข้อมูลแปลง",
                                        style: TextStyle(
                                            fontSize: 18, color: Color(0xFF25634B)),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "ยังไม่มีข้อมูลแปลง",
                                        style: TextStyle(
                                            fontSize: 16, color: Color(0xFF25634B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Custom bottom navigation bar container (white background)
            Positioned(
              bottom: height * 0.01,
              left: width * 0.03,
              right: width * 0.03,
              child: Container(
                height: height * 0.07,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(83.50),
                  ),
                  shadows: const [
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

            // ปุ่ม Home
            Positioned(
              bottom: height * 0.018,
              left: width * 0.07,
              child: Container(
                width: width * 0.12,
                height: height * 0.055,
                decoration: ShapeDecoration(
                  color: const Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                ),
              ),
            ),

            // ปุ่ม Settings
            Positioned(
              bottom: height * 0.018,
              right: width * 0.07,
              child: Container(
                width: width * 0.12,
                height: height * 0.055,
                decoration: ShapeDecoration(
                  color: const Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// แท็บแนะนำ
class SuggestionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SoilAnalysisProvider>(builder: (context, provider, child) {
      // จัดกลุ่มหัวข้อตามประเภทกิจกรรม
      final Map<String, List<TopicItem>> groupedTopics = {
        'การเตรียมดิน': [
          TopicItem('วิเคราะห์ดิน', MdiIcons.microscope, 'เพื่อตรวจสอบคุณภาพและความอุดมสมบูรณ์ของดิน'),
          TopicItem('บำรุงดิน', MdiIcons.sprout, 'เพิ่มธาตุอาหารและปรับปรุงโครงสร้างดิน'),
          TopicItem('ไถดินดาน', MdiIcons.terrain, 'แก้ไขปัญหาดินแน่นและระบายน้ำไม่ดี'),
          TopicItem('ไถดะ', MdiIcons.landPlots, 'ไถครั้งแรกเพื่อพลิกหน้าดิน'),
          TopicItem('ไถแปร', MdiIcons.tractor, 'ไถครั้งที่สองตัดแนวไถดะ'),
          TopicItem('ไถดิน', MdiIcons.tractor, 'การไถเตรียมดินก่อนปลูก'),
        ],
        'การใส่ปุ๋ย': [
          TopicItem('ใส่ปุ๋ยรองพื้น', MdiIcons.seedOutline, 'ใส่ปุ๋ยก่อนการปลูกเพื่อเตรียมธาตุอาหาร'),
          TopicItem('ใส่ปุ๋ยทำรุ่น', MdiIcons.flowerOutline, 'ใส่ปุ๋ยช่วงอ้อยเริ่มเจริญเติบโต'),
          TopicItem('ใส่ปุ๋ยแต่งหน้า', MdiIcons.nature, 'ใส่ปุ๋ยช่วงอ้อยเจริญเติบโตเต็มที่'),
        ],
        'การจัดการวัชพืช': [
          TopicItem('ฉีดยาคุมวัชพืช', MdiIcons.spray, 'ฉีดพ่นสารเคมีกำจัดวัชพืช'),
          TopicItem('ฉีดยาหลังวัชพืชงอก', MdiIcons.bottleTonicPlus, 'ฉีดพ่นสารเคมีหลังวัชพืชงอก'),
          TopicItem('กำจัดวัชพืช', MdiIcons.naturePeople, 'กำจัดวัชพืชโดยวิธีต่างๆ'),
        ],
        'การเก็บเกี่ยว': [
          TopicItem('เริ่มเก็บเกี่ยว', MdiIcons.contentCut, 'เก็บเกี่ยวผลผลิตอ้อย'),
          TopicItem('ขายผลผลิต', MdiIcons.cash, 'การจำหน่ายผลผลิตอ้อย'),
        ],
      };

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // คำแนะนำการใช้งาน
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lightbulb, color: Color(0xFF25634B)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'เลือกกิจกรรมที่คุณต้องการบันทึกข้อมูล',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // แสดงหัวข้อตามกลุ่ม
            ...groupedTopics.entries.map((entry) {
              return _buildTopicGroup(entry.key, entry.value, provider, context);
            }).toList(),
          ],
        ),
      );
    });
  }

  // สร้างกลุ่มหัวข้อ
  Widget _buildTopicGroup(String groupTitle, List<TopicItem> topics, SoilAnalysisProvider provider, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // หัวข้อกลุ่ม
        Container(
          margin: EdgeInsets.only(bottom: 12, top: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF25634B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            groupTitle,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        // รายการในกลุ่ม
        ...topics.map((topic) {
          final isSaved = provider.isTopicSaved(topic.title);
          return _buildOptionCard(topic, context, isSaved);
        }).toList(),

        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOptionCard(TopicItem topic, BuildContext context, bool isSaved) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Get current date for new entries
          final now = DateTime.now();
          final formatter = DateFormat('dd/MM/yyyy');
          final currentDate = formatter.format(now);

          // ตรวจสอบว่ามีข้อมูลเดิมหรือไม่
          final provider = Provider.of<SoilAnalysisProvider>(context, listen: false);
          final existingAnalysis = provider.getAnalysisByTopic(topic.title);

          if (existingAnalysis != null) {
            // ถ้ามีข้อมูลอยู่แล้ว ให้เปิดหน้าแก้ไข
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyzeSoilScreen(
                  topic: topic.title,
                  date: existingAnalysis.date,
                  image: existingAnalysis.image,
                  message: existingAnalysis.message,
                  isEditing: true,
                  analysis: existingAnalysis,
                ),
              ),
            );
          } else {
            // ถ้ายังไม่มีข้อมูล ให้เปิดหน้าเพิ่มใหม่
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyzeSoilScreen(
                  topic: topic.title,
                  date: currentDate,
                ),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // ไอคอนที่เกี่ยวข้องกับหัวข้อ
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Color(0xFF34D396).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  topic.icon,
                  color: Color(0xFF25634B),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),

              // รายละเอียดหัวข้อ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                    if (topic.description.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          topic.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // สถานะการบันทึก
              if (isSaved)
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFF25634B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Color(0xFF25634B),
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// คลาสเก็บข้อมูลหัวข้อ
class TopicItem {
  final String title;
  final IconData icon;
  final String description;

  TopicItem(this.title, this.icon, [this.description = '']);
}

// แท็บประวัติ
class HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SoilAnalysisProvider>(builder: (context, provider, child) {
      final groupedAnalyses = _groupByDate(provider.analyses);

      if (groupedAnalyses.isEmpty) {
        return Center(
          child: Text(
            "ยังไม่มีประวัติการบันทึกข้อมูล",
            style: TextStyle(color: Color(0xFF25634B), fontSize: 18),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.all(16),
        children: groupedAnalyses.entries.map((entry) {
          final date = entry.key;
          final analyses = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 4,
              color: Color(0xFF25634B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Column(
                      children: analyses.map((analysis) {
                        return _buildAnalysisTile(analysis, context);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildAnalysisTile(SoilAnalysis analysis, BuildContext context) {
    // เลือกไอคอนตามหัวข้อ
    IconData topicIcon = MdiIcons.sprout;
    if (analysis.topic.contains("วิเคราะห์")) {
      topicIcon = MdiIcons.microscope;
    } else if (analysis.topic.contains("ดิน")) {
      topicIcon = MdiIcons.terrain;
    } else if (analysis.topic.contains("ปุ๋ย")) {
      topicIcon = MdiIcons.seedOutline;
    } else if (analysis.topic.contains("วัชพืช")) {
      topicIcon = MdiIcons.spray;
    } else if (analysis.topic.contains("เก็บเกี่ยว")) {
      topicIcon = MdiIcons.contentCut;
    } else if (analysis.topic.contains("ขาย")) {
      topicIcon = MdiIcons.cash;
    }

    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          topicIcon,
          color: Color(0xFF25634B),
        ),
        title: Text(
          analysis.topic,
          style: TextStyle(color: Color(0xFF25634B), fontWeight: FontWeight.bold),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF25634B).withOpacity(0.7),
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalyzeSoilScreen(
                topic: analysis.topic,
                date: analysis.date,
                image: analysis.image,
                message: analysis.message,
                isEditing: true,
                analysis: analysis,
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, List<SoilAnalysis>> _groupByDate(List<SoilAnalysis> analyses) {
    final Map<String, List<SoilAnalysis>> grouped = {};
    for (var analysis in analyses) {
      grouped.putIfAbsent(analysis.date, () => []).add(analysis);
    }
    return grouped;
  }
}

class AnalyzeSoilScreen extends StatefulWidget {
  final String topic;
  final String? date;
  final File? image;
  final String? message;
  final bool isEditing;
  final SoilAnalysis? analysis;

  AnalyzeSoilScreen({
    required this.topic,
    this.date,
    this.image,
    this.message = "",
    this.isEditing = false,
    this.analysis,
  });

  @override
  _AnalyzeSoilScreenState createState() => _AnalyzeSoilScreenState();
}

class _AnalyzeSoilScreenState extends State<AnalyzeSoilScreen> {
  late TextEditingController _dateController;
  late TextEditingController _messageController;
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.date ?? "");
    _messageController = TextEditingController(text: widget.message ?? "");
    _image = widget.image;
  }

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการถ่ายรูป'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // เลือกรูปจากแกลเลอรี่
  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveData() {
    // ตรวจสอบว่าข้อความไม่ว่างเปล่า
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกข้อความ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final analysis = SoilAnalysis(
      date: _dateController.text,
      image: _image,
      topic: widget.topic,
      message: _messageController.text,
    );

    if (widget.isEditing && widget.analysis != null) {
      Provider.of<SoilAnalysisProvider>(context, listen: false)
          .removeAnalysis(widget.analysis!);
    }

    Provider.of<SoilAnalysisProvider>(context, listen: false)
        .addAnalysis(analysis);

    // แสดงข้อความบันทึกสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(widget.isEditing ? 'บันทึกการแก้ไขสำเร็จ' : 'บันทึกข้อมูลสำเร็จ'),
          ],
        ),
        backgroundColor: Color(0xFF25634B),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("ยืนยันการลบ"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด dialog
            },
            child: Text("ยกเลิก", style: TextStyle(color: Color(0xFF25634B))),
          ),
          ElevatedButton(
            onPressed: () {
              // ลบข้อมูลจาก Provider
              if (widget.analysis != null) {
                Provider.of<SoilAnalysisProvider>(context, listen: false)
                    .removeAnalysis(widget.analysis!);

                // แสดงข้อความลบสำเร็จ
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text('ลบข้อมูลสำเร็จ'),
                      ],
                    ),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              Navigator.pop(context); // ปิด dialog
              Navigator.pop(context); // กลับไปที่หน้าก่อนหน้า
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text("ลบ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // เลือกไอคอนที่เหมาะสมกับหัวข้อ
    final Map<String, IconData> topicIcons = {
      "ดิน": Icons.terrain,
      "ปุ๋ย": Icons.eco,
      "วัชพืช": Icons.nature,
      "เก็บเกี่ยว": Icons.content_cut,
      "ขาย": Icons.monetization_on,
      "น้ำ": Icons.water_drop,
      "ตรวจวัด": Icons.analytics,
      "ผลผลิต": Icons.agriculture,
      "โรค": Icons.sick,
    };

    IconData topicIcon = Icons.spa; // Default icon
    topicIcons.forEach((key, icon) {
      if (widget.topic.contains(key)) {
        topicIcon = icon;
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF34D396),
        elevation: 0,
        title: Text(
          widget.isEditing ? "รายละเอียด" : "บันทึกข้อมูล",
          style: TextStyle(color: Color(0xFF25634B)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // พื้นหลังส่วนบน
          Container(
            height: 120,
            width: double.infinity,
            color: Color(0xFF34D396),
          ),

          // เนื้อหาหลัก
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                // การ์ดหลัก
                Container(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ส่วนหัวการ์ด
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF25634B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                topicIcon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.topic,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    widget.isEditing ? "แก้ไขข้อมูล" : "กรอกข้อมูลรายละเอียด",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // เนื้อหาการ์ด
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // วันที่
                            Text(
                              "วันที่",
                              style: TextStyle(
                                color: Color(0xFF25634B),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                DateTime? selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Color(0xFF25634B),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (selectedDate != null) {
                                  setState(() {
                                    _dateController.text =
                                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dateController.text,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF34D396),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // ข้อความ
                            Text(
                              "ข้อความ",
                              style: TextStyle(
                                color: Color(0xFF25634B),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: "กรอกรายละเอียด...",
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Color(0xFF34D396), width: 2),
                                ),
                              ),
                              maxLines: 3,
                              style: TextStyle(fontSize: 16, fontFamily: 'Kanit'),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              keyboardType: TextInputType.multiline,
                            ),
                            SizedBox(height: 20),

                            // ส่วนอัพโหลดรูปภาพ
                            Text(
                              "รูปภาพ",
                              style: TextStyle(
                                color: Color(0xFF25634B),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 12),

                            // ปุ่มกล้องและแกลเลอรี่
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _takePicture,
                                    icon: Icon(Icons.camera_alt),
                                    label: Text("ถ่ายรูป"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF34D396),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: Icon(Icons.photo_library),
                                    label: Text("แกลเลอรี่"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF25634B),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            // แสดงภาพถ่าย
                            if (_image != null)
                              Container(
                                width: double.infinity,
                                height: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // เพิ่ม GestureDetector เพื่อให้คลิกดูรูปแบบเต็มหน้าจอได้
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FullScreenImageViewer(
                                              imagePath: _image!.path,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Hero(
                                        tag: 'image_${_image!.path}',
                                        child: Image.file(
                                          _image!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // ปุ่มลบรูปภาพ
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _image = null;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // เพิ่มไอคอนแสดงว่าสามารถคลิกได้
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.fullscreen,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "ยังไม่มีรูปภาพ",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ปุ่มบันทึก
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34D396),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 55),
                    ),
                    child: Text(
                      widget.isEditing ? "บันทึกการแก้ไข" : "บันทึก",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // ปุ่มลบ (แสดงเฉพาะเมื่ออยู่ในโหมดแก้ไข)
                if (widget.isEditing)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton(
                      onPressed: _confirmDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.redAccent),
                        ),
                        minimumSize: Size(double.infinity, 55),
                      ),
                      child: Text(
                        "ลบ",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                SizedBox(height: 24),
              ],
            ),
          ),

          // แสดงตัวโหลดเมื่อกำลังประมวลผล
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF34D396),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

class ImageDetailScreen extends StatelessWidget {
  final SoilAnalysis analysis;

  ImageDetailScreen({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียด"),
        backgroundColor: Color(0xFF34D396),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดงรูปภาพที่สามารถคลิกเพื่อดูแบบเต็มหน้าจอได้
            if (analysis.image != null)
              Container(
                width: double.infinity,
                height: 300,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.hardEdge,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenImageViewer(
                              imagePath: analysis.image!.path,
                            ),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'image_${analysis.image!.path}',
                        child: Image.file(
                          analysis.image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // ไอคอนแสดงว่าสามารถคลิกได้
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ข้อมูลรายละเอียด
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "หัวข้อ: ${analysis.topic}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "วันที่: ${analysis.date}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (analysis.message.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        "รายละเอียด:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF25634B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        analysis.message,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}