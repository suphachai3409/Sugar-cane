import 'package:flutter/material.dart';
import 'plot1.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'weather_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  runApp(Menu1Screen(userId: '',));  // เพิ่ม runApp(MyApp()) ตรงนี้เพื่อให้แอปเริ่มทำงาน
}

class Menu1Screen extends StatefulWidget {
  final String userId; // เพิ่มตรงนี้

  Menu1Screen({required this.userId}); // รับ userId ผ่าน constructor

  @override
  _Menu1ScreenState createState() => _Menu1ScreenState();
}

class _Menu1ScreenState extends State<Menu1Screen> {
  final String apiUrl = 'http://10.0.2.2:3000/pulluser';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
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
          // ถ้ามี userId ให้หาข้อมูลผู้ใช้นั้น ถ้าไม่มีให้ใช้คนแรก
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
                  value: 'Menu ${_currentUser!['menu']?.toString() ?? 'ไม่ระบุ'}',
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    return MaterialApp(
      title: 'Farm Management App',
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
      home: Scaffold(
        appBar: AppBar(
          title: Text('เจ้าของ'),
        ),
        body: Stack(
          children: [
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D396)),
                  ),
                ),
              ),
            
            Padding(
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
                    left: width * 0.055,
                    child: const WeatherWidget(),
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
                          fontSize: width * 0.055, // 5% ของความกว้างหน้าจอ
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  //แปลงไร่
                  Positioned(
                    top: height * 0.36,
                    left: width * 0.06,
                    child: GestureDetector(
                      onTap: () {
                        // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Plot1Screen(userId: widget.userId)), // ไปหน้า Plot1
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
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // คนงาน
                  Positioned(
                    top: height * 0.36,
                    right: width * 0.06,
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
                                'assets/worker.jpg',
                                fit: BoxFit.cover,
                                width: 149,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'คนงาน',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  //ลูกไร่
                  Positioned(
                    top: height * 0.57,
                    left: width * 0.06,
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
                                'assets/human1.png',
                                fit: BoxFit.cover,
                                width: 149,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'ลูกไร่',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  //อุปกรณ์
                  Positioned(
                    top: height * 0.57,
                    right: width * 0.06,
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
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
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
                          padding: EdgeInsets.all(6), // เพิ่มระยะห่างจากขอบ (ลองปรับค่านี้ได้)
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
                          padding: EdgeInsets.all(6), // เพิ่มระยะห่างจากขอบ (ลองปรับค่านี้ได้)
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(38),
                            child: _isLoading
                                ? Container(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
          ],
        ),
      ),
    );
  }
}