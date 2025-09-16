import 'package:flutter/material.dart';
import 'plot3.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'weather_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert'; // เพิ่ม import สำหรับ jsonDecode
import 'package:http/http.dart' as http; // เพิ่ม import สำหรับ http
import 'equipment.dart';
import 'moneytransfer.dart';
import 'profile.dart';
import 'WorkerTasksScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Management App',
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
      home: Menu3Screen(userId: ''),
    );
  }
}

class Menu3Screen extends StatefulWidget {
  final String userId;
  const Menu3Screen({Key? key, required this.userId}) : super(key: key);

  @override
  _Menu3ScreenState createState() => _Menu3ScreenState();
}

class _Menu3ScreenState extends State<Menu3Screen> {
  final String apiUrl = 'https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/pulluser';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _workerId;
  String? _ownerId;
  bool _isLoadingOwner = false;
  int _plotCount = 0;
  List<Map<String, dynamic>> plotList = [];
  @override
  void initState() {
    super.initState();
    _fetchOwnerData();
  }

  Future<void> _loadPlotData() async {
    try {
      // ใช้ ownerId ที่ดึงมาจาก _fetchOwnerData
      if (_ownerId != null) {
        final response = await http.get(
          Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/plots/$_ownerId'),
          headers: {"Content-Type": "application/json"},
        );

        if (response.statusCode == 200) {
          final List<dynamic> plots = jsonDecode(response.body);
          setState(() {
            plotList = plots.cast<Map<String, dynamic>>();
            _plotCount = plots.length;
          });
          print('✅ Loaded ${plots.length} plots for owner: $_ownerId');
        } else {
          print('❌ Error loading plot data: ${response.statusCode}');
          setState(() {
            plotList = [];
            _plotCount = 0;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading plot data: $e');
      setState(() {
        plotList = [];
        _plotCount = 0;
      });
    }
  }

  // ใน menu3.dart
  Future<void> _fetchOwnerData() async {
    try {
      final response = await http.get(
        Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/plots/owner/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['ownerId'] != null) {
          setState(() {
            _ownerId = data['ownerId']; // ได้ ownerId มาครบถ้วน
          });
          await _fetchPlotCount();
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchPlotCount() async {
    if (_ownerId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/plots/count/$_ownerId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _plotCount = data['count'] ?? 0;
        });
        print('✅ Plot count: $_plotCount');
      }
    } catch (e) {
      print('❌ Error fetching plot count: $e');
    }
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

  Future<int> _fetchTaskCount() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/profile/worker-tasks/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final tasks = jsonDecode(response.body);
        return tasks.length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('คนงาน'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Container เขียว
            Positioned(
              top: height * 0.3, // 30% ของความสูงหน้าจอ
              left: 0,
              right: 0,
              child: Container(
                width: width * 0.9, // 90% ของความกว้างหน้าจอ
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            // Container ฟ้า
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

            // Text 'Main menu'
            Positioned(
              top: height * 0.31, // 31% ของความสูงหน้าจอ
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Main menu',
                  style: TextStyle(
                    color: Color(0xFF25624B),
                    fontSize: width * 0.06, // 5% ของความกว้างหน้าจอ
                    fontFamily: 'NotoSansThai',
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(-1, -1),
                        blurRadius: 2,
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(1, -1),
                        blurRadius: 2,
                        color: Colors.white,
                      ),
                      Shadow(
                        offset: Offset(-1, 1),
                        blurRadius: 2,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // แปลงปลูก (ซ้ายบน)
            Positioned(
              top: height * 0.36,
              left: width * 0.06,
              child: GestureDetector(
                onTap: () async {
                  // ดึง ownerId ของคนงานก่อน
                  String? ownerId;
                  try {
                    final response = await http.get(
                      Uri.parse(
                          'https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/profile/worker-info/${widget.userId}'),
                      headers: {"Content-Type": "application/json"},
                    );

                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);
                      if (data['success'] == true && data['worker'] != null) {
                        ownerId = data['worker']['ownerId'];
                        print('🔍 DEBUG: ดึง ownerId สำเร็จ: $ownerId');
                      }
                    }
                  } catch (e) {
                    print('❌ Error getting ownerId: $e');
                  }

                  // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Plot3Screen(
                            userId: widget.userId, ownerId: ownerId)),
                  );
                },
                child: Container(
                  height: height * 0.165,
                  width: width * 0.36,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.asset(
                                'assets/kid.png',
                                fit: BoxFit.cover,
                                width: 149,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'แปลงปลูก',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF25624B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoadingOwner)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (_plotCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                _plotCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // รับงาน (ขวาบน)
            Positioned(
              top: height * 0.36,
              right: width * 0.06,
              child: GestureDetector(
                onTap: () {
                  print(
                      '🚀 Navigating to WorkerTasksScreen with user ID: ${widget.userId}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkerTasksScreen(userId: widget.userId),
                    ),
                  );
                },
                child: Container(
                  height: height * 0.165,
                  width: width * 0.36,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.asset(
                                'assets/ประวัติ.png', // เปลี่ยนเป็น path ของรูปภาพงาน
                                fit: BoxFit.cover,
                                width: 149,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'รับงาน',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF25624B),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Badge แสดงจำนวนงาน
                        if (_workerId != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FutureBuilder(
                              future: _fetchTaskCount(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data! > 0) {
                                  return Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      snapshot.data.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return SizedBox();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // อุปกรณ์ (ซ้ายล่าง)
            Positioned(
              top: height * 0.57,
              left: width * 0.06,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            EquipmentScreen(userId: widget.userId)),
                  );
                },
                child: Container(
                  height: height * 0.165,
                  width: width * 0.36,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/trackter.png',
                            fit: BoxFit.cover,
                            width: 149,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'อุปกรณ์',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25624B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            //เบิกเงินทุน (ขวาล่าง)
            Positioned(
              top: height * 0.57,
              right: width * 0.06,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            moneytransferScreen(userId: widget.userId)),
                  );
                },
                child: Container(
                  height: height * 0.165,
                  width: width * 0.36,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/money.png',
                            fit: BoxFit.cover,
                            width: 149,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'ขอเบิกเงินทุน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25624B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Container ปุ่ม
            Positioned(
              bottom: height * 0, // 2% จากด้านล่าง
              left: width * 0.03, // 3% จากด้านซ้าย
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
                           if (_currentUser?['menu'] == 3) {
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