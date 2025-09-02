import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';


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
                                            'http://10.0.2.2:3000/uploads/${user['profileImage']}'),
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
                              // อัปเดตข้อมูลและอัปโหลดรูปไป backend
                              var uri = Uri.parse(
                                  'http://10.0.2.2:3000/updateuser/${user['_id']}');
                              var request = http.MultipartRequest('PUT', uri);
                              request.fields['name'] = nameController.text;
                              request.fields['email'] = emailController.text;
                              request.fields['number'] = phoneController.text;
                              if (tempSelectedImage != null) {
                                request.files.add(
                                    await http.MultipartFile.fromPath(
                                        'profileImage',
                                        tempSelectedImage!.path));
                              }
                              var response = await request.send();
                              if (response.statusCode == 200) {
                                print('อัปเดตข้อมูลสำเร็จ');
                                if (refreshUser != null) refreshUser();
                              } else {
                                print('อัปเดตข้อมูลไม่สำเร็จ:  [31m [0m');
                              }
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('บันทึกข้อมูลสำเร็จ'),
                                    backgroundColor: Colors.green),
                              );
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
        child: Stack(
          // ใช้ Stack เพื่อวางปุ่ม X เหนือเนื้อหาอื่นๆ
          children: [
            Container(
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
                        (user['profileImage'] != null &&
                                user['profileImage'].toString().isNotEmpty)
                            ? CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                    'http://10.0.2.2:3000/uploads/${user['profileImage']}'),
                                backgroundColor: Colors.white,
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
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showEditProfileDialog();
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
                            'แก้ไขข้อมูล',
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
                            Navigator.of(context).pop();
                            showRelationDialog(context, user);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'ความสัมพันธ์',
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
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                shape: CircleBorder(),
                color: Colors.white.withOpacity(0.9),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
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
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เชื่อมความสัมพันธ์',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'สร้างหรือเชื่อมต่อรหัสความสัมพันธ์',
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.group_add,
                                        color: Color(0xFF34D396), size: 40),
                                    SizedBox(height: 10),
                                    Text(
                                      'เลือกประเภทการสร้างรหัส',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                    SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              print('🔄 กดปุ่มสร้างรหัสคนงาน');
                                              print(
                                                  '👤 user ID: ${user['_id']}');
                                              Navigator.of(context).pop();
                                              await _generateRelationCode(
                                                  context,
                                                  'worker',
                                                  user['_id']);
                                            },
                                            child: Text('คนงาน'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xFF34D396),
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              print('🔄 กดปุ่มสร้างรหัสลูกไร่');
                                              print(
                                                  '👤 user ID: ${user['_id']}');
                                              Navigator.of(context).pop();
                                              await _generateRelationCode(
                                                  context,
                                                  'farmer',
                                                  user['_id']);
                                            },
                                            child: Text('ลูกไร่'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                        padding:
                                            EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text('ปิด',
                                          style: TextStyle(fontSize: 16)),
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
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.vpn_key,
                                            color: Color(0xFF34D396), size: 40),
                                        SizedBox(height: 10),
                                        Text(
                                          'กรอกรหัสการเชื่อม',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
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
                                              selected:
                                                  selectedType == 'worker',
                                              onSelected: (val) {
                                                setState(() =>
                                                    selectedType = 'worker');
                                              },
                                              selectedColor: Color(0xFF34D396),
                                            ),
                                            SizedBox(width: 12),
                                            ChoiceChip(
                                              label: Text('ลูกไร่'),
                                              selected:
                                                  selectedType == 'farmer',
                                              onSelected: (val) {
                                                setState(() =>
                                                    selectedType = 'farmer');
                                              },
                                              selectedColor: Colors.amber,
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
                                                    BorderRadius.circular(12)),
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
                                                  Navigator.of(context).pop();
                                                  await connectRelationCode(
                                                      context,
                                                      codeController.text,
                                                      selectedType,
                                                      user);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Color(0xFF34D396),
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: Text('เชื่อมต่อ',
                                                    style: TextStyle(
                                                        fontSize: 16)),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
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
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: Text('ปิด',
                                                    style: TextStyle(
                                                        fontSize: 16)),
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
}

Future<void> _generateRelationCode(
    BuildContext context, String type, String ownerId) async {
  String apiUrl = type == 'worker'
      ? 'http://10.0.2.2:3000/api/profile/create-worker-code'
      : 'http://10.0.2.2:3000/api/profile/create-farmer-code';
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
              SelectableText(
                code,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ปิด'),
            ),
          ],
        ),
      );
    } else {
      print('❌ Error status: ${response.statusCode}');
      print('❌ Error body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาดในการสร้างรหัส'),
            backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    print('❌ Exception: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('เกิดข้อผิดพลาด: ' + e.toString()),
          backgroundColor: Colors.red),
    );
  }
}

Future<void> connectRelationCode(BuildContext context, String code, String type,
    Map<String, dynamic> user) async {
  String apiUrl = type == 'worker'
      ? 'http://10.0.2.2:3000/api/profile/add-worker'
      : 'http://10.0.2.2:3000/api/profile/add-farmer';
  try {
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
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('สำเร็จ'),
          content: Text(data['message'] ?? 'เชื่อมต่อกับเจ้าของเรียบร้อยแล้ว'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ตกลง'),
            ),
          ],
        ),
      );
    } else {
      final data = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('ผิดพลาด'),
          content: Text(
              'ไม่สามารถเชื่อมต่อได้: \n${data['message'] ?? 'Unknown error'}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ผิดพลาด'),
        content: Text('เกิดข้อผิดพลาด: ' + e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
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

Future<void> _logout(BuildContext context) async {
  try {
    // 1. ลบข้อมูลการล็อกอิน (ถ้ามี)
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('auth_token');

    // 2. นำทางไปยังหน้าล็อกอิน
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );

    // 3. แสดงข้อความแจ้งเตือน
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ออกจากระบบสำเร็จ'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    print('Error during logout: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เกิดข้อผิดพลาดในการออกจากระบบ'),
        backgroundColor: Colors.red,
      ),
    );
  }
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
