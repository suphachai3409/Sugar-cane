import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final String name;
  final String phone;
  final String amount;
  final DateTime date;
  final List<String> images;
  final String? status; // เพิ่มฟิลด์สถานะ
  final String? approvalImage; // รูปภาพการอนุมัติ
  final DateTime? approvedAt; // วันที่อนุมัติ

  CashAdvanceRequest({
    required this.name,
    required this.phone,
    required this.amount,
    required this.date,
    this.images = const [],
    this.status,
    this.approvalImage,
    this.approvedAt,
  });
}

class CashAdvanceApp extends StatefulWidget {
  final String userId;

  const CashAdvanceApp({Key? key, required this.userId}) : super(key: key);

  @override
  State<CashAdvanceApp> createState() => _CashAdvanceAppState();
}

class _CashAdvanceAppState extends State<CashAdvanceApp> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late DateTime _selectedDate;

  // ตัวแปรสำหรับเก็บข้อความแจ้งเตือน
  String? _nameError;
  String? _phoneError;
  String? _amountError;
  String? _dateError;
  List<dynamic> userRequests = [];
  List<CashAdvanceRequest> requests = [];
  int? selectedRequestIndex;
  // เพิ่มตัวแปรสำหรับ profile
  final String apiUrl = 'http://10.0.2.2:3000/pulluser';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String get userId => widget.userId;
  final List<File> _selectedImages = []; // เก็บรูปภาพที่เลือก
  final ImagePicker _picker = ImagePicker(); // สำหรับการเลือกรูปภาพ

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _amountController = TextEditingController();
    _dateController = TextEditingController();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);

    // เรียกใช้ฟังก์ชันดึงข้อมูลผู้ใช้และคำขอ
    fetchUserData().then((_) {
      // หลังจากดึงข้อมูลผู้ใช้เสร็จ ให้ดึงคำขอเบิกเงิน
      if (_currentUser != null) {
        fetchUserRequests();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
    var uri = Uri.parse('http://10.0.2.2:3000/api/upload');

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

      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/api/plots/owner/${_currentUser!['_id']}'),
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
            'http://10.0.2.2:3000/api/cash-advance/user-requests/${_currentUser!['_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'user-id': _currentUser!['_id']
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            requests = (data['requests'] as List).map((request) {
              return CashAdvanceRequest(
                name: request['name'],
                phone: request['phone'],
                amount: request['amount'],
                date: DateTime.parse(request['date']),
                images: List<String>.from(request['images'] ?? []),
                status: request['status'],
                approvalImage: request['approvalImage'],
                approvedAt: request['approvedAt'] != null
                    ? DateTime.parse(request['approvedAt'])
                    : null,
              );
            }).toList();
          });
          print('✅ Loaded ${requests.length} cash advance requests');

          // ตรวจสอบว่ามีคำขอ pending หรือไม่
          final pendingCount =
              requests.where((r) => r.status == 'pending').length;
          if (pendingCount > 0) {
            print('⚠️ มีคำขอ pending อยู่แล้ว: $pendingCount คำขอ');
          }
        }
      } else {
        print('❌ Error fetching requests: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching requests: $e');
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
    _amountController.text = request.amount;
    _selectedDate = request.date;
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
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
                        const Text(
                          'ชื่อ-นามสกุล',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'ระบุชื่อ-นามสกุล',
                            hintStyle: TextStyle(
                                color: Colors
                                    .grey), // เปลี่ยนสีของ hint text เป็นสีเทา
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            errorText: _nameError,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (_nameError != null) _nameError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'เบอร์โทรศัพท์',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: 'ระบุเบอร์โทรศัพท์',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            errorText: _phoneError,
                            counterText: "",
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (_phoneError != null) _phoneError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
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
// ส่วนแสดงรูปภาพ
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
                        const SizedBox(height: 15),
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

      if (_nameController.text.isEmpty) {
        _nameError = "กรุณาระบุชื่อ-นามสกุล";
        isValid = false;
      }

      if (_phoneController.text.isEmpty) {
        _phoneError = "กรุณาระบุเบอร์โทรศัพท์";
        isValid = false;
      }

      if (_amountController.text.isEmpty) {
        _amountError = "กรุณาระบุจำนวนเงิน";
        isValid = false;
      }

      if (_dateController.text.isEmpty) {
        _dateError = "กรุณาเลือกวันที่";
        isValid = false;
      }
    });

    return isValid;
  }

  // ใน _saveRequestFromDialog() - ตรวจสอบคำขอ pending
  Future<void> _saveRequestFromDialog() async {
    // ตรวจสอบว่ามีคำขอ pending อยู่แล้วหรือไม่
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
            'http://10.0.2.2:3000/api/cash-advance/check-relation/${_currentUser!['_id']}/$ownerId'),
        headers: {'user-id': _currentUser!['_id']},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // อัพโหลดรูปภาพและส่งคำขอ...
          List<String> uploadedImageUrls = [];
          if (_selectedImages.isNotEmpty) {
            uploadedImageUrls = await _uploadImages(_selectedImages);
          }

          final requestResponse = await http.post(
            Uri.parse('http://10.0.2.2:3000/api/cash-advance/request'),
            headers: {
              'Content-Type': 'application/json',
              'user-id': _currentUser!['_id']
            },
            body: jsonEncode({
              'userId': _currentUser!['_id'],
              'ownerId': ownerId,
              'name': _nameController.text,
              'phone': _phoneController.text,
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
              // อัพเดต UI หลังส่งคำขอสำเร็จ
              await fetchUserRequests(); // ดึงข้อมูลใหม่
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ส่งคำขอเบิกเงินเรียบร้อย'),
                  backgroundColor: Colors.green,
                ),
              );
            }
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

  void _resetErrors() {
    _nameError = null;
    _phoneError = null;
    _amountError = null;
    _dateError = null;
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

  void _deleteRequest() {
    if (selectedRequestIndex != null) {
      setState(() {
        requests.removeAt(selectedRequestIndex!);
        selectedRequestIndex = null;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _amountController.clear();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _selectedImages.clear(); // ล้างรูปภาพที่เลือก
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

    if (requests.isEmpty) {
      return _buildEmptyState(width, height);
    } else {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom:
                  pendingRequests.isEmpty ? height * 0.1 : 0, // ปรับตามสถานะ
              child: SingleChildScrollView(
                child: _buildRequestList(),
              ),
            ),
            if (pendingRequests.isEmpty) // แสดงปุ่มเฉพาะเมื่อไม่มีคำขอ pending
              Positioned(
                bottom: -8,
                left: 60,
                right: 60,
                child: Padding(
                  padding: const EdgeInsets.all(10),
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
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
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

  // ใน moneytransfer.dart - แสดงคำขอ pending
  Widget _buildRequestList() {
    final pendingRequests =
        requests.where((r) => r.status == 'pending').toList();
    final completedRequests =
        requests.where((r) => r.status != 'pending').toList();

    return Column(
      children: [
        if (pendingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'คำขอที่รอดำเนินการ',
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
              'ประวัติคำขอ',
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
        if (requests.isEmpty) ...[
          SizedBox(height: 100),
          Icon(Icons.request_page, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีคำขอเบิกเงิน',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ],
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ชื่อ ${request.name} tel. ${request.phone}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
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
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

    return Center(
      child: Padding(
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
                    'ชื่อ ${request.name} tel.${request.phone}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF25634B),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ ใส่การแสดงสถานะตรงนี้ - ใต้ข้อมูลพื้นฐานและก่อนจำนวนเงิน
                _buildDetailRow('สถานะ', _getStatusText(request.status)),
                const SizedBox(height: 15),

                const Text(
                  'จำนวนเงินที่ต้องการเบิก',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${request.amount} บาท",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'วันที่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),

                // แสดงรูปภาพที่แนบมา (ถ้ามี)
                if (request.images.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  const Text(
                    'รูปภาพที่แนบมา:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF25634B),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: request.images.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                  'http://10.0.2.2:3000/uploads/${request.images[index]}'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // แสดงรูปภาพการอนุมัติ (ถ้ามี)
                if (request.approvalImage != null) ...[
                  const SizedBox(height: 15),
                  const Text(
                    'รูปภาพการอนุมัติ:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF25634B),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Image.network(
                    'http://10.0.2.2:3000/uploads/${request.approvalImage}',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ],

                // แสดงวันที่อนุมัติ (ถ้ามี)
                if (request.approvedAt != null) ...[
                  const SizedBox(height: 15),
                  _buildDetailRow(
                      'อนุมัติเมื่อ',
                      DateFormat('dd/MM/yyyy HH:mm')
                          .format(request.approvedAt!)),
                ],

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _editRequest(selectedRequestIndex!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('แก้ไข',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                        onPressed: _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(100, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('ลบ',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goBack,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Color(0xFF34D396)),
                        ),
                        child: const Text('กลับ',
                            style: TextStyle(
                              color: Color(0xFF34D396),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _goBack,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34D396),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('ปิด',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
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
  }

// ฟังก์ชันแสดงแถวรายละเอียด
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              ),
            ),
          ),
          Expanded(
            child: Text(value),
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
