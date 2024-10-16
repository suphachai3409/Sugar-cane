import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _callnumberController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();


  Future<void> _registerUser() async {
    final String username = _nameController.text;
    final String email = _emailController.text;
    final String number = _callnumberController.text;
    final String name = _usernameController.text;
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;


    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _callnumberController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
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
    // ตรวจสอบว่า password และ confirm password ตรงกัน
    if (password != confirmPassword) {
      // แจ้งเตือนเมื่อ password ไม่ตรงกัน
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('รหัสผ่านและยืนยันรหัสผ่านไม่ตรงกัน'),
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

    // สร้างข้อมูลที่จะส่ง
    final Map<String, dynamic> requestBody = {
      'name': name,
      'email': email,
      'number' : number,
      'username': username,
      'password': password,
    };

    // ส่งข้อมูลไปยังเซิร์ฟเวอร์
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      // สมัครสมาชิกสำเร็จ
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('susess'),
            content: Text('สมัครสมาชิกสำเร็จ'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  // นำผู้ใช้กลับไปหน้า LoginScreen (หรือหน้าแรก)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    // กลับไปหน้า LoginScreen
                        (Route<
                        dynamic> route) => false, // ลบ stack ของหน้าอื่นๆ เพื่อกลับไปหน้าแรก
                  );

                  
                  _nameController.clear();
                  _emailController.clear();
                  _callnumberController.clear();
                  _usernameController.clear();
                  _passwordController.clear();
                  _confirmPasswordController.clear();
                },
              ),
            ],
          );
        },
      );
    }

     else {
      // สมัครสมาชิกไม่สำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'ชื่อ-สกุล'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'email'),
            ),
            TextField(
              controller: _callnumberController,
              decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser, // เมื่อกดจะเรียกใช้ฟังก์ชันนี้
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
