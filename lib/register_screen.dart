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

  bool _isLoading = false; // เพิ่มตัวแปร loading
  bool _isCheckingUsername = false; // เพิ่มตัวแปรสำหรับตรวจสอบ username
  String? _usernameError; // เพิ่มตัวแปรสำหรับแสดง error ของ username

  // ฟังก์ชันตรวจสอบ username แบบ real-time
  Future<void> _checkUsernameRealTime(String username) async {
    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    bool isAvailable = await _checkUsernameAvailability(username);
    
    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
        if (!isAvailable) {
          _usernameError = 'ชื่อผู้ใช้นี้ถูกใช้งานแล้ว';
        } else {
          _usernameError = null;
        }
      });
    }
  }

  // ฟังก์ชันตรวจสอบ username
  Future<bool> _checkUsernameAvailability(String username) async {
    try {
      print('🔍 กำลังตรวจสอบ username: $username');
      
      final response = await http.post(
        Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/check-username'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'username': username}),
      );
      
      print('📥 Username check response status: ${response.statusCode}');
      print('📥 Username check response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isAvailable = data['available'] ?? false;
        print('✅ Username available: $isAvailable');
        return isAvailable;
      } else {
        print('❌ Username check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Username check error: $e');
      return false;
    }
  }

  Future<void> _registerUser() async {
    if (_isLoading) return; // ป้องกันการกดซ้ำ
    
    setState(() {
      _isLoading = true;
    });

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
      setState(() {
        _isLoading = false;
      });
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
      setState(() {
        _isLoading = false;
      });
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

    // ตรวจสอบ username ก่อนสมัคร
    print('🔍 กำลังตรวจสอบ username: $username');
    
    // แสดง loading dialog ขณะตรวจสอบ username
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('กำลังตรวจสอบชื่อผู้ใช้...'),
          ],
        ),
      ),
    );
    
    bool isUsernameAvailable = await _checkUsernameAvailability(username);
    
    // ปิด loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    if (!isUsernameAvailable) {
      setState(() {
        _isLoading = false;
      });
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Text('ชื่อผู้ใช้ไม่ว่าง'),
              ],
            ),
            content: Text('ชื่อผู้ใช้ "$username" ถูกใช้งานแล้ว กรุณาเลือกชื่ออื่น'),
            actions: [
              TextButton(
                child: Text('ตกลง'),
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

    // แสดง loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('กำลังสมัครสมาชิก...'),
          ],
        ),
      ),
    );

    // ส่งข้อมูลไปยังเซิร์ฟเวอร์
    try {
      print('🔄 กำลังสมัครสมาชิก...');
      print('👤 Name: $name');
      print('📧 Email: $email');
      print('📞 Phone: $phone');
      print('👤 Username: $username');
      print('🔑 Password: $password');
      print('🔗 Relation Code: ${_relationCodeController.text.trim()}');
      print('🖼️ Has Image: ${selectedImage != null}');
      
      var uri = Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/register');
      var request = http.MultipartRequest('POST', uri);
      
      // เพิ่มข้อมูล fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['number'] = phone;
      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['relationCode'] = _relationCodeController.text.trim();
      
      // เพิ่มรูปภาพถ้ามี
      if (selectedImage != null) {
        print('📤 อัพโหลดรูป: ${selectedImage!.path}');
        request.files.add(await http.MultipartFile.fromPath('profileImage', selectedImage!.path));
      }
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: $responseBody');
      
      // ปิด loading dialog ก่อน
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        try {
          var responseData = json.decode(responseBody);
          print('✅ สมัครสมาชิกสำเร็จ: $responseData');
          
          setState(() {
            _isLoading = false;
          });
          
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
              print('❌ Error connecting relation code: $e');
              // แสดงข้อความแจ้งเตือนถ้าเชื่อมต่อไม่สำเร็จ
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('สมัครสมาชิกสำเร็จ แต่เชื่อมต่อรหัสความสัมพันธ์ไม่สำเร็จ'),
                ));
              }
            }
          }
          
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 10),
                      Text('สำเร็จ'),
                    ],
                  ),
                  content: Text('สมัครสมาชิกสำเร็จแล้ว'),
                  actions: [
                    TextButton(
                      child: Text('ตกลง'),
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
          }
        } catch (e) {
          print('❌ Error parsing response: $e');
          setState(() {
            _isLoading = false;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('เกิดข้อผิดพลาดในการประมวลผลข้อมูล'),
            ));
          }
        }
      } else {
        // สมัครสมาชิกไม่สำเร็จ
        print('❌ Registration failed with status: ${response.statusCode}');
        print('❌ Error response: $responseBody');
        setState(() {
          _isLoading = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('สมัครสมาชิกไม่สำเร็จ: ${response.statusCode}'),
          ));
        }
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e'),
        ));
      }
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
                            fontFamily: 'NotoSansThai',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'เชื่อมต่อกับเจ้าของไร่',
                              style: TextStyle(
                            fontFamily: 'NotoSansThai',
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
                            fontFamily: 'NotoSansThai',
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
                            fontFamily: 'NotoSansThai',
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
                            fontFamily: 'NotoSansThai',
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
                            fontFamily: 'NotoSansThai',
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
                            fontFamily: 'NotoSansThai',
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
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',fontWeight: FontWeight.bold, fontSize: 20),
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
                            child: Text('ปิด', style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 16)),
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
                            child: Text('บันทึก', style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 16)),
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
                            fontFamily: 'NotoSansThai',
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
                            fontFamily: 'NotoSansThai',
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
                    labelStyle: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey[500]),
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
                    labelStyle: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    errorText: _usernameError,
                    suffixIcon: _isCheckingUsername 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D396)),
                            ),
                          )
                        : _usernameError == null && _usernameController.text.isNotEmpty
                            ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                            : null,
                  ),
                  onChanged: (value) {
                    // ตรวจสอบ username แบบ real-time หลังจากผู้ใช้หยุดพิมพ์ 1 วินาที
                    Future.delayed(Duration(seconds: 1), () {
                      if (value == _usernameController.text) {
                        _checkUsernameRealTime(value);
                      }
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'อีเมล',
                    labelStyle: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey[500]),
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
                    labelStyle: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey[500]),
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
                    labelStyle: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey[500]),
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
                    labelStyle: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey[500]),
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
                            fontFamily: 'NotoSansThai',
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
                            fontFamily: 'NotoSansThai',
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
                      onPressed: (_isLoading || _isCheckingUsername || _usernameError != null) ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isLoading || _isCheckingUsername || _usernameError != null) ? Colors.grey : Color(0xFF34D396),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'กำลังสมัคร...',
                                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : _isCheckingUsername
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'กำลังตรวจสอบ...',
                                      style: TextStyle(
                                fontFamily: 'NotoSansThai',
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'ลงทะเบียน',
                                  style: TextStyle(
                                fontFamily: 'NotoSansThai',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                            fontFamily: 'NotoSansThai',
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
