import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'package:http/http.dart' as http;  // สำหรับเชื่อมต่อกับ API
import 'dart:convert';  // สำหรับแปลงข้อมูล JSON
import 'menu1.dart';
import 'menu2.dart';
import 'menu3.dart';    // Import menu1.dart
import 'datahuman.dart'; // เพิ่มไฟล์ datahuman.dart ที่คุณเขียนไว้

void main() {
  runApp(MyApp());  // เพิ่ม runApp(MyApp()) ตรงนี้เพื่อให้แอปเริ่มทำงาน
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบบริหารจัดการไร่อ้อย',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Color(0xFF2D8C8A),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF2D8C8A),
          secondary: Color(0xFF4CAF50),
        ),
        textTheme: TextTheme(
          headlineMedium: TextStyle(
            color: Color(0xFF2D8C8A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: LoginScreen(),
      routes: {
        '/menu1': (context) => Menu1Screen(userId: '',), // เส้นทางหน้า Menu 1
        '/menu2': (context) => Menu2Screen(userId: '',), // เส้นทางหน้า Menu 2
        '/menu3': (context) => Menu3Screen(userId: '',), // เส้นทางหน้า Menu 3
        '/register': (context) => RegisterScreen(), // ✅ เพิ่มเส้นทางหน้า Register
        '/datahuman': (context) => DataHumanScreen(), // ✅ เพิ่มเส้นทางหน้า DataHuman
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ให้แสดงหน้า Splash 2 วินาทีแล้วเปลี่ยนไปหน้า Login
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // โลโก้วงกลมสีเขียว
              Image.asset(
                'assets/logo.png',
                width: 180,
                height: 180,
                // ถ้าไม่มีไฟล์โลโก้ ให้ใช้ CircleAvatar แทน
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 180,
                    height: 180,
                    child: Image.network(
                      'https://via.placeholder.com/180',
                      errorBuilder: (context, error, stackTrace) {
                        return CircleAvatar(
                          radius: 90,
                          backgroundColor: Colors.white,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.home,
                                size: 70,
                                color: Color(0xFF2D8C8A),
                              ),
                              Positioned(
                                top: 30,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                        (index) => Container(
                                      margin: EdgeInsets.symmetric(horizontal: 2),
                                      child: Icon(
                                        Icons.grass,
                                        size: 20,
                                        color: Color(0xFF4AC1A2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              Text(
                'ระบบบริหารจัดการไร่อ้อย',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D8C8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('แจ้งเตือน'),
            content: Text('กรุณาใส่ ชื่อผู้ใช้ และ รหัสผ่าน ก่อนเข้าสู่ระบบ'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      // ส่งข้อมูลไปยังเซิร์ฟเวอร์เพื่อตรวจสอบ
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userMenu = data['user']['menu'];
        final userId = data['user']['_id']; // ✅ เพิ่มตรงนี้ เพื่อดึง ObjectId จาก MongoDB

        // Debug
        print('Received menu: $userMenu');
        print('Received userId: $userId');

        if (userMenu == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Menu1Screen(userId: userId)), // ✅ ส่ง userId ไป
          );
        } else if (userMenu == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Menu2Screen(userId: userId)),
          );
        } else if (userMenu == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Menu3Screen(userId: userId)),
          );
        } else {
          print('Invalid menu value received: $userMenu');
        }
      } else if (response.statusCode == 401) {
        _showErrorDialog('Username หรือ Password ไม่ถูกต้อง');
      } else {
        _showErrorDialog('เกิดข้อผิดพลาดในการล็อกอิน: ${response.statusCode}');
      }
    } catch (error) {
      _showErrorDialog('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์: $error');
    }
  }

// ฟังก์ชันสำหรับแสดงข้อผิดพลาดใน AlertDialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('แจ้งเตือน'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // โลโก้วงกลมสีเขียว
                  Image.asset(
                    'assets/logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.network(
                          'https://via.placeholder.com/120',
                          errorBuilder: (context, error, stackTrace) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    Icons.home,
                                    size: 50,
                                    color: Color(0xFF2D8C8A),
                                  ),
                                ),
                                Positioned(
                                  top: 25,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      5,
                                          (index) => Container(
                                        margin: EdgeInsets.symmetric(horizontal: 1),
                                        child: Icon(
                                          Icons.grass,
                                          size: 14,
                                          color: Color(0xFF4AC1A2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 40),

                  // Input field for username with light gray background
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'ชื่อผู้ใช้',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Input field for password with light gray background
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'รหัสผ่าน',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      obscureText: true,
                    ),
                  ),
                  SizedBox(height: 20),

                  // แสดงข้อความแสดงข้อผิดพลาด
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(height: 10),

                  // ปุ่มเข้าสู่ระบบ
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34D396),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // ลิงก์ "ยังไม่มีบัญชีผู้ใช้?"
                  TextButton(
                    onPressed: () {
                      // ✅ ใช้ Navigator.pushNamed ตอนนี้ใช้ได้แล้ว เพราะมี routes แล้ว
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      'ยังไม่มีบัญชีผู้ใช้?',
                      style: TextStyle(
                        color: Color(0xFF25634B),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  // ปุ่มไปที่หน้าข้อมูลสมาชิก (DataHuman)
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // ✅ ใช้ Navigator.pushNamed ตอนนี้ใช้ได้แล้ว เพราะมี routes แล้ว
                      Navigator.pushNamed(context, '/datahuman');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2D8C8A),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ไปที่หน้าข้อมูลสมาชิก (DataHuman)',
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}