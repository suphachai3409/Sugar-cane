import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'menu1.dart';
import 'menu2.dart';
import 'menu3.dart';

void main() {
  runApp(moneytransferScreen(
      userId: 'default_user_id')); // ใช้ค่าจริงจากระบบล็อกอิน
}

class moneytransferScreen extends StatelessWidget {
  final String userId;

  const moneytransferScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: CashAdvanceApp(userId: userId), // ส่ง userId ไปยัง CashAdvanceApp
    );
  }
}

class CashAdvanceRequest {
  final String? id;
  final String name;
  final String phone;
  final String purpose;
  final String amount;
  final DateTime date;
  final List<String> images;
  final String? status;
  final String? approvalImage;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime? rejectedAt;

  CashAdvanceRequest({
    this.id,
    required this.name,
    required this.phone,
    required this.purpose,
    required this.amount,
    required this.date,
    this.images = const [],
    this.status,
    this.approvalImage,
    this.approvedAt,
    this.rejectionReason,
    this.rejectedAt,
  });
}

class CashAdvanceApp extends StatefulWidget {
  final String userId;

  const CashAdvanceApp({Key? key, required this.userId}) : super(key: key);

  @override
  State<CashAdvanceApp> createState() => _CashAdvanceAppState();
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const FullScreenImage({
    Key? key,
    required this.imageUrl,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // ✅ ใส่ GestureDetector ไว้ด้านนอกสุด
        onTap: onClose, // ✅ Tap นอกรูปเพื่อปิด
        child: Stack(
          children: [
            // พื้นหลังสีดำครึ่งใสสำหรับพื้นที่ว่าง
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),

            // รูปภาพตรงกลาง
            Center(
              child: GestureDetector(
                onTap: () {}, // ✅ ป้องกันไม่ให้ tap บนรูปปิดหน้า
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Container(
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/uploads/$imageUrl',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error,
                                      color: Colors.white, size: 50),
                                  SizedBox(height: 10),
                                  Text(
                                    'ไม่สามารถโหลดรูปภาพ',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ปุ่ม X สำหรับปิด (มุมขวาบน)
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),

            // ปุ่ม back สำหรับ Android (มุมซ้ายบน)
            Positioned(
              top: 40,
              left: 20,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
            ),

            // ข้อความแนะนำที่ด้านล่าง
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'แตะนอกพื้นที่เพื่อปิด',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
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

class _CashAdvanceAppState extends State<CashAdvanceApp> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _purposeController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late DateTime _selectedDate;

  // ตัวแปรสำหรับเก็บข้อความแจ้งเตือน
  String? _nameError;
  String? _phoneError;
  String? _purposeError;
  String? _amountError;
  String? _dateError;
  List<dynamic> userRequests = [];
  List<CashAdvanceRequest> requests = [];
  int? selectedRequestIndex;
  // เพิ่มตัวแปรสำหรับ profile
  final String apiUrl = 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/pulluser';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String get userId => widget.userId;
  final List<File> _selectedImages = []; // เก็บรูปภาพที่เลือก
  final ImagePicker _picker = ImagePicker(); // สำหรับการเลือกรูปภาพ

  void _testApiDirectly() async {
    try {
      print('🧪 Testing API directly...');

      final response = await http.get(
        Uri.parse(
            'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/cash-advance/user-requests/${_currentUser!['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'user-id': _currentUser!['_id']
        },
      );

      print('🧪 Direct API status: ${response.statusCode}');
      print('🧪 Direct API body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['requests'] is List) {
          for (var req in data['requests']) {
            print('🧪 Request from API:');
            print('   _id: ${req['_id']}');
            print('   purpose: "${req['purpose']}"');
            print('   purpose type: ${req['purpose']?.runtimeType}');
          }
        }
      }
    } catch (e) {
      print('🧪 Direct API error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _testApiDirectly();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _purposeController = TextEditingController();
    _amountController = TextEditingController();
    _dateController = TextEditingController();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);

    // เรียกใช้ฟังก์ชันดึงข้อมูลผู้ใช้และคำขอ
    fetchUserData().then((_) {
      // หลังจากดึงข้อมูลผู้ใช้เสร็จ ให้ดึงคำขอเบิกเงิน
      if (_currentUser != null) {
        fetchUserRequests();
        _fillUserData();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

// ฟังก์ชันเลือกรูปภาพจาก gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          _selectedImages
              .addAll(pickedFiles.map((file) => File(file.path)).toList());
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

// ฟังก์ชันถ่ายรูป
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

// ฟังก์ชันลบรูปภาพ
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

// เพิ่มฟังก์ชันสำหรับอัพโหลดรูปภาพ
  Future<List<String>> _uploadImages(List<File> imageFiles) async {
    List<String> imageUrls = [];
    var uri = Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/upload');

    for (var imageFile in imageFiles) {
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'cash_advance_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        imageUrls.add(jsonResponse['imageUrl']);
      }
    }

    return imageUrls;
  }

  // ฟังก์ชันดึงข้อมูลผู้ใช้
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
          // ใช้ userId ที่รับมาจาก widget
          if (userId.isNotEmpty) {
            _currentUser = _users.firstWhere(
              (user) => user['_id'] == userId,
              orElse: () => _users.isNotEmpty ? _users.first : {},
            );
          } else {
            _currentUser = _users.isNotEmpty ? _users.first : null;
          }
        });

        // ดึงข้อมูลคำขอเบิกเงินหลังจากดึงข้อมูลผู้ใช้เสร็จ
        await fetchUserRequests();

        setState(() {
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

  Future<String?> _getOwnerId() async {
    try {
      print('🔍 Fetching ownerId for worker: ${_currentUser!['_id']}');

      // ใช้ API ที่ถูกต้อง - หา ownerId จากแปลงปลูก
      final response = await http.get(
        Uri.parse(
            'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/plots/owner/${_currentUser!['_id']}'),
        headers: {'user-id': _currentUser!['_id']},
      ).timeout(Duration(seconds: 10));

      print('📥 Owner API response: ${response.statusCode}');
      print('📥 Owner API body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Found ownerId: ${data['ownerId']}');
          return data['ownerId'];
        }
      }

      print('❌ Failed to get ownerId, status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error fetching ownerId: $e');
      return null;
    }
  }

// ฟังก์ชันดึงข้อมูลคำขอเบิกเงิน
  Future<void> fetchUserRequests() async {
    if (_currentUser == null) return;

    try {
      print(
          '🔍 Fetching cash advance requests for user: ${_currentUser!['_id']}');

      final response = await http.get(
        Uri.parse(
            'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/cash-advance/user-requests/${_currentUser!['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'user-id': _currentUser!['_id']
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
            '📥 Full API response: ${jsonEncode(data)}'); // ✅ Debug ทั้ง response

        if (data['success'] == true) {
          setState(() {
            requests = (data['requests'] as List).map((request) {
              // ✅ Debug ละเอียดสำหรับแต่ละ field
              print('🔍 === REQUEST DETAILS ===');
              print('   _id: ${request['_id']}');
              print('   purpose: "${request['purpose']}"');
              print('   purpose type: ${request['purpose']?.runtimeType}');
              print('   purpose is null: ${request['purpose'] == null}');
              print('   purpose is empty: ${request['purpose']?.isEmpty}');
              print('   purpose toString: "${request['purpose']?.toString()}"');

              // ✅ ตรวจสอบทุก field ที่เกี่ยวข้อง
              print('   name: ${request['name']}');
              print('   phone: ${request['phone']}');
              print('   amount: ${request['amount']}');
              print('   status: ${request['status']}');
              print('   ========================');

              return CashAdvanceRequest(
                id: request['_id'],
                name: request['name'] ?? 'ไม่มีชื่อ',
                phone: request['phone'] ?? 'ไม่มีเบอร์',
                purpose: request['purpose']?.toString() ??
                    'ไม่ระบุ', // ✅ ใช้ toString() เพื่อความปลอดภัย
                amount: request['amount'] ?? '0',
                date: DateTime.parse(
                    request['date'] ?? DateTime.now().toString()),
                images: List<String>.from(request['images'] ?? []),
                status: request['status'] ?? 'pending',
                approvalImage: request['approvalImage'],
                approvedAt: request['approvedAt'] != null
                    ? DateTime.parse(request['approvedAt'])
                    : null,
                rejectionReason: request['rejectionReason'],
                rejectedAt: request['rejectedAt'] != null
                    ? DateTime.parse(request['rejectedAt'])
                    : null,
              );
            }).toList();
          });

          print('✅ Loaded ${requests.length} cash advance requests');

          // ✅ Debug ข้อมูลสุดท้ายที่ได้
          for (var i = 0; i < requests.length; i++) {
            final request = requests[i];
            print('📋 Final request $i:');
            print('   id: ${request.id}');
            print('   purpose: "${request.purpose}"');
            print('   purpose is null: ${request.purpose == null}');
          }
        }
      } else {
        print('❌ Error status: ${response.statusCode}');
        print('❌ Error body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching requests: $e');
      print('❌ Error type: ${e.runtimeType}');
    }
  }

  void _fillUserData() {
    if (_currentUser != null) {
      _nameController.text = _currentUser!['name'] ?? '';
      _phoneController.text = _currentUser!['number']?.toString() ?? '';
    }
  }

  void _addNewRequest() {
    selectedRequestIndex = null;
    _clearForm();
    _resetErrors();
    _fillUserData();
    _showFormDialog();
  }

  void _editRequest(int index) {
    selectedRequestIndex = index;
    final request = requests[index];
    _nameController.text = request.name;
    _phoneController.text = request.phone;
    _purposeController.text = request.purpose; // ✅ ต้องเพิ่มบรรทัดนี้
    _amountController.text = request.amount;
    _selectedDate = request.date;
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);

    // ✅ ล้างรูปภาพที่เลือกเดิม (ถ้ามีการอัพโหลดรูปใหม่)
    _selectedImages.clear();

    _resetErrors();
    _showFormDialog();
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'เบิกล่วงหน้า',
                            style: TextStyle(
                              color: Color(0xFF25634B),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ชื่อ-นามสกุล (ไม่สามารถแก้ไขได้)
                        const Text(
                          'ชื่อ-นามสกุล',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors
                                .grey[100], // สีพื้นหลังแสดงว่าไม่สามารถแก้ไข
                          ),
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'ไม่พบข้อมูลชื่อ',
                            style: TextStyle(
                              color: _nameController.text.isNotEmpty
                                  ? Colors.black
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // เบอร์โทรศัพท์ (ไม่สามารถแก้ไขได้)
                        const Text(
                          'เบอร์โทรศัพท์',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[100],
                          ),
                          child: Text(
                            _phoneController.text.isNotEmpty
                                ? _phoneController.text
                                : 'ไม่พบข้อมูลเบอร์โทร',
                            style: TextStyle(
                              color: _phoneController.text.isNotEmpty
                                  ? Colors.black
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // จำนวนเงินที่ต้องการเบิก
                        const Text(
                          'จำนวนเงินที่ต้องการเบิก',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'ระบุจำนวนเงิน',
                            suffixText: 'บาท',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            errorText: _amountError,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (_amountError != null) _amountError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        // วันที่
                        const Text(
                          'วันที่',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'เลือกวันที่',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                            errorText: _dateError,
                          ),
                          onTap: () async {
                            await _selectDateInDialog(context, setDialogState);
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 15),

                        // ✅ แสดงวัตถุประสงค์/เหตุผล
                        const Text(
                          'วัตถุประสงค์/เหตุผล',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller:
                              _purposeController, // ✅ ใช้ controller นี้
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'ระบุวัตถุประสงค์ในการเบิกเงิน (เช่น ซ่อมบำรุง, ค่าอุปกรณ์, ฯลฯ)',
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 12),
                            errorText: _purposeError, // ✅ แสดง error ถ้ามี
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (_purposeError != null) _purposeError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                        // ส่วนแสดงรูปภาพ (เดิม)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'แนบรูปภาพ (ถ้ามี)',
                              style: TextStyle(
                                color: Color(0xFF30C39E),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImages,
                                  icon:
                                      const Icon(Icons.photo_library, size: 18),
                                  label: const Text('เลือกจาก gallery'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF30C39E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _takePhoto,
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('ถ่ายรูป'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF30C39E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedImages.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Text('รูปภาพที่เลือก:'),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_selectedImages.length,
                                    (index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(
                                                _selectedImages[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  side: const BorderSide(
                                      color: Color(0xFF30C39E)),
                                ),
                                child: const Text(
                                  'กลับ',
                                  style: TextStyle(
                                    color: Color(0xFF30C39E),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 60),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_validateInputsInDialog(setDialogState)) {
                                    _saveRequestFromDialog();
                                    Navigator.of(context).pop();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF30C39E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'บันทึก',
                                  style: TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateInDialog(
      BuildContext context, StateSetter setDialogState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF30C39E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF30C39E),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setDialogState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
        _dateError = null;
      });
    }
  }

  bool _validateInputsInDialog(StateSetter setDialogState) {
    bool isValid = true;

    setDialogState(() {
      _resetErrors();

      if (_amountController.text.isEmpty) {
        _amountError = "กรุณาระบุจำนวนเงิน";
        isValid = false;
      }

      if (_dateController.text.isEmpty) {
        _dateError = "กรุณาเลือกวันที่";
        isValid = false;
      }

      // ✅ Validation สำหรับวัตถุประสงค์
      if (_purposeController.text.isEmpty) {
        _purposeError = "กรุณาระบุวัตถุประสงค์";
        isValid = false;
      } else if (_purposeController.text.length < 5) {
        _purposeError = "กรุณาระบุวัตถุประสงค์อย่างน้อย 5 ตัวอักษร";
        isValid = false;
      }
    });

    return isValid;
  }

  void _resetErrors() {
    _nameError = null;
    _phoneError = null;
    _amountError = null;
    _dateError = null;
    _purposeError = null; // ✅ เพิ่ม reset purpose error
  }

  // ใน _saveRequestFromDialog() - ตรวจสอบคำขอ pending
  Future<void> _saveRequestFromDialog() async {
    // ตรวจสอบว่ามีคำขอ pending อยู่แล้วหรือไม่ (เฉพาะเมื่อสร้างใหม่)
    if (selectedRequestIndex == null) {
      final hasPendingRequest =
          requests.any((request) => request.status == 'pending');
      if (hasPendingRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'มีคำขอเบิกเงินที่รอดำเนินการอยู่แล้ว ไม่สามารถส่งคำขอใหม่ได้'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // ดึง ownerId และส่งคำขอ...
    try {
      final ownerId = await _getOwnerId();
      if (ownerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบข้อมูลเจ้าของ')),
        );
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/cash-advance/check-relation/${_currentUser!['_id']}/$ownerId'),
        headers: {'user-id': _currentUser!['_id']},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // อัพโหลดรูปภาพ
          List<String> uploadedImageUrls = [];
          if (_selectedImages.isNotEmpty) {
            uploadedImageUrls = await _uploadImages(_selectedImages);
          }

          // ✅ ตรวจสอบการส่ง purpose
          final purposeText = _purposeController.text.trim();
          print('📤 Sending purpose: $purposeText'); // Debug log

          final String apiUrl = selectedRequestIndex != null
              ? 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/cash-advance/request/${requests[selectedRequestIndex!].id}'
              : 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/cash-advance/request';

          final httpMethod =
              selectedRequestIndex != null ? http.put : http.post;

          final requestResponse = await httpMethod(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'user-id': _currentUser!['_id']
            },
            body: jsonEncode({
              'userId': _currentUser!['_id'],
              'ownerId': ownerId,
              'name': _nameController.text,
              'phone': _phoneController.text,
              'purpose': purposeText, // ✅ ใช้ text ที่ trim แล้ว
              'amount': _amountController.text,
              'date': _selectedDate.toIso8601String(),
              'type': data['type'],
              'images': uploadedImageUrls,
              'status': 'pending',
            }),
          );

          print('📤 Request API response: ${requestResponse.statusCode}');
          print('📤 Request API body: ${requestResponse.body}');

          if (requestResponse.statusCode == 200 ||
              requestResponse.statusCode == 201) {
            final requestData = jsonDecode(requestResponse.body);
            if (requestData['success'] == true) {
              // ✅ ดึงข้อมูลใหม่เพื่อให้ได้ข้อมูลที่ถูกต้องจาก server
              await fetchUserRequests();

              _clearForm();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(selectedRequestIndex != null
                      ? 'แก้ไขคำขอเบิกเงินเรียบร้อย'
                      : 'ส่งคำขอเบิกเงินเรียบร้อย'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              setState(() {
                _selectedImages.clear();
                selectedRequestIndex = null;
              });
            }
          } else {
            // ✅ แสดง error จาก server
            final errorData = jsonDecode(requestResponse.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'เกิดข้อผิดพลาด: ${errorData['message'] ?? 'ไม่ทราบสาเหตุ'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRequestDetails(int index) {
    if (index < 0 || index >= requests.length) return;

    setState(() {
      selectedRequestIndex = index;
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRequest();
              },
              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteRequest() async {
    if (selectedRequestIndex != null) {
      final request = requests[selectedRequestIndex!];

      if (request.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถลบคำขอได้: ไม่พบ ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final response = await http.delete(
          Uri.parse(
              'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/cash-advance/request/${request.id}'),
          headers: {'user-id': _currentUser!['_id']},
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['success'] == true) {
            setState(() {
              requests.removeAt(selectedRequestIndex!);
              selectedRequestIndex = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ลบคำขอเรียบร้อย (ข้อมูลยังคงอยู่ในระบบ)'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error deleting request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการลบคำขอ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _amountController.clear();
    _purposeController.clear(); // ✅ ล้าง purpose ด้วย
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _selectedImages.clear();
    selectedRequestIndex = null; // ✅ ล้าง index การแก้ไข
  }

  void _goBack() {
    setState(() {
      selectedRequestIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เบิกล่วงหน้า',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF25634B),
              fontWeight: FontWeight.w800,
            )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF34D396)),
                  ),
                ),
              ),
            _buildCurrentScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (selectedRequestIndex != null) {
      return _buildRequestDetails();
    } else {
      return _buildBody(width, height);
    }
  }

  // ใน _buildBody() - แสดงปุ่มเพิ่มการขอเบิกเฉพาะเมื่อไม่มีคำขอ pending
  Widget _buildBody(double width, double height) {
    final pendingRequests =
        requests.where((r) => r.status == 'pending').toList();
    final completedRequests =
        requests.where((r) => r.status != 'pending').toList();

    // ✅ แสดง empty state เมื่อไม่มีคำขอใดๆ
    if (requests.isEmpty) {
      return _buildEmptyState(width, height);
    }

    return RefreshIndicator(
      onRefresh: fetchUserRequests,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: pendingRequests.isEmpty ? height * 0.1 : 0,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (pendingRequests.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'คำขอที่รอดำเนินการ (${pendingRequests.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF25634B),
                          ),
                        ),
                      ),
                      ...pendingRequests.asMap().entries.map((entry) {
                        return _buildRequestCard(entry.value, entry.key);
                      }).toList(),
                    ],
                    if (completedRequests.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'ประวัติคำขอ (${completedRequests.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF25634B),
                          ),
                        ),
                      ),
                      ...completedRequests.asMap().entries.map((entry) {
                        return _buildRequestCard(
                            entry.value, entry.key + pendingRequests.length);
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            // ปุ่มเพิ่มคำขอ (แสดงเฉพาะเมื่อไม่มีคำขอ pending)
            if (pendingRequests.isEmpty)
              Positioned(
                bottom: 10,
                left: 60,
                right: 60,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _addNewRequest,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'เพิ่มการขอเบิก',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34D396),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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

  Widget _buildEmptyState(double width, double height) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: GestureDetector(
          onTap: _addNewRequest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: width * 0.2,
                height: height * 0.1,
                decoration: ShapeDecoration(
                  color: const Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'กดเพื่อเบิกล่วงหน้า',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF25634B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(CashAdvanceRequest request, int index) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(request.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: InkWell(
          onTap: () => _showRequestDetails(index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ แสดงวัตถุประสงค์เป็นอันแรก (สำคัญ!)
                if (request.purpose.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'วัตถุประสงค์:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25634B),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        request.purpose,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                    ],
                  ),

                Text(
                  "ชื่อ ${request.name}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "โทร: ${request.phone}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${request.amount} บาท",
                      style: const TextStyle(
                        color: Color(0xFF25634B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // แสดงสถานะ
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(request.status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ฟังก์ชันช่วยเหลือสำหรับสีสถานะ
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

// ฟังก์ชันช่วยเหลือสำหรับข้อความสถานะ
  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ปฏิเสธ';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Widget _buildRequestDetails() {
    if (selectedRequestIndex == null) return Container();

    final request = requests[selectedRequestIndex!];
    final formattedDate = DateFormat('dd/MM/yyyy').format(request.date);

    // ✅ Debug ข้อมูล request ที่เลือก
    print('🎯 Selected request details:');
    print('   purpose: "${request.purpose}"');
    print('   purpose == null: ${request.purpose == null}');
    print('   purpose isEmpty: ${request.purpose.isEmpty}');
    print('   purpose == "ไม่ระบุ": ${request.purpose == "ไม่ระบุ"}');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'เบิกล่วงหน้า',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "ชื่อ ${request.name} tel. ${request.phone}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ ใส่การแสดงสถานะ
                  _buildDetailRow('สถานะ', _getStatusText(request.status)),
                  const SizedBox(height: 15),

                  // ✅ แสดงวัตถุประสงค์ - ใช้วิธีตรงๆ แทน
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            "วัตถุประสงค์:",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25634B),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            request.purpose ?? 'ไม่ระบุ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ✅ แสดงเหตุผลการปฏิเสธ (ถ้ามี)
                  if (request.status == 'rejected' &&
                      request.rejectionReason != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              "เหตุผลการปฏิเสธ:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              request.rejectionReason!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[700],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (request.status == 'rejected' &&
                      request.rejectionReason != null)
                    const SizedBox(height: 15),

                  _buildDetailRow('จำนวนเงิน', "${request.amount} บาท"),
                  const SizedBox(height: 15),

                  _buildDetailRow('วันที่', formattedDate),
                  const SizedBox(height: 15),

                  // แสดงรูปภาพที่แนบมา (ถ้ามี)
                  if (request.images.isNotEmpty) ...[
                    Text(
                      'รูปภาพที่แนบมา:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: request.images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImage(
                                    imageUrl: request.images[index],
                                    onClose: () => Navigator.pop(context),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 100,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/uploads/${request.images[index]}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.zoom_in,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 15),
                  ],

                  // แสดงรูปภาพการอนุมัติ (ถ้ามี)
                  if (request.approvalImage != null) ...[
                    Text(
                      'รูปภาพการอนุมัติ:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FullScreenImage(
                              imageUrl: request.approvalImage!,
                              onClose: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Stack(
                          children: [
                            Image.network(
                              'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/uploads/${request.approvalImage}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error,
                                          color: Colors.grey, size: 40),
                                      SizedBox(height: 8),
                                      Text('ไม่สามารถโหลดรูปภาพ',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF34D396)),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.zoom_in,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                  ],

                  // แสดงวันที่อนุมัติ (ถ้ามี)
                  if (request.approvedAt != null) ...[
                    _buildDetailRow(
                      'อนุมัติเมื่อ',
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(request.approvedAt!),
                    ),
                    SizedBox(height: 15),
                  ],

                  SizedBox(height: 30),

                  // ปุ่มแก้ไขและลบ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (request.status == 'pending')
                        ElevatedButton(
                          onPressed: () {
                            _editRequest(selectedRequestIndex!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            minimumSize: Size(100, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text('แก้ไข',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              )),
                        ),

                      if (request.status == 'pending') SizedBox(width: 20),

                      // ✅ แสดงปุ่มลบสำหรับทุกสถานะ
                      ElevatedButton(
                        onPressed: _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: Size(100, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text('ลบ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: _goBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text('ปิด',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
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

// ฟังก์ชันแสดงแถวรายละเอียด
  Widget _buildDetailRow(String label, String value) {
    // ✅ Debug ค่าที่ส่งมาแสดง
    print('🔄 _buildDetailRow - $label: "$value"');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF25634B),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;

        return Container(
          height: 110,
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              // Custom bottom navigation bar container (white background)
              Positioned(
                bottom: 0,
                left: width * 0.03,
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
                          if (_currentUser?['menu'] == 1) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Menu1Screen(userId: _currentUser?['_id'] ?? '')));
                          } else if (_currentUser?['menu'] == 2) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Menu2Screen(userId: _currentUser?['_id'] ?? '')));
                          } else if (_currentUser?['menu'] == 3) {
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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
        );
      },
    );
  }
}
