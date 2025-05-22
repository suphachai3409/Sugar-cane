import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'อุปกรณ์',
      theme: ThemeData(
        primaryColor: const Color(0xFF30C39E),
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF30C39E),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF30C39E)),
        ),
      ),
      home: const CashAdvanceApp(),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({Key? key, required this.imagePath}) : super(key: key);

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
          // ปุ่มปิด
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
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
  const CashAdvanceApp({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _equipmentNameController = TextEditingController();
    _dateController = TextEditingController();
    _selectedDate = DateTime.now();

    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _equipmentNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _addNewRequest() {
    setState(() {
      showForm = true;
      selectedRequestIndex = null;
      _clearForm();
      _resetErrors();
    });
  }

  void _resetErrors() {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _equipmentNameError = null;
      _dateError = null;
      _imageError = null;
    });
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
      _showErrorDialog('ไม่สามารถเปิดกล้องได้ กรุณาตรวจสอบสิทธิ์การเข้าถึงกล้อง');
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
      _showErrorDialog('ไม่สามารถเปิดแกลเลอรี่ได้ กรุณาตรวจสอบสิทธิ์การเข้าถึงแกลเลอรี่');
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

  void _showImageSourceOptions() {
    showModalBottomSheet(
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
                leading: const Icon(Icons.photo_library, color: Color(0xFF30C39E)),
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
          content: const Text('คุณต้องการกลับโดยไม่บันทึกการเปลี่ยนแปลงใช่หรือไม่?'),
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
              child: const Text('ยืนยัน', style: TextStyle(color: Color(0xFF30C39E))),
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
        _equipmentNameController.text = requests[selectedRequestIndex!].equipmentName;
        _selectedDate = requests[selectedRequestIndex!].date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
        _selectedImagePath = requests[selectedRequestIndex!].imagePath;
      } else {
        // กลับไปที่หน้าลิสต์
        selectedRequestIndex = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อุปกรณ์', style: TextStyle(color: Colors.green, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: requests.isEmpty && !showForm ? null : _goBack,
        ),
      ),
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    if (showForm) {
      return _buildRequestForm();
    } else if (selectedRequestIndex != null) {
      return _buildRequestDetails();
    } else if (requests.isNotEmpty) {
      return _buildRequestsList();
    } else {
      return _buildEmptyInitialScreen();
    }
  }

  Widget _buildEmptyInitialScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF30C39E),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 40),
              onPressed: _addNewRequest,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'กดเพื่อเพิ่มอุปกรณ์',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
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
              final formattedDate = DateFormat('dd/MM/yyyy').format(request.date);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
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
                                  onTap: () => _showFullScreenImage(request.imagePath!),
                                  child: Hero(
                                    tag: 'image_${request.imagePath}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
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
                              SizedBox(width: request.imagePath != null ? 12 : 0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "ชื่อ ${request.name}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "เบอร์โทร: ${request.phone}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "อุปกรณ์: ${request.equipmentName}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addNewRequest,
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มอุปกรณ์'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF30C39E),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
                      onTap: () => _showFullScreenImage(_selectedImagePath!),
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
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
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
                        child: const Text('กลับ', style: TextStyle(color: Color(0xFF30C39E))),
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
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "ชื่อ ${request.name} ${request.phone}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  request.equipmentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showForm = true;
                        });
                      },
                      child: const Text('แก้ไข'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _showDeleteConfirmation,
                      child: const Text('ลบ'),
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
                        child: const Text('กลับ', style: TextStyle(color: Color(0xFF30C39E))),
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
                        child: const Text('ยืนยัน'),
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
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF30C39E),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              children: [
                Icon(Icons.home, color: Colors.white, size: 20),
                SizedBox(width: 5),
                Text('Home', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Icon(Icons.person, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }
}