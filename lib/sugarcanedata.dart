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
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('th_TH', null);
  runApp(sugarcanedata(userId: 'default_user_id')); // ใช้ค่าจริงจากระบบล็อกอิน
}

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
        fontFamily: 'Kanit',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
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
  _SugarcaneDataScreenWithPlotInfoState createState() =>
      _SugarcaneDataScreenWithPlotInfoState();
}

class _SugarcaneDataScreenWithPlotInfoState
    extends State<SugarcaneDataScreenWithPlotInfo> {
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
                        if (_startDragYOffset != null &&
                            _startDragContainerPosition != null) {
                          // คำนวณระยะที่เปลี่ยนแปลงในแนวดิ่ง
                          final dragDelta =
                              details.globalPosition.dy - _startDragYOffset!;

                          // คำนวณตำแหน่งใหม่ของ Container
                          double newPosition = _startDragContainerPosition! +
                              (dragDelta / height);

                          // จำกัดตำแหน่งไม่ให้เลื่อนเกินขอบเขตที่กำหนด
                          if (newPosition < 0)
                            newPosition = 0; // ไม่เลื่อนขึ้นเกินส่วนบนของหน้าจอ
                          if (newPosition > 0.3)
                            newPosition = 0.3; // ไม่เลื่อนลงเกินครึ่งหน้าจอ

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
                              margin: EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 0),
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
                                labelStyle: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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

class sugarcanedata extends StatelessWidget {
  final String userId;

  const sugarcanedata({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoilAnalysisProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(userId: userId),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({Key? key, required this.imagePath})
      : super(key: key);

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
  List<File> images; // เปลี่ยนจาก File? เป็น List<File>
  String topic;
  String message;

  SoilAnalysis({
    required this.date,
    required this.images, // เปลี่ยนเป็น required
    required this.topic,
    this.message = "",
  });
}

class SoilAnalysisProvider with ChangeNotifier {
  final List<SoilAnalysis> _analyses = [];

  List<SoilAnalysis> get analyses => _analyses;

  bool isTopicSaved(String topic) {
    return _analyses.any((analysis) => analysis.topic == topic);
  }

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
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // เพิ่มตัวแปรสำหรับเก็บข้อมูลผู้ใช้
  final String apiUrl = 'http://10.0.2.2:3000/pulluser';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  // เพิ่ม getter สำหรับ userId
  String get userId => widget.userId;

  // ฟังก์ชันดึงข้อมูลผู้ใช้
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
          // ใช้ userId ที่รับมาจาก widget
          if (userId.isNotEmpty) {
            _currentUser = _users.firstWhere(
              (user) => user['_id'] == userId,
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

  // ฟังก์ชันแสดงโปรไฟล์ (เหมือนใน moneytransfer.dart)
  void _showProfileDialog() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34D396).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: Color(0xFF34D396),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'โปรไฟล์ของฉัน',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'ข้อมูลส่วนตัว',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // User Information
                _buildInfoCard(
                  icon: Icons.account_circle,
                  title: 'ชื่อผู้ใช้',
                  value: _currentUser!['username'] ?? 'ไม่มีข้อมูล',
                  color: Colors.purple,
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.person,
                  title: 'ชื่อ',
                  value: _currentUser!['name'] ?? 'ไม่มีข้อมูล',
                  color: Color(0xFF25624B),
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.email,
                  title: 'อีเมล',
                  value: _currentUser!['email'] ?? 'ไม่มีข้อมูล',
                  color: Colors.orange,
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.phone,
                  title: 'เบอร์โทร',
                  value: _currentUser!['number']?.toString() ?? 'ไม่มีข้อมูล',
                  color: Colors.blue,
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.menu_book,
                  title: 'เมนู',
                  value:
                      'Menu ${_currentUser!['menu']?.toString() ?? 'ไม่ระบุ'}',
                  color: Color(0xFF34D396),
                ),

                SizedBox(height: 25),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34D396),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'ปิด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลผู้ใช้เมื่อเริ่มต้น
    fetchUserData();
  }

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
              left: width * 0.055,
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
                      if (_startDragYOffset != null &&
                          _startDragContainerPosition != null) {
                        // คำนวณระยะที่เปลี่ยนแปลงในแนวดิ่ง
                        final dragDelta =
                            details.globalPosition.dy - _startDragYOffset!;

                        // คำนวณตำแหน่งใหม่ของ Container
                        double newPosition =
                            _startDragContainerPosition! + (dragDelta / height);

                        // จำกัดตำแหน่งไม่ให้เลื่อนเกินขอบเขตที่กำหนด
                        if (newPosition < 0)
                          newPosition = 0; // ไม่เลื่อนขึ้นเกินส่วนบนของหน้าจอ
                        if (newPosition > 0.3)
                          newPosition = 0.3; // ไม่เลื่อนลงเกินครึ่งหน้าจอ

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
                            margin: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
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
                              labelStyle: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              dividerColor: Colors.transparent,
                              tabs: [
                                Tab(
                                  icon: Image.asset(
                                    'assets/ประวัติ.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                  text: "ประวัติ",
                                  iconMargin: EdgeInsets.only(bottom: 4),
                                ),
                                Tab(
                                  icon: Image.asset(
                                    'assets/แนะนำ.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                  text: "แนะนำ",
                                  iconMargin: EdgeInsets.only(bottom: 4),
                                ),
                                Tab(
                                  icon: Image.asset(
                                    'assets/ข้อมูลแปลง.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
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
                                            fontSize: 18,
                                            color: Color(0xFF25634B)),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "ยังไม่มีข้อมูลแปลง",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF25634B)),
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
            //ปุ่มล่างสุด ซ้าย
            Positioned(
              bottom: height * 0.01, // 3% จากด้านล่าง
              left: width * 0.07,
              child: GestureDetector(
                onTap: () {
                  // TODO: ใส่ฟังก์ชันเมื่อกด
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
                    padding: EdgeInsets.all(
                        6), // เพิ่มระยะห่างจากขอบ (ลองปรับค่านี้ได้)
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: Image.asset(
                        'assets/โฮม.png',
                        fit: BoxFit.contain, // แสดงภาพโดยไม่เบียดจนเต็ม
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ปุ่มขวา
            Positioned(
              bottom: height * 0.01,
              right: width * 0.07,
              child: GestureDetector(
                onTap: () {
                  if (_currentUser == null && !_isLoading) {
                    fetchUserData().then((_) {
                      if (_currentUser != null) {
                        _showProfileDialog();
                      }
                    });
                  } else if (_currentUser != null) {
                    _showProfileDialog();
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
                    padding: EdgeInsets.all(
                        6), // เพิ่มระยะห่างจากขอบ (ลองปรับค่านี้ได้)
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
        ),
      ),
    );
  }
}

// แท็บแนะนำ
class SuggestionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SoilAnalysisProvider>(
      builder: (context, provider, child) {
        // จัดกลุ่มหัวข้อตามประเภทกิจกรรม
        final Map<String, List<TopicItem>> groupedTopics = {
          'การเตรียมดิน': [
            TopicItem('วิเคราะห์ดิน', MdiIcons.microscope,
                'เพื่อตรวจสอบคุณภาพและความอุดมสมบูรณ์ของดิน'),
            TopicItem('บำรุงดิน', MdiIcons.sprout,
                'เพิ่มธาตุอาหารและปรับปรุงโครงสร้างดิน'),
            TopicItem('ไถดินดาน', MdiIcons.terrain,
                'แก้ไขปัญหาดินแน่นและระบายน้ำไม่ดี'),
            TopicItem('ไถดะ', MdiIcons.landPlots, 'ไถครั้งแรกเพื่อพลิกหน้าดิน'),
            TopicItem('ไถแปร', MdiIcons.tractor, 'ไถครั้งที่สองตัดแนวไถดะ'),
            TopicItem('ไถดิน', MdiIcons.tractor, 'การไถเตรียมดินก่อนปลูก'),
          ],
          'การใส่ปุ๋ย': [
            TopicItem('ใส่ปุ๋ยรองพื้น', MdiIcons.seedOutline,
                'ใส่ปุ๋ยก่อนการปลูกเพื่อเตรียมธาตุอาหาร'),
            TopicItem('ใส่ปุ๋ยทำรุ่น', MdiIcons.flowerOutline,
                'ใส่ปุ๋ยช่วงอ้อยเริ่มเจริญเติบโต'),
            TopicItem('ใส่ปุ๋ยแต่งหน้า', MdiIcons.nature,
                'ใส่ปุ๋ยช่วงอ้อยเจริญเติบโตเต็มที่'),
          ],
          'การจัดการวัชพืช': [
            TopicItem(
                'ฉีดยาคุมวัชพืช', MdiIcons.spray, 'ฉีดพ่นสารเคมีกำจัดวัชพืช'),
            TopicItem('ฉีดยาหลังวัชพืชงอก', MdiIcons.bottleTonicPlus,
                'ฉีดพ่นสารเคมีหลังวัชพืชงอก'),
            TopicItem('กำจัดวัชพืช', MdiIcons.naturePeople,
                'กำจัดวัชพืชโดยวิธีต่างๆ'),
          ],
          'การเก็บเกี่ยว': [
            TopicItem(
                'เริ่มเก็บเกี่ยว', MdiIcons.contentCut, 'เก็บเกี่ยวผลผลิตอ้อย'),
            TopicItem('ขายผลผลิต', MdiIcons.cash, 'การจำหน่ายผลผลิตอ้อย'),
          ],
        };

        // ไอคอนสำหรับแต่ละกลุ่ม
        final Map<String, IconData> groupIcons = {
          'การเตรียมดิน': MdiIcons.shovel,
          'การใส่ปุ๋ย': Icons.spa,
          'การจัดการวัชพืช': MdiIcons.spray,
          'การเก็บเกี่ยว': MdiIcons.grain,
        };

        // สีสำหรับแต่ละกลุ่ม
        final Map<String, List<Color>> groupGradients = {
          'การเตรียมดิน': [Color(0xFF8B4513), Color(0xFFD2691E)],
          'การใส่ปุ๋ย': [Color(0xFF228B22), Color(0xFF90EE90)],
          'การจัดการวัชพืช': [Color(0xFFFF8C00), Color(0xFFFFA500)],
          'การเก็บเกี่ยว': [Color(0xFF9932CC), Color(0xFFDA70D6)],
        };

        return SafeArea(
          // เอา Scaffold ออกและเหลือแค่ SafeArea
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding เท่ากันทุกด้าน
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
              // เพิ่ม physics เพื่อให้ scroll ได้ดีขึ้น
              physics: const BouncingScrollPhysics(),
              children: groupedTopics.entries.map((entry) {
                final groupTitle = entry.key;
                final topics = entry.value;
                final icon = groupIcons[groupTitle] ?? Icons.category;
                final gradientColors = groupGradients[groupTitle] ??
                    [Color(0xFF25634B), Color(0xFF34D396)];

                final savedCount = topics
                    .where((topic) => provider.isTopicSaved(topic.title))
                    .length;
                final totalCount = topics.length;

                return Card(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _showTopicPopup(context, groupTitle, topics, provider,
                          gradientColors[0]);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            gradientColors[1].withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient:
                                        LinearGradient(colors: gradientColors),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            gradientColors[0].withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  groupTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF25634B),
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (savedCount > 0)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '$savedCount/$totalCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 4,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: savedCount > 0
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                savedCount > 0
                                    ? 'มีข้อมูล $savedCount รายการ'
                                    : 'ยังไม่มีข้อมูล',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: savedCount > 0
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // แสดง popup สำหรับแต่ละกลุ่ม
  void _showTopicPopup(BuildContext context, String groupTitle,
      List<TopicItem> topics, SoilAnalysisProvider provider, Color color) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 16,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // หัวข้อ popup
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'เลือกกิจกรรมที่ต้องการบันทึก',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // รายการหัวข้อ
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: topics.asMap().entries.map((entry) {
                        final index = entry.key;
                        final topic = entry.value;
                        final isSaved = provider.isTopicSaved(topic.title);
                        return _buildPopupOptionCard(
                            topic, context, isSaved, provider, index);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // การ์ดสำหรับแต่ละหัวข้อใน popup
  Widget _buildPopupOptionCard(TopicItem topic, BuildContext context,
      bool isSaved, SoilAnalysisProvider provider, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSaved ? 6 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pop(); // ปิด popup ก่อน

            // Get current date for new entries
            final now = DateTime.now();
            final formatter = DateFormat('dd/MM/yyyy');
            final currentDate = formatter.format(now);

            // ตรวจสอบว่ามีข้อมูลเดิมหรือไม่
            final existingAnalysis = provider.getAnalysisByTopic(topic.title);

            if (existingAnalysis != null) {
              // ถ้ามีข้อมูลอยู่แล้ว ให้เปิดหน้าแก้ไข
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyzeSoilScreen(
                    topic: topic.title,
                    date: existingAnalysis.date,
                    images: existingAnalysis.images,
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isSaved
                  ? LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05)
                      ],
                    )
                  : null,
            ),
            child: Row(
              children: [
                // หมายเลขลำดับ
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSaved
                        ? Colors.green
                        : Color(0xFF34D396).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSaved ? Colors.white : Color(0xFF25634B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // ไอคอน
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396).withOpacity(0.1),
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
                          color: Color(0xFF2D3748),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                // สถานะการบันทึก
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSaved ? Colors.green : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSaved ? Icons.check : Icons.add,
                    color: isSaved ? Colors.white : Color(0xFF25634B),
                    size: 20,
                  ),
                ),
              ],
            ),
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
          style:
              TextStyle(color: Color(0xFF25634B), fontWeight: FontWeight.bold),
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
                images: analysis.images,
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
  final List<File>? images; // เปลี่ยนจาก File? เป็น List<File>
  final String? message;
  final bool isEditing;
  final SoilAnalysis? analysis;

  AnalyzeSoilScreen({
    required this.topic,
    this.date,
    this.images,
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
  List<File> _images = []; // เปลี่ยนจาก File? เป็น List<File>
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.date ?? "");
    _messageController = TextEditingController(text: widget.message ?? "");
    _images = widget.images ?? []; // เปลี่ยนจาก widget.image เป็น widget.images
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
          _images.add(File(pickedFile.path)); // เพิ่มรูปใหม่เข้า List
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

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _images.addAll(pickedFiles.map((file) => File(file.path)));
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
      images: _images, // ใช้ List<File> แทน File?
      topic: widget.topic,
      message: _messageController.text,
    );

    if (widget.isEditing && widget.analysis != null) {
      Provider.of<SoilAnalysisProvider>(context, listen: false)
          .removeAnalysis(widget.analysis!);
    }

    Provider.of<SoilAnalysisProvider>(context, listen: false)
        .addAnalysis(analysis);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(widget.isEditing
                ? 'บันทึกการแก้ไขสำเร็จ'
                : 'บันทึกข้อมูลสำเร็จ'),
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
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก", style: TextStyle(color: Color(0xFF25634B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.analysis != null) {
                Provider.of<SoilAnalysisProvider>(context, listen: false)
                    .removeAnalysis(widget.analysis!);
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text("ลบ", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    IconData topicIcon = Icons.spa;
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
          Container(
            height: 120,
            width: double.infinity,
            color: Color(0xFF34D396),
          ),
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
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
                                    widget.isEditing
                                        ? "แก้ไขข้อมูล"
                                        : "กรอกข้อมูลรายละเอียด",
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
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
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
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Color(0xFF34D396), width: 2),
                                ),
                              ),
                              maxLines: 3,
                              style:
                                  TextStyle(fontSize: 16, fontFamily: 'Kanit'),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              keyboardType: TextInputType.multiline,
                            ),
                            SizedBox(height: 20),
                            Text(
                              "รูปภาพ",
                              style: TextStyle(
                                color: Color(0xFF25634B),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 12),
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
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
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
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            if (_images.isNotEmpty)
                              Container(
                                height: 250,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Container(
                                        width: 200,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 5,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.hardEdge,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImageGalleryScreen(
                                                      images: _images,
                                                      initialIndex: index,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Hero(
                                                tag:
                                                    'image_${_images[index].path}',
                                                child: Image.file(
                                                  _images[index],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _images.removeAt(index);
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
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
                                            Visibility(
                                              visible: false,
                                              child: Positioned(
                                                bottom: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.fullscreen,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                SizedBox(height: 24),
              ],
            ),
          ),
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

class ImageGalleryScreen extends StatelessWidget {
  final List<File> images;
  final int initialIndex;

  const ImageGalleryScreen({
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'image_${images[index].path}',
                child: Image.file(
                  images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
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
            if (analysis.images.isNotEmpty)
              Container(
                height: 300,
                child: PageView.builder(
                  itemCount: analysis.images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageGalleryScreen(
                              images: analysis.images,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'image_${analysis.images[index].path}',
                        child: Image.file(
                          analysis.images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
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
