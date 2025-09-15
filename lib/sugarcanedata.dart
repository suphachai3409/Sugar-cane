import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'weather_widget.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'menu1.dart';
import 'menu2.dart';
import 'menu3.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'workerscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('th_TH', null);
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
        fontFamily: 'NotoSansThai',
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF2D8C8A),
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansThai',
            fontSize: 28,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF2D8C8A),
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansThai',
            fontSize: 24,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF2D8C8A),
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSansThai',
            fontSize: 18,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF2D8C8A),
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansThai',
            fontSize: 16,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'NotoSansThai',
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'NotoSansThai',
            fontSize: 14,
          ),
        ),
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
  double _greenContainerHeight = 0.6;

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
        appBar: AppBar(),
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
  final String plotId;
  final String userId;
  final String plotName;
  final String? plantType;
  final String? waterSource;
  final String? soilType;
  final LatLng? plotPosition;
  final List<LatLng>? polygonPoints;
  final bool isWorkerMode; // เพิ่มพารามิเตอร์นี้
  final bool isViewMode;
  final String ownerId;

  const sugarcanedata({
    Key? key,
    required this.plotId,
    required this.userId,
    required this.plotName,
    this.plantType,
    this.waterSource,
    this.soilType,
    this.plotPosition,
    this.polygonPoints,
    this.isWorkerMode = false, // กำหนดค่าเริ่มต้น
    this.isViewMode = false,
    required this.ownerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoilAnalysisProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(
          plotId: plotId,
          userId: userId,
          plotName: plotName,
          plantType: plantType,
          waterSource: waterSource,
          soilType: soilType,
          plotPosition: plotPosition,
          polygonPoints: polygonPoints,
          ownerId: ownerId,
        ),
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
  final String plotId;
  final String userId;
  final String plotName;
  final String? plantType;
  final String? waterSource;
  final String? soilType;
  final LatLng? plotPosition;
  final List<LatLng>? polygonPoints;
  final String ownerId;
  const HomeScreen({
    Key? key,
    required this.plotId,
    required this.userId,
    required this.plotName,
    this.plantType,
    this.waterSource,
    this.soilType,
    this.plotPosition,
    this.polygonPoints,
    required this.ownerId, 
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // เพิ่มตัวแปรสำหรับเก็บข้อมูลผู้ใช้
  final String apiUrl = 'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/pulluser';
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
          // ใช้ ownerId แทน userId ของลูกไร่
          if (widget.ownerId.isNotEmpty) {
            _currentUser = _users.firstWhere(
              (user) => user['_id'] == widget.ownerId,
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
  void _showEditProfileDialog() {
    if (_currentUser == null) return;

    final TextEditingController _nameController =
        TextEditingController(text: _currentUser!['name']);
    final TextEditingController _emailController =
        TextEditingController(text: _currentUser!['email']);
    final TextEditingController _numberController =
        TextEditingController(text: _currentUser!['number']?.toString());
    final TextEditingController _usernameController =
        TextEditingController(text: _currentUser!['username']);
    final TextEditingController _passwordController =
        TextEditingController(text: _currentUser!['password']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('แก้ไขข้อมูลส่วนตัว'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'ชื่อ'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'อีเมล'),
                ),
                TextField(
                  controller: _numberController,
                  decoration: InputDecoration(labelText: 'เบอร์โทร'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'ชื่อผู้ใช้'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'รหัสผ่าน'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                await _updateUserProfile(
                  _currentUser!['_id'],
                  _nameController.text,
                  _emailController.text,
                  int.tryParse(_numberController.text) ?? 0,
                  _usernameController.text,
                  _passwordController.text,
                );
                Navigator.pop(context);
                fetchUserData(); // Refresh the user data
              },
              child: Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

// Add this method to update user profile
  Future<void> _updateUserProfile(
    String userId,
    String name,
    String email,
    int number,
    String username,
    String password,
  ) async {
    final updateUrl = 'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/updateuser/$userId';
    try {
      final response = await http.put(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'number': number,
          'username': username,
          'password': password,
          // Keep the existing menu value
          'menu': _currentUser!['menu'],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตข้อมูลสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปเดตข้อมูล'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Then modify the _showProfileDialog method to add the edit button:
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
                SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.grey[800],
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
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(); // Close the profile dialog
                          _showEditProfileDialog(); // Show edit dialog
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
                          'แก้ไขข้อมูล',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.pushReplacementNamed(context, '/'); // Logout
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'ออกจากระบบ',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF25634B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
              overflow: TextOverflow.ellipsis, // ตัดข้อความยาวด้วย ...
              maxLines: 2, // อนุญาตให้มีได้สูงสุด 2 บรรทัด
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      // ในส่วนของ AppBar ในหน้า sugarcanedata.dart
      appBar: AppBar(
        title: Text(
          widget.plotName,
          style: TextStyle(
            color: Color(0xFF25634B),
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Positioned(
              top: height * 0.02,
              left: 0,
              right: 0,
              child: Container(
                width: width * 0.9, // กำหนดความกว้างสูงสุด 90% ของหน้าจอ
                child: Center(
                  child: WeatherWidget(),
                ),
              ),
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
                                HistoryTab(
                                    plotId: widget.plotId,
                                    userId: widget.userId), // Pass userId here
                                SuggestionTab(
                                    plotId: widget.plotId,
                                    userId: widget.userId),
                                SingleChildScrollView(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "ข้อมูลแปลง",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF25634B),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoRow("ชื่อแปลง",
                                                    widget.plotName),
                                                _buildInfoRow(
                                                    "ชนิดพืช",
                                                    widget.plantType ??
                                                        "ไม่มีข้อมูล"),
                                                _buildInfoRow(
                                                    "แหล่งน้ำ",
                                                    widget.waterSource ??
                                                        "ไม่มีข้อมูล"),
                                                _buildInfoRow(
                                                    "ชนิดดิน",
                                                    widget.soilType ??
                                                        "ไม่มีข้อมูล"),
                                                SizedBox(height: 16),
                                                Text(
                                                  "ตำแหน่งแปลง",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF25634B),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Container(
                                                  height: 150,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: GoogleMap(
                                                      initialCameraPosition:
                                                          CameraPosition(
                                                        target: widget
                                                                .plotPosition ??
                                                            LatLng(13.736717,
                                                                100.523186),
                                                        zoom: 14,
                                                      ),
                                                      markers: {
                                                        if (widget
                                                                .plotPosition !=
                                                            null)
                                                          Marker(
                                                            markerId: MarkerId(
                                                                'plot_location'),
                                                            position: widget
                                                                .plotPosition!,
                                                            icon: BitmapDescriptor
                                                                .defaultMarkerWithHue(
                                                              BitmapDescriptor
                                                                  .hueGreen,
                                                            ),
                                                          ),
                                                      },
                                                      polygons: {
                                                        if (widget.polygonPoints !=
                                                                null &&
                                                            widget.polygonPoints!
                                                                    .length >=
                                                                3)
                                                          Polygon(
                                                            polygonId: PolygonId(
                                                                'plot_polygon'),
                                                            points: widget
                                                                .polygonPoints!,
                                                            fillColor: Color(
                                                                    0xFF34D396)
                                                                .withOpacity(
                                                                    0.4),
                                                            strokeColor: Color(
                                                                0xFF34D396),
                                                            strokeWidth: 3,
                                                          ),
                                                      },
                                                      zoomControlsEnabled:
                                                          false,
                                                      myLocationButtonEnabled:
                                                          false,
                                                      scrollGesturesEnabled:
                                                          false,
                                                      rotateGesturesEnabled:
                                                          false,
                                                      tiltGesturesEnabled:
                                                          false,
                                                      zoomGesturesEnabled:
                                                          false,
                                                      liteModeEnabled: true,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      widget.polygonPoints !=
                                                                  null &&
                                                              widget.polygonPoints!
                                                                      .length >=
                                                                  3
                                                          ? Icons.map
                                                          : Icons.location_on,
                                                      size: 16,
                                                      color: widget.polygonPoints !=
                                                                  null &&
                                                              widget.polygonPoints!
                                                                      .length >=
                                                                  3
                                                          ? Color(0xFF34D396)
                                                          : Colors.grey,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        widget.plotPosition !=
                                                                null
                                                            ? "${widget.plotPosition!.latitude.toStringAsFixed(6)}, ${widget.plotPosition!.longitude.toStringAsFixed(6)}"
                                                            : "ไม่มีตำแหน่ง",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey.shade600),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        if (widget
                                                                .plotPosition !=
                                                            null) {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  FullScreenMap(
                                                                position: widget
                                                                    .plotPosition!,
                                                                polygonPoints:
                                                                    widget
                                                                        .polygonPoints,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      child: Text(
                                                        "ดูแผนที่เต็มหน้าจอ",
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xFF34D396),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                        // ย้อนกลับไปหน้า menu ตาม menu ของ user
                        if (_currentUser != null) {
                          if (_currentUser?['menu'] == 1) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Menu1Screen(userId: _currentUser?['_id'] ?? '')));
                          } else if (_currentUser?['menu'] == 2) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Menu2Screen(userId: _currentUser?['_id'] ?? '')));
                          } else if (_currentUser?['menu'] == 3) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Menu3Screen(userId: _currentUser?['_id'] ?? '')));
                          }
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
                // ในปุ่มโปรไฟล์ ให้ใช้ ownerId
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

class FullScreenMap extends StatelessWidget {
  final LatLng position;
  final List<LatLng>? polygonPoints;

  const FullScreenMap({
    Key? key,
    required this.position,
    this.polygonPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แผนที่แปลงปลูก'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: MarkerId('plot_location'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        },
        polygons: {
          if (polygonPoints != null && polygonPoints!.length >= 3)
            Polygon(
              polygonId: PolygonId('plot_polygon'),
              points: polygonPoints!,
              fillColor: Color(0xFF34D396).withOpacity(0.4),
              strokeColor: Color(0xFF34D396),
              strokeWidth: 3,
            ),
        },
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
    );
  }
}

// แท็บแนะนำ
class SuggestionTab extends StatefulWidget {
  final String plotId;
  final String userId; // Add this line

  const SuggestionTab({
    Key? key,
    required this.plotId,
    required this.userId, // Add this line
  }) : super(key: key);

  @override
  _SuggestionTabState createState() => _SuggestionTabState();
}

class _SuggestionTabState extends State<SuggestionTab> {
  bool _isLoading = false;
// เพิ่มฟังก์ชันนี้เพื่อรีเฟรชข้อมูลเมื่อกลับมาที่หน้า
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _fetchRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchRecommendations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
        }

        final recommendations = snapshot.data?['recommendations'] ?? [];
        final counts = snapshot.data?['counts'] ??
            {
              'การเตรียมดิน': 0,
              'การใส่ปุ๋ย': 0,
              'การจัดการวัชพืช': 0,
              'การเก็บเกี่ยว': 0,
            };

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
                TopicItem(
                    'ไถดะ', MdiIcons.landPlots, 'ไถครั้งแรกเพื่อพลิกหน้าดิน'),
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
                TopicItem('ฉีดยาคุมวัชพืช', MdiIcons.spray,
                    'ฉีดพ่นสารเคมีกำจัดวัชพืช'),
                TopicItem('ฉีดยาหลังวัชพืชงอก', MdiIcons.bottleTonicPlus,
                    'ฉีดพ่นสารเคมีหลังวัชพืชงอก'),
                TopicItem('กำจัดวัชพืช', MdiIcons.naturePeople,
                    'กำจัดวัชพืชโดยวิธีต่างๆ'),
              ],
              'การเก็บเกี่ยว': [
                TopicItem('เริ่มเก็บเกี่ยว', MdiIcons.contentCut,
                    'เก็บเกี่ยวผลผลิตอ้อย'),
                TopicItem('ขายผลผลิต', MdiIcons.cash, 'การจำหน่ายผลผลิตอ้อย'),
              ],
            };

            // นับจำนวน recommendation สำหรับแต่ละ topic
            final topicCounts = <String, int>{};
            for (final rec in recommendations) {
              topicCounts[rec['topic']] = (topicCounts[rec['topic']] ?? 0) + 1;
            }

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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15,
                  physics: const BouncingScrollPhysics(),
                  children: groupedTopics.entries.map((entry) {
                    final groupTitle = entry.key;
                    final topics = entry.value;
                    final icon = groupIcons[groupTitle] ?? Icons.category;
                    final gradientColors = groupGradients[groupTitle] ??
                        [Color(0xFF25634B), Color(0xFF34D396)];
                    final savedCount = counts[groupTitle] ?? 0;
                    final totalCount = topics.length;
                    final topicStatus = <String, bool>{};
                    for (final topic in topics) {
                      topicStatus[topic.title] =
                          topicCounts.containsKey(topic.title);
                    }

                    return Card(
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: InkWell(
                        onTap: () {
                          _showTopicPopup(
                            context,
                            groupTitle,
                            topics,
                            provider,
                            gradientColors[0],
                            topicStatus, // ส่ง topicStatus แทน topicCounts
                          );
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
                                        gradient: LinearGradient(
                                            colors: gradientColors),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: gradientColors[0]
                                                .withOpacity(0.3),
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
      },
    );
  }

  Future<Map<String, dynamic>> _fetchRecommendations() async {
    try {
      final response = await http
          .get(
            Uri.parse(
                'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/recommendations'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> recommendations = jsonDecode(response.body);

        // นับจำนวน recommendation สำหรับแต่ละกลุ่มกิจกรรม
        final Map<String, int> counts = {
          'การเตรียมดิน': 0,
          'การใส่ปุ๋ย': 0,
          'การจัดการวัชพืช': 0,
          'การเก็บเกี่ยว': 0,
        };

        // กำหนดว่าแต่ละหัวข้ออยู่ในกลุ่มไหน
        final Map<String, String> topicToGroup = {
          'วิเคราะห์ดิน': 'การเตรียมดิน',
          'บำรุงดิน': 'การเตรียมดิน',
          'ไถดินดาน': 'การเตรียมดิน',
          'ไถดะ': 'การเตรียมดิน',
          'ไถแปร': 'การเตรียมดิน',
          'ไถดิน': 'การเตรียมดิน',
          'ใส่ปุ๋ยรองพื้น': 'การใส่ปุ๋ย',
          'ใส่ปุ๋ยทำรุ่น': 'การใส่ปุ๋ย',
          'ใส่ปุ๋ยแต่งหน้า': 'การใส่ปุ๋ย',
          'ฉีดยาคุมวัชพืช': 'การจัดการวัชพืช',
          'ฉีดยาหลังวัชพืชงอก': 'การจัดการวัชพืช',
          'กำจัดวัชพืช': 'การจัดการวัชพืช',
          'เริ่มเก็บเกี่ยว': 'การเก็บเกี่ยว',
          'ขายผลผลิต': 'การเก็บเกี่ยว',
        };

        // นับจำนวน recommendation ในแต่ละกลุ่ม
        for (final rec in recommendations) {
          final topic = rec['topic'];
          if (topicToGroup.containsKey(topic)) {
            counts[topicToGroup[topic]!] = counts[topicToGroup[topic]!]! + 1;
          }
        }

        return {
          'recommendations': recommendations,
          'counts': counts,
        };
      } else {
        throw Exception(
            'Failed to load recommendations. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  // แสดง popup สำหรับแต่ละกลุ่ม
  void _showTopicPopup(
    BuildContext context,
    String groupTitle,
    List<TopicItem> topics,
    SoilAnalysisProvider provider,
    Color color,
    Map<String, bool> topicStatus,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final popupWidth = screenWidth * 0.9;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 20,
          insetPadding: EdgeInsets.symmetric(
            horizontal: (screenWidth - popupWidth) / 2,
            vertical: 20,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: popupWidth,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนหัวของ Popup
                Container(
                  padding: EdgeInsets.fromLTRB(24, 24, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // ชื่อหัวข้อ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupTitle,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "เลือกกิจกรรมที่ต้องการบันทึก",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ไอคอนปิด ขวา
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // รายการกิจกรรม
                Expanded(
                  child: ListView.builder(
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      final isSaved = topicStatus[topic.title] ?? false;

                      return InkWell(
                        onTap: () async {
                          Navigator.pop(context);

                          if (isSaved) {
                            setState(() => _isLoading = true);
                            try {
                              final response = await http.get(
                                Uri.parse(
                                    'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/recommendations/${topic.title}'),
                              );

                              if (response.statusCode == 200) {
                                final data = jsonDecode(response.body);
                                if (data == null || data['date'] == null) {
                                  throw Exception(
                                      'Invalid data format from API');
                                }
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnalyzeSoilScreen(
                                      userId: widget.userId,
                                      plotId: widget.plotId,
                                      topic: topic.title,
                                      date: data['date'],
                                      message: data['message'],
                                      images: (data['images'] as List<dynamic>)
                                          .where((path) =>
                                              path != null && path is String)
                                          .map((path) => File(path.toString()))
                                          .toList(),
                                      isEditing: true,
                                      canAssignTask: true,
                                      isWorker: false,
                                      onDataChanged: () =>
                                          _fetchRecommendations(), // Add this callback
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          } else {
                            final now = DateTime.now();
                            final formatter = DateFormat('dd/MM/yyyy');
                            final currentDate = formatter.format(now);

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnalyzeSoilScreen(
                                  plotId: widget.plotId,
                                  userId: widget.userId,
                                  topic: topic.title,
                                  date: currentDate,
                                  isEditing: false,
                                  canAssignTask: true,
                                  isWorker: false,
                                  onDataChanged: () =>
                                      _fetchRecommendations(), // Add this callback
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // เลขลำดับ
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isSaved
                                        ? [color, color.withOpacity(0.8)]
                                        : [
                                            Color(0xFF34D396).withOpacity(0.2),
                                            Color(0xFF34D396).withOpacity(0.1),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSaved
                                        ? color.withOpacity(0.3)
                                        : Color(0xFF34D396).withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: isSaved
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isSaved
                                          ? Colors.white
                                          : Color(0xFF25634B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 18),

                              // ไอคอนหัวข้อ
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSaved
                                      ? color.withOpacity(0.15)
                                      : color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSaved
                                        ? color.withOpacity(0.4)
                                        : color.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  TopicIcons.getIconForTopic(topic.title),
                                  color:
                                      isSaved ? color : color.withOpacity(0.8),
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: 18),

                              // รายละเอียดกิจกรรม
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSaved
                                            ? Color(0xFF1A202C)
                                            : Color(0xFF2D3748),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      topic.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 14),

                              // ไอคอนสถานะ
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isSaved
                                        ? [Colors.green, Colors.green.shade600]
                                        : [
                                            Colors.red.shade400,
                                            Colors.red.shade500
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSaved
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.red.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isSaved
                                      ? Icons.check_rounded
                                      : Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ส่วนท้าย (แสดงเมื่อยังไม่มีข้อมูล)
                if (topics.every((t) => !(topicStatus[t.title] ?? false)))
                  Container(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: Colors.grey.shade400,
                              size: 36,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "$groupTitle",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "ยังไม่มีข้อมูล",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
}

// คลาสเก็บข้อมูลหัวข้อ
class TopicItem {
  final String title;
  final IconData icon;
  final String description;
  final bool isCompleted; // เพิ่มฟิลด์สถานะการเสร็จสิ้น

  TopicItem(this.title, this.icon, this.description,
      {this.isCompleted = false});
}

// แท็บประวัติ
class HistoryTab extends StatefulWidget {
  final String plotId;
  final String userId;

  const HistoryTab({
    Key? key,
    required this.plotId,
    required this.userId,
  }) : super(key: key);

  @override
  _HistoryTabState createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<dynamic> _recommendations = [];
  bool _isLoading = false;
  Map<String, List<dynamic>> _groupedRecommendations = {};
  List<String> _groups = [
    'การเตรียมดิน',
    'การใส่ปุ๋ย',
    'การจัดการวัชพืช',
    'การเก็บเกี่ยว'
  ];
  Map<String, String> _workerNames = {}; // เก็บชื่อคนงาน

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/recommendations'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> recommendations = jsonDecode(response.body);

        // ดึงข้อมูล tasks เพื่อหาชื่อคนงาน
        final tasksResponse = await http.get(
          Uri.parse('https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/tasks'),
        );

        if (tasksResponse.statusCode == 200) {
          final tasks = jsonDecode(tasksResponse.body);
          await _fetchWorkerNames(tasks); // ดึงชื่อคนงาน
        }

        // จัดกลุ่มข้อมูลใหม่
        final Map<String, List<dynamic>> grouped = {
          'การเตรียมดิน': recommendations
              .where((rec) =>
                  rec['topic'].contains('ดิน') ||
                  rec['topic'].contains('ไถ') ||
                  rec['topic'].contains('บำรุง'))
              .toList(),
          'การใส่ปุ๋ย': recommendations
              .where((rec) => rec['topic'].contains('ปุ๋ย'))
              .toList(),
          'การจัดการวัชพืช': recommendations
              .where((rec) =>
                  rec['topic'].contains('วัชพืช') ||
                  rec['topic'].contains('ยาคุม') ||
                  rec['topic'].contains('กำจัด'))
              .toList(),
          'การเก็บเกี่ยว': recommendations
              .where((rec) =>
                  rec['topic'].contains('เก็บเกี่ยว') ||
                  rec['topic'].contains('ขาย'))
              .toList(),
        };

        setState(() {
          _recommendations = recommendations;
          _groupedRecommendations = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// ดึงชื่อคนงานจาก workerId
  Future<void> _fetchWorkerNames(List<dynamic> tasks) async {
    final workerIds = tasks
        .where((task) => task['assignedWorkerId'] != null)
        .map((task) => task['assignedWorkerId'].toString())
        .toSet()
        .toList();

    for (final workerId in workerIds) {
      try {
        final response = await http.get(
          Uri.parse('https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/workers/$workerId'),
        );

        if (response.statusCode == 200) {
          final workerData = jsonDecode(response.body);
          _workerNames[workerId] = workerData['name'] ?? 'ไม่ทราบชื่อ';
        }
      } catch (e) {
        print('Error fetching worker name: $e');
        _workerNames[workerId] = 'ไม่ทราบชื่อ';
      }
    }
  }

// ฟังก์ชันหาชื่อคนงานจาก task
  String _getWorkerNameForTask(String topic) {
    try {
      // หา task ที่เกี่ยวข้อง
      final relatedTask = _groupedRecommendations.entries
          .expand((entry) => entry.value)
          .firstWhere(
            (rec) => rec['topic'] == topic,
            orElse: () => null,
          );

      if (relatedTask != null) {
        // ในกรณีนี้เราอาจต้องปรับ logic ตามโครงสร้างข้อมูลจริง
        // อาจต้องมี field ที่เชื่อมโยงระหว่าง recommendation กับ task
        return _workerNames[relatedTask['assignedWorkerId']] ?? 'ไม่ทราบคนงาน';
      }
    } catch (e) {
      print('Error getting worker name: $e');
    }
    return 'ไม่ทราบคนงาน';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Text(
          "ยังไม่มีประวัติการบันทึกข้อมูล",
          style: TextStyle(color: Color(0xFF25634B)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRecommendations,
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, groupIndex) {
          final group = _groups[groupIndex];
          final items = _groupedRecommendations[group] ?? [];

          if (items.isEmpty) return SizedBox();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  group,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
              ),
              ...items.map((rec) {
                final workerName = _getWorkerNameForTask(rec['topic']);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF34D396).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        TopicIcons.getIconForTopic(rec['topic']),
                        color: Color(0xFF25634B),
                      ),
                    ),
                    title: Text(
                      rec['topic'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec['message'] ?? 'ไม่มีคำอธิบาย'),
                        SizedBox(height: 4),
                        Text(
                          rec['date'] ?? 'ไม่มีวันที่',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        if (workerName != 'ไม่ทราบคนงาน')
                          Text(
                            'ผู้ทำ: $workerName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing:
                        Icon(Icons.chevron_right, color: Color(0xFF34D396)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AnalyzeSoilScreen(
                                  plotId: widget.plotId,
                                  userId: widget.userId,
                                  topic: rec['topic'],
                                  date: rec['date'],
                                  message: rec['message'],
                                  images: (rec['images'] as List<dynamic>)
                                      .map((path) => File(path))
                                      .toList(),
                                  isEditing: true,
                                  canAssignTask: true,
                                  isWorker: false,
                                )),
                      ).then((shouldRefresh) {
                        if (shouldRefresh == true) {
                          _fetchRecommendations();
                        }
                      });
                    },
                  ),
                );
              }).toList(),
              SizedBox(height: groupIndex == _groups.length - 1 ? 16 : 0),
            ],
          );
        },
      ),
    );
  }
}

class AnalyzeSoilScreen extends StatefulWidget {
  final String plotId;
  final String userId;
  final String topic;
  final String? date;
  final List<File>? images;
  final String? message;
  final bool isEditing;
  final bool canAssignTask;
  final bool isWorker;
  final String? taskId; // ✅ เพิ่ม taskId
  final VoidCallback? onDataChanged;

  const AnalyzeSoilScreen({
    required this.plotId,
    required this.userId,
    required this.topic,
    this.canAssignTask = true,
    this.date,
    this.images,
    this.message = "",
    this.isEditing = false,
    this.isWorker = false,
    this.taskId, // ✅ เพิ่ม taskId
    this.onDataChanged,
    Key? key,
  }) : super(key: key);

  @override
  _AnalyzeSoilScreenState createState() => _AnalyzeSoilScreenState();
}

class _AnalyzeSoilScreenState extends State<AnalyzeSoilScreen> {
  late TextEditingController _dateController;
  late TextEditingController _messageController;
  List<File> _images = []; // เปลี่ยนจาก File? เป็น List<File>
  bool _isLoading = false;
  List<Map<String, dynamic>> _workers = [];
  String? _selectedWorkerId;
  bool _isLoadingWorkers = false;
  bool _isTaskAssigned = false; // เพิ่มตัวแปรตรวจสอบว่ามอบหมายงานแล้ว
  Map<String, dynamic>? _assignedWorker; // เก็บข้อมูลคนงานที่มอบหมายแล้ว

  Future<void> _fetchWorkers() async {
    if (_isTaskAssigned) return; // ไม่ต้องดึงถ้ามอบหมายแล้ว

    setState(() => _isLoadingWorkers = true);
    try {
      final response = await http.get(
        Uri.parse('https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/profile/workers/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userId}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _workers = List<Map<String, dynamic>>.from(data['workers'] ?? []);
          _isLoadingWorkers = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingWorkers = false);
    }
  }

  // เพิ่มตัวแปรนี้ใน class
  Map<String, dynamic>? _selectedWorker;

// แล้วใน _assignTask() ใช้ _selectedWorker โดยตรง
  Future<void> _assignTask() async {
    if (_selectedWorkerId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': widget.topic,
          'description': _messageController.text,
          'assignedWorkerId': _selectedWorkerId,
          'dueDate': _dateController.text,
          'images': _images.map((file) => file.path).toList(),
        }),
      );

      print('📤 Assign task response: ${response.statusCode}');
      print('📤 Assign task body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // อัปเดตสถานะว่ามอบหมายงานแล้ว
        setState(() {
          _isTaskAssigned = true;
        });

        // ดึงข้อมูลคนงานที่มอบหมายแล้ว
        _fetchAssignedWorkerInfo(_selectedWorkerId!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('มอบหมายงานให้ ${_selectedWorker?['name']} สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการมอบหมายงาน'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error assigning task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  // ฟังก์ชันอัพโหลดรูปภาพไปยัง server
  Future<List<String>> _uploadImages(List<String> imagePaths) async {
    List<String> imageUrls = [];
    var uri = Uri.parse('https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/upload');

    for (var imagePath in imagePaths) {
      try {
        var request = http.MultipartRequest('POST', uri);
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            filename: 'sugarcane_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);
          imageUrls.add(jsonResponse['imageUrl']);
          print('📤 Uploaded image: ${jsonResponse['imageUrl']}');
        } else {
          print('❌ Upload failed for $imagePath: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Error uploading $imagePath: $e');
      }
    }

    return imageUrls;
  }

  // ใน _HomeScreenState ของ sugarcanedata.dart
  Future<void> _saveData() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อความ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // อัพโหลดรูปภาพไปยัง server ก่อน
      List<String> uploadedImageUrls = [];
      if (_images.isNotEmpty) {
        uploadedImageUrls = await _uploadImages(_images.map((file) => file.path).toList());
      }

      final requestData = {
        'topic': widget.topic,
        'date': _dateController.text,
        'message': _messageController.text,
        'images': uploadedImageUrls, // ใช้ URL ที่อัพโหลดแล้ว
      };

      // ✅ บันทึก recommendation เสมอ
      final response = widget.isEditing
          ? await http.put(
              Uri.parse(
                  'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/recommendations/${widget.topic}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestData),
            )
          : await http.post(
              Uri.parse(
                  'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/recommendations'), // ✅ ต้องมี s
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestData),
            );

      print('📤 Save recommendation response: ${response.statusCode}');
      print('📤 Save recommendation body: ${response.body}');

      // ✅ ถ้าเป็นคนงานและมี taskId ให้อัปเดตสถานะงาน
      if (widget.isWorker && widget.taskId != null) {
        try {
          final taskResponse = await http.put(
            Uri.parse(
                'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/tasks/${widget.taskId}/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'status': 'completed',
              'completedAt': DateTime.now().toIso8601String()
            }),
          );

          if (taskResponse.statusCode == 200) {
            print('✅ Updated task status to completed');
          } else {
            print('❌ Failed to update task status: ${taskResponse.statusCode}');
          }
        } catch (e) {
          print('⚠️ Error updating task status: $e');
        }
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );

        // ✅ เรียก callback เพื่อแจ้งให้ parent screen รู้
        if (widget.onDataChanged != null) {
          widget.onDataChanged!();
        }

        Navigator.of(context).pop(true);
      } else {
        throw Exception(
            'Failed to save recommendation: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in _saveData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ยืนยันการลบ"),
          content: const Text("คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  final response = await http.delete(
                    Uri.parse(
                        'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/recommendations/${widget.topic}'),
                  );

                  if (response.statusCode == 200) {
                    // ✅ ถ้าเป็นคนงานและมี taskId ให้อัปเดตสถานะงาน
                    if (widget.isWorker && widget.taskId != null) {
                      await http.put(
                        Uri.parse(
                            'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/tasks/${widget.taskId}/status'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'status': 'completed',
                          'completedAt': DateTime.now().toIso8601String()
                        }),
                      );
                    }

                    Navigator.of(context).pop(true);
                  } else {
                    throw Exception('Failed to delete recommendation');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาดในการลบข้อมูล: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              },
              child: const Text("ลบ", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบข้อมูลสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.onDataChanged != null) {
        widget.onDataChanged!();
      }
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.date ?? "");
    _messageController = TextEditingController(text: widget.message ?? "");
    _images = widget.images ?? [];
    _fetchWorkers();
    _checkIfTaskAssigned();
    // ถ้าเป็นโหมดแก้ไขและไม่มีวันที่ ให้ใช้วันที่ปัจจุบัน
    if (widget.isEditing && widget.date == null) {
      final now = DateTime.now();
      final formatter = DateFormat('dd/MM/yyyy');
      _dateController.text = formatter.format(now);
    }
  }

  // ใน _checkIfTaskAssigned() ให้แก้ไขเป็น
  Future<void> _checkIfTaskAssigned() async {
    try {
      final response = await http.get(
        Uri.parse('https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.plotId}/tasks'),
      );

      if (response.statusCode == 200) {
        final tasks = jsonDecode(response.body);
        // หางานที่มี topic ตรงกับหน้าปัจจุบัน
        final existingTask = tasks.firstWhere(
          (task) => task['taskType'] == widget.topic,
          orElse: () => null,
        );

        if (existingTask != null) {
          setState(() {
            _isTaskAssigned = true;
            _selectedWorkerId = existingTask['assignedWorkerId'];
          });

          // ดึงข้อมูลคนงานที่มอบหมายแล้ว
          _fetchAssignedWorkerInfo(existingTask['assignedWorkerId']);

          // อัปเดตรายการคนงานโดยไม่แสดงคนที่มอบหมายแล้ว
          _updateWorkerList(existingTask['assignedWorkerId']);
        }
      }
    } catch (e) {
      print('Error checking task assignment: $e');
    }
  }

// ฟังก์ชันอัปเดตรายการคนงานโดยไม่แสดงคนที่มอบหมายแล้ว
  void _updateWorkerList(String assignedWorkerId) {
    setState(() {
      _workers = _workers
          .where((worker) => worker['_id'] != assignedWorkerId)
          .toList();
    });
  }

  Future<void> _fetchAssignedWorkerInfo(String workerId) async {
    try {
      final response = await http.get(
        Uri.parse('https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/workers/$workerId'),
      );

      if (response.statusCode == 200) {
        final workerData = jsonDecode(response.body);
        setState(() {
          _assignedWorker = workerData;
        });
      }
    } catch (e) {
      print('Error fetching worker info: $e');
    }
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
            physics: ClampingScrollPhysics(),
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
                            // ส่วนมอบหมายงาน (แสดงเฉพาะเมื่อ canAssignTask เป็น true)
                            if (widget.canAssignTask &&
                                !widget.isWorker &&
                                !_isTaskAssigned) ...[
                              Text(
                                "มอบหมายงานให้คนงาน",
                                style: TextStyle(
                                  color: Color(0xFF25634B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              _isLoadingWorkers
                                  ? Center(child: CircularProgressIndicator())
                                  : _workers.isEmpty
                                      ? Column(
                                          children: [
                                            Text('ไม่พบคนงานในระบบ'),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        WorkerScreen(
                                                            userId:
                                                                widget.userId),
                                                  ),
                                                );
                                                _fetchWorkers();
                                              },
                                              child: Text('จัดการคนงาน'),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            ConstrainedBox(
                                              constraints:
                                                  BoxConstraints(maxWidth: 300),
                                              child: DropdownButtonFormField<
                                                  String>(
                                                value: _selectedWorkerId,
                                                decoration: InputDecoration(
                                                  labelText: 'เลือกคนงาน',
                                                  border: OutlineInputBorder(),
                                                ),
                                                isExpanded: true,
                                                items: _workers.map((worker) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: worker['_id'],
                                                    child: Text(
                                                      worker['name'] ??
                                                          'ไม่ทราบชื่อ', // แสดงแค่ชื่อ
                                                      style: TextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedWorkerId = value;
                                                    _selectedWorker =
                                                        _workers.firstWhere(
                                                      (worker) =>
                                                          worker['_id'] ==
                                                          value,
                                                      orElse: () => {},
                                                    );
                                                  });
                                                },
                                              ),
                                            ),
                                            if (_selectedWorkerId != null)
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 16),
                                                child: ElevatedButton(
                                                  onPressed: _assignTask,
                                                  child: Text('มอบหมายงาน'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    minimumSize: Size(
                                                        double.infinity, 50),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                              SizedBox(height: 20),
                            ],
                            // แสดงสถานะเมื่อมอบหมายงานแล้ว
                            if (_isTaskAssigned && _assignedWorker != null)
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'มอบหมายงานแล้ว',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'ให้: ${_assignedWorker!['name']}',
                                            style: TextStyle(
                                                color: Colors.green[700]),
                                          ),
                                          if (_assignedWorker!['phone'] != null)
                                            Text(
                                              'โทร: ${_assignedWorker!['phone']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                  TextStyle(fontSize: 16, fontFamily: 'NotoSansThai'),
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
                                                child: _images[index].path.startsWith('http')
                                                    ? Image.network(
                                                        _images[index].path,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          print('❌ Sugarcane data image load error: $error');
                                                          print('❌ Failed URL: ${_images[index].path}');
                                                          return Container(
                                                            color: Colors.grey[200],
                                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                                          );
                                                        },
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) {
                                                            print('✅ Sugarcane data image loaded: ${_images[index].path}');
                                                            return child;
                                                          }
                                                          return Container(
                                                            color: Colors.grey[200],
                                                            child: Center(
                                                              child: CircularProgressIndicator(),
                                                            ),
                                                          );
                                                        },
                                                      )
                                                    : Image.file(
                                                        _images[index],
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            color: Colors.grey[200],
                                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                                          );
                                                        },
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
                child: images[index].path.startsWith('http')
                    ? Image.network(
                        images[index].path,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Sugarcane gallery image load error: $error');
                          print('❌ Failed URL: ${images[index].path}');
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey, size: 60),
                                  SizedBox(height: 16),
                                  Text('ไม่สามารถโหลดรูปภาพ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            print('✅ Sugarcane gallery image loaded: ${images[index].path}');
                            return child;
                          }
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      )
                    : Image.file(
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
                        child: analysis.images[index].path.startsWith('http')
                            ? Image.network(
                                analysis.images[index].path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('❌ Sugarcane analysis image load error: $error');
                                  print('❌ Failed URL: ${analysis.images[index].path}');
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    print('✅ Sugarcane analysis image loaded: ${analysis.images[index].path}');
                                    return child;
                                  }
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                analysis.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
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
