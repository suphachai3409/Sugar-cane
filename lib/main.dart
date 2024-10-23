import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'package:http/http.dart' as http;  // สำหรับเชื่อมต่อกับ API
import 'dart:convert';  // สำหรับแปลงข้อมูล JSON
import 'menu1.dart';    // Import menu1.dart

void main() {
  runApp(MyApp());  // เพิ่ม runApp(MyApp()) ตรงนี้เพื่อให้แอปเริ่มทำงาน
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
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

  // ฟังก์ชันเชื่อมต่อกับ MongoDB ผ่าน API
  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // ตรวจสอบว่ากรอกข้อมูลครบหรือไม่
    if (username.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('กรุณากรอกข้อมูลให้ครบ'),
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

      // แสดง response body เพื่อดูข้อความที่ส่งกลับจากเซิร์ฟเวอร์
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // ตรวจสอบ response status code ว่าล็อกอินสำเร็จหรือไม่
      if (response.statusCode == 200) {
        // ล็อกอินสำเร็จ, เปลี่ยนไปหน้าเมนู
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Menu1Screen()),  // ไปที่หน้า Menu1Screen
        );
      } else if (response.statusCode == 401) {
        // ล็อกอินไม่สำเร็จ (เช่น รหัสผ่านผิด)
        setState(() {
          _errorMessage = 'Username หรือ Password ไม่ถูกต้อง';
        });
      } else {
        // เกิดข้อผิดพลาดอื่นๆ
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาดในการล็อกอิน: ${response.statusCode}';
        });
      }
    } catch (error) {
      // แสดงข้อความข้อผิดพลาดหากเกิดข้อผิดพลาดในการเชื่อมต่อ API
      setState(() {
        _errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์: $error';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,  // เรียกใช้ฟังก์ชัน login เมื่อกดปุ่มนี้
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text('สมัครสมาชิก'),
            ),
          ],
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
