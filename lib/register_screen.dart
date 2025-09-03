import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _relationCodeController = TextEditingController();
  File? selectedImage; // เพิ่มตัวแปรสำหรับเก็บรูปที่เลือก
  String? selectedRelationType; // เพิ่มตัวแปรสำหรับเก็บประเภทความสัมพันธ์

  Future<void> _registerUser() async {
    final String phone = _phoneController.text;
    final String name = _nameController.text;
    final String email = _emailController.text;
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (_phoneController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('แจ้งเตือน'),
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
            title: Text('แจ้งเตือน'),
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
      'number': phone,
      'username': username,
      'password': password,
      'relationCode': _relationCodeController.text.trim(), // เพิ่มรหัสความสัมพันธ์
    };

    // ส่งข้อมูลไปยังเซิร์ฟเวอร์
    try {
      var uri = Uri.parse('http://10.0.2.2:3000/register');
      var request = http.MultipartRequest('POST', uri);
      
      // เพิ่มข้อมูล fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['number'] = phone;
      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['relationCode'] = _relationCodeController.text.trim();
      
      print('=== SENDING REGISTER DATA ===');
      print('Name: $name');
      print('Email: $email');
      print('Number: $phone');
      print('Username: $username');
      print('Password: $password');
      print('Relation Code: ${_relationCodeController.text.trim()}');
      print('Has Image: ${selectedImage != null}');
      
      // เพิ่มรูปภาพถ้ามี
      if (selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath('profileImage', selectedImage!.path));
        print('Image path: ${selectedImage!.path}');
      }
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 200) {
        try {
          var responseData = json.decode(responseBody);
          print('Parsed response: $responseData');
          
          // เชื่อมต่อรหัสความสัมพันธ์ถ้ามี
          if (_relationCodeController.text.isNotEmpty && selectedRelationType != null) {
            try {
              // สร้าง user object จากข้อมูลที่สมัครเสร็จแล้ว
              Map<String, dynamic> newUser = {
                '_id': responseData['user']['_id'], // ใช้ ID จริงจาก backend
                'name': name,
                'email': email,
                'number': phone,
                'username': username,
              };
              
              // เชื่อมต่อรหัสความสัมพันธ์
              await connectRelationCode(context, _relationCodeController.text, selectedRelationType!, newUser);
            } catch (e) {
              print('Error connecting relation code: $e');
              // แสดงข้อความแจ้งเตือนถ้าเชื่อมต่อไม่สำเร็จ
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('สมัครสมาชิกสำเร็จ แต่เชื่อมต่อรหัสความสัมพันธ์ไม่สำเร็จ'),
              ));
            }
          }
          
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('สำเร็จ'),
                content: Text('สมัครสมาชิกสำเร็จ'),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      // นำผู้ใช้กลับไปหน้า LoginScreen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (Route<dynamic> route) => false,
                      );

                      _phoneController.clear();
                      _nameController.clear();
                      _emailController.clear();
                      _usernameController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _relationCodeController.clear();
                      selectedImage = null; // เคลียร์รูปที่เลือก
                      selectedRelationType = null; // เคลียร์ประเภทความสัมพันธ์
                    },
                  ),
                ],
              );
            },
          );
        } catch (e) {
          print('Error parsing response: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาดในการประมวลผลข้อมูล'),
          ));
        }
      } else {
        // สมัครสมาชิกไม่สำเร็จ
        print('Registration failed with status: ${response.statusCode}');
        print('Error response: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('สมัครสมาชิกไม่สำเร็จ: ${response.statusCode}'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
      ));
    }
  }

  // ฟังก์ชันแสดง Dialog ช่วยเหลือเกี่ยวกับรหัสความสัมพันธ์
  void _showRelationCodeHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
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
                      Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รหัสความสัมพันธ์',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'เชื่อมต่อกับเจ้าของไร่',
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
                Text(
                  'รหัสความสัมพันธ์คืออะไร?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'รหัสความสัมพันธ์เป็นรหัสที่เจ้าของไร่สร้างขึ้นเพื่อให้คุณสามารถเชื่อมต่อกับไร่ของเขาได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[700],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'หากคุณไม่มีรหัส สามารถข้ามขั้นตอนนี้ได้',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'ปิด',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showRelationCodeInputDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'กรอกรหัส',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ฟังก์ชันแสดง Dialog สำหรับกรอกรหัสความสัมพันธ์ (ใช้ฟังก์ชันจาก profile.dart)
  void _showRelationCodeInputDialog(BuildContext context) {
    TextEditingController codeController = TextEditingController();
    String selectedType = 'worker'; // default

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vpn_key, color: Color(0xFF34D396), size: 40),
                    SizedBox(height: 10),
                    Text(
                      'กรอกรหัสความสัมพันธ์',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    SizedBox(height: 16),
                    // ปุ่มเลือกประเภท
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text('คนงาน'),
                          selected: selectedType == 'worker',
                          onSelected: (val) {
                            setState(() => selectedType = 'worker');
                          },
                          selectedColor: Color(0xFF34D396),
                        ),
                        SizedBox(width: 12),
                        ChoiceChip(
                          label: Text('ลูกไร่'),
                          selected: selectedType == 'farmer',
                          onSelected: (val) {
                            setState(() => selectedType = 'farmer');
                          },
                          selectedColor: Colors.amber,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: 'รหัสความสัมพันธ์',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'กรอกรหัสที่ได้รับจากเจ้าของไร่',
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('ปิด', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              _relationCodeController.text = codeController.text;
                              selectedRelationType = selectedType; // เก็บประเภทที่เลือก
                              setState(() {}); // อัพเดต UI เพื่อแสดงรหัสที่กรอกแล้ว
                              Navigator.of(context).pop();
                              // ไม่เรียก connectRelationCode ที่นี่ เพราะยังไม่มี user ID จริง
                              // จะเชื่อมต่อหลังจากสมัครสมาชิกเสร็จแล้ว
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF34D396),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('บันทึก', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Text(
                  'สมัครสมาชิก',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                // เพิ่มส่วนเลือกรูปภาพ
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() {
                          selectedImage = File(picked.path);
                        });
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF34D396),
                          width: 3,
                        ),
                        color: Colors.grey[100],
                      ),
                      child: selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Color(0xFF34D396),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'เลือกรูปภาพ',
                                  style: TextStyle(
                                    color: Color(0xFF34D396),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อ-สกุล',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ใช้',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'อีเมล',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,

                ),
                SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    // เพิ่ม counter เพื่อแสดงจำนวนตัวอักษรที่พิมพ์
                    errorText: _phoneController.text.length > 10 ? 'เบอร์โทรศัพท์ต้องมี 10 หลัก' : null,
                  ),
                  // จำกัดให้รับเฉพาะตัวเลขและไม่เกิน 10 ตัว
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  // อัพเดต counter เมื่อมีการพิมพ์
                  onChanged: (value) {
                    setState(() {
                      // เพื่ออัพเดต counterText
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 16),
                // ปุ่มสำหรับรหัสความสัมพันธ์
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showRelationCodeInputDialog(context);
                    },
                    icon: Icon(
                      Icons.vpn_key,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      _relationCodeController.text.isEmpty 
                          ? 'กรอกรหัสความสัมพันธ์ (ไม่บังคับ)'
                          : 'รหัสความสัมพันธ์: ${_relationCodeController.text}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _relationCodeController.text.isEmpty 
                          ? Color(0xFF34D396) 
                          : Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // ปุ่มช่วยเหลือสำหรับรหัสความสัมพันธ์
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _showRelationCodeHelpDialog(context);
                      },
                      child: Text(
                        'ไม่ทราบรหัสความสัมพันธ์?',
                        style: TextStyle(
                          color: Color(0xFF34D396),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: 150, // คุณสามารถปรับค่านี้ได้ตามขนาดที่ต้องการ
                    child: ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF34D396),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('ลงทะเบียน',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      color: Color(0xFF25634B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
