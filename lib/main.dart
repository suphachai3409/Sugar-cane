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
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
      routes: {
        '/menu1': (context) => Menu1Screen(userId: '',), // เส้นทางหน้า Menu 1
        '/menu2': (context) => Menu2Screen(userId: '',), // เส้นทางหน้า Menu 2
        '/menu3': (context) => Menu3Screen(userId: '',), // เส้นทางหน้า Menu 3
      },
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
          title: Text('Error'),
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
            SizedBox(height: 20), // เพิ่มพื้นที่ว่าง
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DataHumanScreen()),
                );
              },
              child: Text('ไปที่หน้าข้อมูลสมาชิก (DataHuman)'),
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
