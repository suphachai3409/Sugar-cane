import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(
      EquipmentScreen(userId: 'default_user_id')); // ใช้ค่าจริงจากระบบล็อกอิน
}

class EquipmentScreen extends StatelessWidget {
  final String userId;

  const EquipmentScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: CashAdvanceApp(userId: userId), // หรือเนื้อหาของหน้า Equipment
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // แสดงรูปภาพแบบเต็มหน้าจอ
          Center(
            child: Hero(
              tag: 'image_$imagePath',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CashAdvanceRequest {
  final String name;
  final String phone;
  final String equipmentName;
  final DateTime date;
  final String? imagePath;

  CashAdvanceRequest({
    required this.name,
    required this.phone,
    required this.equipmentName,
    required this.date,
    this.imagePath,
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
  late TextEditingController _equipmentNameController;
  late TextEditingController _dateController;
  late DateTime _selectedDate;
  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  String? _nameError;
  String? _phoneError;
  String? _equipmentNameError;
  String? _dateError;
  String? _imageError;

  List<CashAdvanceRequest> requests = [];
  bool showForm = false;
  int? selectedRequestIndex;
  // เพิ่มตัวแปรสำหรับ profile
  final String apiUrl = 'http://10.0.2.2:3000/pulluser';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String get userId => widget.userId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _equipmentNameController = TextEditingController();
    _dateController = TextEditingController();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _equipmentNameController.dispose();
    _dateController.dispose();
    super.dispose();
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

  // ฟังก์ชันแสดง profile dialog
  void _showProfileDialog() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบข้อมูลผู้ใช้'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
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

                // User Information
                _buildInfoCard(
                  icon: Icons.account_circle,
                  title: 'ชื่อผู้ใช้',
                  value: _currentUser!['username'] ?? 'ไม่มีข้อมูล',
                  color: Colors.purple,
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.person,
                  title: 'ชื่อ',
                  value: _currentUser!['name'] ?? 'ไม่มีข้อมูล',
                  color: Color(0xFF25624B),
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.email,
                  title: 'อีเมล',
                  value: _currentUser!['email'] ?? 'ไม่มีข้อมูล',
                  color: Colors.orange,
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.phone,
                  title: 'เบอร์โทร',
                  value: _currentUser!['number']?.toString() ?? 'ไม่มีข้อมูล',
                  color: Colors.blue,
                ),
                SizedBox(height: 12),

                _buildInfoCard(
                  icon: Icons.menu_book,
                  title: 'เมนู',
                  value:
                      'Menu ${_currentUser!['menu']?.toString() ?? 'ไม่ระบุ'}',
                  color: Color(0xFF34D396),
                ),

                SizedBox(height: 25),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
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
          ),
        );
      },
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

  void _addNewRequest() {
    _clearForm();
    _resetErrors();
    _showEquipmentFormPopup();
  }

  void _resetErrors() {
    _nameError = null;
    _phoneError = null;
    _equipmentNameError = null;
    _dateError = null;
    _imageError = null;
  }

  // ฟังก์ชันตรวจสอบข้อมูลใน popup
  bool _validateInputsInPopup(StateSetter setStateDialog) {
    bool isValid = true;

    setStateDialog(() {
      _resetErrors();

      if (_nameController.text.isEmpty) {
        _nameError = "กรุณาระบุชื่อ-นามสกุล";
        isValid = false;
      }

      if (_phoneController.text.isEmpty) {
        _phoneError = "กรุณาระบุเบอร์โทรศัพท์";
        isValid = false;
      } else if (!RegExp(r'^[0-9]{9,10}$').hasMatch(_phoneController.text)) {
        _phoneError = "กรุณาระบุเบอร์โทรศัพท์ที่ถูกต้อง";
        isValid = false;
      }

      if (_equipmentNameController.text.isEmpty) {
        _equipmentNameError = "กรุณาระบุชื่ออุปกรณ์";
        isValid = false;
      }

      if (_dateController.text.isEmpty) {
        _dateError = "กรุณาเลือกวันที่";
        isValid = false;
      }
    });

    return isValid;
  }

  // ฟังก์ชันบันทึกข้อมูลจาก popup
  void _saveRequestFromPopup() {
    setState(() {
      requests.add(CashAdvanceRequest(
        name: _nameController.text,
        phone: _phoneController.text,
        equipmentName: _equipmentNameController.text,
        date: _selectedDate,
        imagePath: _selectedImagePath,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกข้อมูลสำเร็จ'),
          backgroundColor: Color(0xFF30C39E),
        ),
      );
    });
  }

  // เพิ่มฟังก์ชันสำหรับแสดงรูปภาพแบบเต็มหน้าจอ
  void _showFullScreenImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imagePath: imagePath),
      ),
    );
  }

  Future<void> _getImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      _showErrorDialog(
          'ไม่สามารถเปิดกล้องได้ กรุณาตรวจสอบสิทธิ์การเข้าถึงกล้อง');
    }
  }

  Future<void> _getImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      _showErrorDialog(
          'ไม่สามารถเปิดแกลเลอรี่ได้ กรุณาตรวจสอบสิทธิ์การเข้าถึงแกลเลอรี่');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageSourceOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF30C39E)),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromCamera();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF30C39E)),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromGallery();
                },
              ),
              if (_selectedImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('ลบรูปภาพ'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImagePath = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _resetErrors();

      if (_nameController.text.isEmpty) {
        _nameError = "กรุณาระบุชื่อ-นามสกุล";
        isValid = false;
      }

      if (_phoneController.text.isEmpty) {
        _phoneError = "กรุณาระบุเบอร์โทรศัพท์";
        isValid = false;
      } else if (!RegExp(r'^[0-9]{9,10}$').hasMatch(_phoneController.text)) {
        _phoneError = "กรุณาระบุเบอร์โทรศัพท์ที่ถูกต้อง";
        isValid = false;
      }

      if (_equipmentNameController.text.isEmpty) {
        _equipmentNameError = "กรุณาระบุชื่ออุปกรณ์";
        isValid = false;
      }

      if (_dateController.text.isEmpty) {
        _dateError = "กรุณาเลือกวันที่";
        isValid = false;
      }
    });

    return isValid;
  }

  void _saveRequest() {
    if (_validateInputs()) {
      setState(() {
        if (selectedRequestIndex != null) {
          // Update existing request
          requests[selectedRequestIndex!] = CashAdvanceRequest(
            name: _nameController.text,
            phone: _phoneController.text,
            equipmentName: _equipmentNameController.text,
            date: _selectedDate,
            imagePath: _selectedImagePath,
          );
        } else {
          // Add new request
          requests.add(CashAdvanceRequest(
            name: _nameController.text,
            phone: _phoneController.text,
            equipmentName: _equipmentNameController.text,
            date: _selectedDate,
            imagePath: _selectedImagePath,
          ));
        }
        showForm = false;
        selectedRequestIndex = null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            backgroundColor: Color(0xFF30C39E),
          ),
        );
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
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
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      });
    }
  }

  void _showRequestDetails(int index) {
    setState(() {
      selectedRequestIndex = index;
      _nameController.text = requests[index].name;
      _phoneController.text = requests[index].phone;
      _equipmentNameController.text = requests[index].equipmentName;
      _selectedDate = requests[index].date;
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _selectedImagePath = requests[index].imagePath;
      showForm = false;
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
        showForm = false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบรายการสำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  void _showFormBackConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('ยืนยันการกลับ'),
          content:
              const Text('คุณต้องการกลับโดยไม่บันทึกการเปลี่ยนแปลงใช่หรือไม่?'),
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
                _goBackFromForm();
              },
              child: const Text('ยืนยัน',
                  style: TextStyle(color: Color(0xFF30C39E))),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _equipmentNameController.clear();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _selectedImagePath = null;
  }

  void _goBack() {
    setState(() {
      if (selectedRequestIndex != null) {
        selectedRequestIndex = null;
      } else if (showForm) {
        _showFormBackConfirmation();
      }
    });
  }

  void _goBackFromForm() {
    setState(() {
      showForm = false;
      if (selectedRequestIndex != null) {
        // กลับไปที่หน้ารายละเอียด
        _nameController.text = requests[selectedRequestIndex!].name;
        _phoneController.text = requests[selectedRequestIndex!].phone;
        _equipmentNameController.text =
            requests[selectedRequestIndex!].equipmentName;
        _selectedDate = requests[selectedRequestIndex!].date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
        _selectedImagePath = requests[selectedRequestIndex!].imagePath;
      } else {
        // กลับไปที่หน้าลิสต์
        selectedRequestIndex = null;
      }
    });
  }

  // ฟังก์ชันสำหรับแก้ไขข้อมูล
  void _editRequest(int index) {
    setState(() {
      selectedRequestIndex = index;
      _nameController.text = requests[index].name;
      _phoneController.text = requests[index].phone;
      _equipmentNameController.text = requests[index].equipmentName;
      _selectedDate = requests[index].date;
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _selectedImagePath = requests[index].imagePath;
      showForm = false; // ปิดฟอร์มปัจจุบัน
    });
    _showEquipmentFormPopup(); // เรียกใช้ Popup สำหรับแก้ไข
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อุปกรณ์',
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
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    if (showForm) {
      return _buildRequestForm();
    } else if (selectedRequestIndex != null) {
      return _buildRequestDetails();
    } else if (requests.isNotEmpty) {
      return _buildRequestsList();
    } else {
      return _buildEmptyInitialScreen(width, height);
    }
  }

  Widget _buildEmptyInitialScreen(double width, double height) {
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
                'กดเพื่อเพิ่มอุปกรณ์',
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

  Widget _buildRequestsList() {
    return Column(
      children: [
        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Text(
                    'ไม่มีรายการอุปกรณ์',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final formattedDate =
                        DateFormat('dd/MM/yyyy').format(request.date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => _showRequestDetails(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // แสดงรูปภาพขนาดเล็กในลิสต์ถ้ามี
                                    if (request.imagePath != null)
                                      GestureDetector(
                                        onTap: () => _showFullScreenImage(
                                            request.imagePath!),
                                        child: Hero(
                                          tag: 'image_${request.imagePath}',
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 60,
                                              height: 60,
                                              child: Image.file(
                                                File(request.imagePath!),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    SizedBox(
                                        width:
                                            request.imagePath != null ? 12 : 0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "ชื่อ ${request.name}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF25634B),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "เบอร์โทร: ${request.phone}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF25634B),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "อุปกรณ์: ${request.equipmentName}",
                                                  style: const TextStyle(
                                                    color: Color(0xFF25634B),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                        ],
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
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 250,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _addNewRequest,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'เพิ่มอุปกรณ์',
                style: TextStyle(
                  color: Colors.white,
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
    );
  }

  // ฟังก์ชันสำหรับแสดง popup ฟอร์มเพิ่มอุปกรณ์
  void _showEquipmentFormPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: EdgeInsets.all(16),
              child: Container(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.85,
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
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  selectedRequestIndex != null
                                      ? 'แก้ไขอุปกรณ์ที่ใช้ในการเกษตร'
                                      : 'เพิ่มอุปกรณ์ที่ใช้ในการเกษตร',
                                  style: TextStyle(
                                    color: Color(0xFF25634B),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close, color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // ชื่อ-นามสกุล
                        Text(
                          'ชื่อ-นามสกุล',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
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
                            setStateDialog(() {
                              if (_nameError != null) _nameError = null;
                            });
                          },
                        ),
                        SizedBox(height: 15),

                        // เบอร์โทรศัพท์
                        Text(
                          'เบอร์โทรศัพท์',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
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
                            setStateDialog(() {
                              if (_phoneError != null) _phoneError = null;
                            });
                          },
                        ),
                        SizedBox(height: 15),

                        // ชื่ออุปกรณ์
                        Text(
                          'ชื่ออุปกรณ์',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        TextField(
                          controller: _equipmentNameController,
                          decoration: InputDecoration(
                            hintText: 'ระบุชื่ออุปกรณ์',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            errorText: _equipmentNameError,
                          ),
                          onChanged: (value) {
                            setStateDialog(() {
                              if (_equipmentNameError != null)
                                _equipmentNameError = null;
                            });
                          },
                        ),
                        SizedBox(height: 15),

                        // วันที่
                        Text(
                          'วันที่',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
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
                            await _selectDate(context);
                            setStateDialog(() {});
                          },
                        ),
                        SizedBox(height: 15),

                        // รูปภาพอุปกรณ์
                        Text(
                          'รูปภาพอุปกรณ์',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        GestureDetector(
                          onTap: () async {
                            await _showImageSourceOptions();
                            setStateDialog(() {});
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _selectedImagePath != null
                                ? GestureDetector(
                                    onTap: () => _showFullScreenImage(
                                        _selectedImagePath!),
                                    child: Hero(
                                      tag: 'image_form_${_selectedImagePath}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(_selectedImagePath!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo,
                                          size: 40, color: Colors.grey[400]),
                                      SizedBox(height: 5),
                                      Text(
                                        'เพิ่มรูปภาพ',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (_imageError != null)
                          Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              _imageError!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        SizedBox(height: 30),

                        // ปุ่มบันทึกและยกเลิก
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('ยกเลิก',
                                    style: TextStyle(
                                      color: Color(0xFF30C39E),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    )),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  side: BorderSide(color: Color(0xFF30C39E)),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_validateInputsInPopup(setStateDialog)) {
                                    _saveRequestFromPopup();
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: Text('บันทึก',
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    )),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF30C39E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
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

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
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
                    'เพิ่มอุปกรณ์ที่ใช้ในการเกษตร',
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
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'ระบุชื่อ-นามสกุล',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'เบอร์โทรศัพท์',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10, // จำกัดความยาวเบอร์โทรศัพท์
                  decoration: InputDecoration(
                    hintText: 'ระบุเบอร์โทรศัพท์',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    errorText: _phoneError,
                    counterText: "", // ซ่อนตัวนับจำนวนตัวอักษร
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'ชื่ออุปกรณ์',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _equipmentNameController,
                  decoration: InputDecoration(
                    hintText: 'ระบุชื่ออุปกรณ์',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    errorText: _equipmentNameError,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'วันที่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'เลือกวันที่',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                    errorText: _dateError,
                  ),
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 15),
                const Text(
                  'รูปภาพอุปกรณ์',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedImagePath != null
                        ? GestureDetector(
                            onTap: () =>
                                _showFullScreenImage(_selectedImagePath!),
                            child: Hero(
                              tag: 'image_form_${_selectedImagePath}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_selectedImagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 5),
                              Text(
                                'เพิ่มรูปภาพ',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      _imageError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showFormBackConfirmation,
                        child: const Text('กลับ',
                            style: TextStyle(color: Color(0xFF30C39E))),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Color(0xFF30C39E)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveRequest,
                        child: const Text('บันทึก'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF30C39E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
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
                    'อุปกรณ์ที่ใช้ในการเกษตร',
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
                    "ชื่อ ${request.name} tel.${request.phone}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF25634B),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // เพิ่มการแสดงรูปภาพถ้ามีและทำให้สามารถกดเพื่อดูแบบเต็มหน้าจอได้
                if (request.imagePath != null)
                  Center(
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(request.imagePath!),
                      child: Hero(
                        tag: 'image_details_${request.imagePath}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(request.imagePath!),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (request.imagePath != null) const SizedBox(height: 20),
                const Text(
                  'ชื่ออุปกรณ์',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  request.equipmentName,
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
                      child: const Text('ลบ',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goBack,
                        child: const Text('กลับ',
                            style: TextStyle(
                              color: Color(0xFF30C39E),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Color(0xFF30C39E)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _goBack();
                        },
                        child: const Text('ยืนยัน',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF30C39E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
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

              // ปุ่มขวา
              Positioned(
                bottom: height * 0.01,
                right: width * 0.07,
                child: GestureDetector(
                  onTap: () {
                    if (_currentUser == null && !_isLoading) {
                      fetchUserData().then((_) {
                        if (_currentUser != null) {
                          _showProfileDialog();
                        }
                      });
                    } else if (_currentUser != null) {
                      _showProfileDialog();
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
