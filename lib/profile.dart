import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

// ฟังก์ชันตรวจสอบสถานะของรูปภาพ
Future<bool> _checkImageUrl(String url) async {
  try {
    final response = await http.head(Uri.parse(url));
    return response.statusCode == 200;
  } catch (e) {
    print('❌ Error checking image URL: $e');
    return false;
  }
}

Future<void> showProfileDialog(BuildContext context, Map<String, dynamic> user,
    {VoidCallback? refreshUser}) async {
  void showEditProfileDialog() {
    final nameController = TextEditingController(text: user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController =
        TextEditingController(text: user['number']?.toString() ?? '');
    File? tempSelectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (picked != null) {
                                setStateDialog(() {
                                  tempSelectedImage = File(picked.path);
                                });
                              }
                            },
                            child: tempSelectedImage != null
                                ? CircleAvatar(
                                    radius: 30,
                                    backgroundImage:
                                        FileImage(tempSelectedImage!),
                                    backgroundColor: Colors.white,
                                  )
                                : (user['profileImage'] != null &&
                                        user['profileImage']
                                            .toString()
                                            .isNotEmpty)
                                    ? CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(
                                            'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/uploads/${user['profileImage']}'),
                                        backgroundColor: Colors.white,
                                      )
                                    : CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.add_a_photo,
                                          size: 35,
                                          color: Color(0xFF34D396),
                                        ),
                                      ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'แก้ไขโปรไฟล์',
                                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ข้อมูลส่วนตัว',
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
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'เบอร์โทร',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF34D396),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // แสดง loading dialog
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 20),
                                      Text('กำลังบันทึกข้อมูล...'),
                                    ],
                                  ),
                                ),
                              );
                              
                              try {
                                print('🔄 กำลังอัพเดตข้อมูลผู้ใช้...');
                                print('👤 User ID: ${user['_id']}');
                                print('📝 Name: ${nameController.text}');
                                print('📧 Email: ${emailController.text}');
                                print('📞 Phone: ${phoneController.text}');
                                print('🖼️ Has Image: ${tempSelectedImage != null}');
                                
                                // อัปเดตข้อมูลและอัปโหลดรูปไป backend
                                var uri = Uri.parse(
                                    'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/updateuser/${user['_id']}');
                                var request = http.MultipartRequest('PUT', uri);
                                request.fields['name'] = nameController.text;
                                request.fields['email'] = emailController.text;
                                request.fields['number'] = phoneController.text;
                                
                                if (tempSelectedImage != null) {
                                  print('📤 อัพโหลดรูป: ${tempSelectedImage!.path}');
                                  request.files.add(
                                      await http.MultipartFile.fromPath(
                                          'profileImage',
                                          tempSelectedImage!.path));
                                }
                                
                                var response = await request.send();
                                print('📥 Response status: ${response.statusCode}');
                                
                                // ปิด loading dialog ก่อน
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                
                                if (response.statusCode == 200) {
                                  print('✅ อัปเดตข้อมูลสำเร็จ');
                                  if (refreshUser != null) refreshUser();
                                  
                                  // แสดง success dialog
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 28),
                                            SizedBox(width: 10),
                                            Text('สำเร็จ'),
                                          ],
                                        ),
                                        content: Text('บันทึกข้อมูลสำเร็จแล้ว'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // ปิด success dialog
                                              Navigator.of(context).pop(); // ปิด edit dialog
                                            },
                                            child: Text('ตกลง'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } else {
                                  print('❌ อัปเดตข้อมูลไม่สำเร็จ: ${response.statusCode}');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print('❌ Exception: $e');
                                // ปิด loading dialog ก่อน
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('เกิดข้อผิดพลาด: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'บันทึก',
                              style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                fontSize: 16,
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
      },
    );
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
          child: Stack(
            children: [
              // ปุ่มปิด (X) บนขวา
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Column(
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
                        // Debug: แสดงข้อมูล user
                        Builder(
                          builder: (context) {
                            print('🔍 DEBUG Profile Image:');
                            print('   - user: $user');
                            print('   - profileImage: ${user['profileImage']}');
                            print('   - imageprofile: ${user['imageprofile']}');
                            print('   - profileImage type: ${user['profileImage'].runtimeType}');
                            print('   - imageprofile type: ${user['imageprofile'].runtimeType}');
                            return SizedBox.shrink();
                          },
                        ),
                        (() {
                          // ตรวจสอบทั้ง profileImage และ imageprofile
                          final profileImage = user['profileImage'] ?? user['imageprofile'];
                          final hasImage = profileImage != null &&
                              profileImage.toString().isNotEmpty;
                          print('🔍 Profile image condition: $hasImage');
                          print('🔍 Using image: $profileImage');
                          
                          // ตรวจสอบสถานะของรูปภาพถ้าเป็น Cloudinary URL
                          if (hasImage && profileImage.toString().contains('res.cloudinary.com')) {
                            _checkImageUrl(profileImage.toString()).then((isValid) {
                              if (!isValid) {
                                print('⚠️ Cloudinary image URL is not accessible: $profileImage');
                              }
                            });
                          }
                          
                          return hasImage;
                        })()
                            ? ClipOval(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Image.network(
                                    (() {
                                      final imageUrl = user['profileImage'] ?? user['imageprofile'];
                                      print('🔍 Profile image URL: $imageUrl');
                                      // ตรวจสอบว่าเป็น Cloudinary URL หรือไม่
                                      if (imageUrl.toString().startsWith('http')) {
                                        print('✅ Using Cloudinary URL: $imageUrl');
                                        return imageUrl.toString();
                                      }
                                      // ถ้าไม่ใช่ ให้ใช้ local uploads
                                      final localUrl = 'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/uploads/$imageUrl';
                                      print('✅ Using local URL: $localUrl');
                                      return localUrl;
                                    })(),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      final imageUrl = user['profileImage'] ?? user['imageprofile'];
                                      print('❌ Error loading profile image: $error');
                                      print('❌ Stack trace: $stackTrace');
                                      print('❌ Failed URL: $imageUrl');
                                      
                                      // ลองใช้ fallback URL ถ้าเป็น Cloudinary URL
                                      if (imageUrl.toString().contains('res.cloudinary.com')) {
                                        print('🔄 Trying fallback for Cloudinary URL...');
                                        return Image.network(
                                          imageUrl.toString(),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error2, stackTrace2) {
                                            print('❌ Fallback also failed: $error2');
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                size: 35,
                                                color: Color(0xFF34D396),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 35,
                                          color: Color(0xFF34D396),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) {
                                        print('✅ Profile image loaded successfully');
                                        return child;
                                      }
                                      print('🔄 Loading profile image...');
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D396)),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : CircleAvatar(
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
                            fontFamily: 'NotoSansThai',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ข้อมูลส่วนตัว',
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
                  _buildInfoCard(
                    icon: Icons.account_circle,
                    title: 'ชื่อผู้ใช้',
                    value: user['username'] ?? 'ไม่มีข้อมูล',
                    color: Colors.purple,
                  ),
                  SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'ชื่อ',
                    value: user['name'] ?? 'ไม่มีข้อมูล',
                    color: Color(0xFF25624B),
                  ),
                  SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'อีเมล',
                    value: user['email'] ?? 'ไม่มีข้อมูล',
                    color: Colors.orange,
                  ),
                  SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'เบอร์โทร',
                    value: user['number']?.toString() ?? 'ไม่มีข้อมูล',
                    color: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.menu_book,
                    title: 'เมนู',
                    value: 'Menu  ${user['menu']?.toString() ?? 'ไม่ระบุ'}',
                    color: Color(0xFF34D396),
                  ),
                  SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _logout(context);
                          },
                          icon: Icon(Icons.exit_to_app, size: 20),
                          label: Text('ออกจากระบบ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: Colors.red.withOpacity(0.4),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showEditProfileDialog();
                          },
                          icon: Icon(Icons.edit, size: 20),
                          label: Text('แก้ไขข้อมูล'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: Colors.amber.withOpacity(0.4),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showRelationDialog(context, user);
                          },
                          icon: Icon(Icons.people, size: 20),
                          label: Text('ความสัมพันธ์'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: Colors.blue.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ฟังก์ชันออกจากระบบ
void _logout(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('ออกจากระบบ'),
      content: Text('คุณต้องการออกจากระบบหรือไม่?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () {
            // ล้างข้อมูลการล็อกอินและนำผู้ใช้กลับไปที่หน้าล็อกอิน
            Navigator.of(context).popUntil((route) => route.isFirst);
            // หรือ Navigator.pushReplacementNamed(context, '/login');
          },
          child: Text('ออกจากระบบ', style: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.red)),
        ),
      ],
    ),
  );
}

void showRelationDialog(context, user) {
  showDialog(
    context: context,
    builder: (context) {
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
          child: Stack(
            children: [
              // ปุ่มปิด (X) บนขวา
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              Column(
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
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'เชื่อมความสัมพันธ์',
                                style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'สร้างหรือเชื่อมต่อรหัสความสัมพันธ์',
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
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Show dialog ย่อย เลือกสร้างของคนงาน/ลูกไร่
                            showDialog(
                              context: context,
                              builder: (context) {
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
                                    child: Stack(
                                      children: [
                                        // ปุ่มปิด (X) บนขวา
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: IconButton(
                                            icon: Icon(Icons.close,
                                                color: Colors.grey),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ),

                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.group_add,
                                                color: Color(0xFF34D396),
                                                size: 40),
                                            SizedBox(height: 10),
                                            Text(
                                              'เลือกประเภทการสร้างรหัส',
                                              style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            ),
                                            SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      print(
                                                          '🔄 กดปุ่มสร้างรหัสคนงาน');
                                                      print(
                                                          '👤 user ID: ${user['_id']}');
                                                      // เรียก function ก่อน ไม่ปิด dialog
                                                      await _generateRelationCode(
                                                          context,
                                                          'worker',
                                                          user['_id']);
                                                      // ปิด dialog หลังจากแสดงผลแล้ว
                                                      if (context.mounted) {
                                                        Navigator.of(context).pop();
                                                      }
                                                    },
                                                    child: Text('คนงาน'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Color(0xFF34D396),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 14),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      print(
                                                          '🔄 กดปุ่มสร้างรหัสลูกไร่');
                                                      print(
                                                          '👤 user ID: ${user['_id']}');
                                                      // เรียก function ก่อน ไม่ปิด dialog
                                                      await _generateRelationCode(
                                                          context,
                                                          'farmer',
                                                          user['_id']);
                                                      // ปิด dialog หลังจากแสดงผลแล้ว
                                                      if (context.mounted) {
                                                        Navigator.of(context).pop();
                                                      }
                                                    },
                                                    child: Text('ลูกไร่'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.amber,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 14),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 20),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text('ปิด',
                                                  style:
                                                      TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 16)),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF34D396),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'สร้างการเชื่อมต่อ',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Show dialog สำหรับกรอกรหัส พร้อมเลือกประเภท
                            showDialog(
                              context: context,
                              builder: (context) {
                                TextEditingController codeController =
                                    TextEditingController();
                                String selectedType = 'worker'; // default
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
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Stack(
                                          children: [
                                            // ปุ่มปิด (X) บนขวา
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: IconButton(
                                                icon: Icon(Icons.close,
                                                    color: Colors.grey),
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                            ),

                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.vpn_key,
                                                    color: Color(0xFF34D396),
                                                    size: 40),
                                                SizedBox(height: 10),
                                                Text(
                                                  'กรอกรหัสการเชื่อม',
                                                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20),
                                                ),
                                                SizedBox(height: 16),
                                                // ปุ่มเลือกประเภท
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ChoiceChip(
                                                      label: Text('คนงาน'),
                                                      selected: selectedType ==
                                                          'worker',
                                                      onSelected: (val) {
                                                        setState(() =>
                                                            selectedType =
                                                                'worker');
                                                      },
                                                      selectedColor:
                                                          Color(0xFF34D396),
                                                    ),
                                                    SizedBox(width: 12),
                                                    ChoiceChip(
                                                      label: Text('ลูกไร่'),
                                                      selected: selectedType ==
                                                          'farmer',
                                                      onSelected: (val) {
                                                        setState(() =>
                                                            selectedType =
                                                                'farmer');
                                                      },
                                                      selectedColor:
                                                          Colors.amber,
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16),
                                                TextField(
                                                  controller: codeController,
                                                  decoration: InputDecoration(
                                                    labelText: 'รหัสการเชื่อม',
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12)),
                                                    filled: true,
                                                    fillColor: Colors.grey[100],
                                                  ),
                                                ),
                                                SizedBox(height: 24),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () async {
                                                          await connectRelationCode(
                                                              context,
                                                              codeController
                                                                  .text,
                                                              selectedType,
                                                              user);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Color(0xFF34D396),
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical: 14),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        child: Text('เชื่อมต่อ',
                                                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                                                fontSize: 16)),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical: 14),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                        ),
                                                        child: Text('ปิด',
                                                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                                                fontSize: 16)),
                                                      ),
                                                    ),
                                                  ],
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
                            'กรอกรหัสการเชื่อม',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'ปิด',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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

Future<void> _generateRelationCode(
    BuildContext context, String type, String ownerId) async {
  String apiUrl = type == 'worker'
      ? 'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/profile/create-worker-code'
      : 'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/profile/create-farmer-code';
  
  // แสดง loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('กำลังสร้างรหัส...'),
        ],
      ),
    ),
  );
  
  try {
    print('🔄 กำลังสร้างรหัสสำหรับ $type...');
    print('📤 URL: $apiUrl');
    print('📤 ownerId: $ownerId');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        // ไม่ต้องส่ง Authorization header เพราะ middleware จะข้าม
      },
      body: jsonEncode({'ownerId': ownerId}),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String code = data['code'] ?? '';
      print('✅ สร้างรหัสสำเร็จ: $code');

      // ปิด loading dialog ก่อน
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // ใช้ SchedulerBinding เพื่อให้แน่ใจว่า context ยังใช้งานได้
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('รหัส${type == 'worker' ? 'คนงาน' : 'ลูกไร่'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'นำรหัสนี้ไปให้${type == 'worker' ? 'คนงาน' : 'ลูกไร่'}ของคุณ'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: SelectableText(
                      code,
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'หมดอายุ: ${data['expiresAt'] != null ? DateTime.parse(data['expiresAt']).toString().substring(0, 19) : 'ไม่ระบุ'}',
                    style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    // คัดลอกรหัส
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('คัดลอกรหัสแล้ว: $code'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.copy, size: 18),
                  label: Text('คัดลอก'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ปิด'),
                ),
              ],
            ),
          );
        } else {
          print('❌ Context ไม่สามารถใช้งานได้');
          print('✅ สร้างรหัสสำเร็จ: $code');
        }
      });
    } else {
      print('❌ Error status: ${response.statusCode}');
      print('❌ Error body: ${response.body}');
      // ปิด loading dialog ก่อน
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการสร้างรหัส'),
              backgroundColor: Colors.red),
        );
      }
    }
  } catch (e) {
    print('❌ Exception: $e');
    // ปิด loading dialog ก่อน
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: ' + e.toString()),
            backgroundColor: Colors.red),
      );
    }
  }
}

Future<void> connectRelationCode(BuildContext context, String code, String type,
    Map<String, dynamic> user) async {
  String apiUrl = type == 'worker'
      ? 'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/profile/add-worker'
      : 'https://sugarcane-iqddm6q3o-suphachais-projects-d3438f04.vercel.app/api/profile/add-farmer';
  
  // แสดง loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Text('กำลังเชื่อมต่อ...'),
        ],
      ),
    ),
  );
  
  try {
    print('🔄 กำลังเชื่อมต่อรหัส $code สำหรับ $type...');
    print('📤 URL: $apiUrl');
    print('📤 user ID: ${user['_id']}');
    
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${user['_id']}', // ส่ง userId เป็น token
      },
      body: jsonEncode({
        'relationCode': code,
        // ไม่ต้องส่ง userId เพราะ backend จะดึงจาก req.user
      }),
    );
    
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');
    
    // ปิด loading dialog ก่อน
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ เชื่อมต่อสำเร็จ: ${data['message']}');
      
      // ใช้ SchedulerBinding เพื่อให้แน่ใจว่า context ยังใช้งานได้
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // ปิด dialog กรอกรหัสก่อน
          Navigator.of(context).pop();
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 10),
                  Text('สำเร็จ'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data['message'] ?? 'เชื่อมต่อกับเจ้าของเรียบร้อยแล้ว'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ตอนนี้คุณสามารถเข้าถึงข้อมูลของเจ้าของได้แล้ว',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 12, color: Colors.green[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ปิด dialog
                    
                    // แสดง popup แจ้งเตือนว่าต้องเข้าสู่ระบบใหม่
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 28),
                            SizedBox(width: 10),
                            Text('แจ้งเตือน'),
                          ],
                        ),
                        content: Text('การเชื่อมต่อสำเร็จแล้ว\nจำเป็นต้องเข้าสู่ระบบใหม่เพื่อให้เมนูอัพเดต'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // ปิด popup
                              // ไปหน้า login
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                                (Route<dynamic> route) => false,
                              );
                            },
                            child: Text('เข้าสู่ระบบใหม่'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text('ตกลง'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          );
        } else {
          print('❌ Context ไม่สามารถใช้งานได้');
          print('✅ เชื่อมต่อสำเร็จ: ${data['message']}');
        }
      });
    } else {
      final data = jsonDecode(response.body);
      print('❌ Error status: ${response.statusCode}');
      print('❌ Error body: ${response.body}');
      
      // ใช้ SchedulerBinding เพื่อให้แน่ใจว่า context ยังใช้งานได้
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          // ปิด dialog กรอกรหัสก่อน
          Navigator.of(context).pop();
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text('ผิดพลาด'),
                ],
              ),
              content: Text(
                  'ไม่สามารถเชื่อมต่อได้: \n${data['message'] ?? 'Unknown error'}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ตกลง'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          );
        } else {
          print('❌ Context ไม่สามารถใช้งานได้');
          print('❌ Error: ${data['message']}');
        }
      });
    }
  } catch (e) {
    print('❌ Exception: $e');
    
    // ปิด loading dialog ก่อน
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    
    // ใช้ SchedulerBinding เพื่อให้แน่ใจว่า context ยังใช้งานได้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        // ปิด dialog กรอกรหัสก่อน
        Navigator.of(context).pop();
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('ผิดพลาด'),
              ],
            ),
            content: Text('เกิดข้อผิดพลาด: ' + e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('ตกลง'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        );
      } else {
        print('❌ Context ไม่สามารถใช้งานได้');
        print('❌ Exception: $e');
      }
    });
  }
}

void connectWithCode(BuildContext context, String code) {
  // TODO: ใส่ logic การเชื่อมต่อที่นี่ เช่น ส่ง code ไป backend หรือเช็คกับฐานข้อมูล
  print('รหัสที่กรอก: ' + code);
  // ตัวอย่าง: แสดง dialog แจ้งผล
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('ผลการเชื่อมต่อ'),
      content: Text('เชื่อมต่อด้วยรหัส: ' + code + ' เรียบร้อยแล้ว'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('ตกลง'),
        ),
      ],
    ),
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
                            fontFamily: 'NotoSansThai',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                            fontFamily: 'NotoSansThai',
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
