import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'profile.dart';
import 'menu1.dart';
import 'menu2.dart';
import 'menu3.dart';

void main() {
  runApp(EquipmentScreen(userId: 'default_user_id'));
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
      body: EquipmentApp(userId: userId),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.imagePaths,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${initialIndex + 1}/${imagePaths.length}',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            itemCount: imagePaths.length,
            controller: PageController(initialPage: initialIndex),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: imagePaths[index].startsWith('http')
                      ? Image.network(
                          imagePaths[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.grey, size: 60),
                                    SizedBox(height: 16),
                                    Text('ไม่สามารถโหลดรูปภาพ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(imagePaths[index]),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, color: Colors.grey, size: 60),
                                    SizedBox(height: 16),
                                    Text('ไม่สามารถโหลดรูปภาพ', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('ออก'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.white),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EquipmentRequest {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String equipmentName;
  final String description;
  final DateTime date;
  final List<String> imagePaths;
  final int menu;

  EquipmentRequest({
    this.id = '',
    required this.userId,
    required this.name,
    required this.phone,
    required this.equipmentName,
    required this.description,
    required this.date,
    required this.imagePaths,
    required this.menu,
  });

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // ใช้ _id สำหรับ MongoDB
      'userId': userId,
      'name': name,
      'phone': phone,
      'equipmentName': equipmentName,
      'description': description,
      'date': date.toIso8601String(),
      'imagePaths': imagePaths,
      'menu': menu,
    };
  }

  factory EquipmentRequest.fromJson(Map<String, dynamic> json) {
    return EquipmentRequest(
      id: json['_id'] ?? '',
      userId: json['userId'],
      name: json['name'],
      phone: json['phone'],
      equipmentName: json['equipmentName'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      imagePaths: List<String>.from(json['imagePaths']),
      menu: json['menu'],
    );
  }
}

class EquipmentApp extends StatefulWidget {
  final String userId;

  const EquipmentApp({Key? key, required this.userId}) : super(key: key);

  @override
  State<EquipmentApp> createState() => _EquipmentAppState();
}

class _EquipmentAppState extends State<EquipmentApp> {
  late TextEditingController _equipmentNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late DateTime _selectedDate;
  List<String> _selectedImagePaths = [];
  final ImagePicker _picker = ImagePicker();

  String? _equipmentNameError;
  String? _descriptionError;
  String? _dateError;
  String? _imagesError;

  List<EquipmentRequest> requests = [];
  bool showForm = false;
  int? selectedRequestIndex;

  final String apiUrl = 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/equipment';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String get userId => widget.userId;

  @override
  void initState() {
    super.initState();
    _equipmentNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    fetchUserData();
    fetchEquipmentRequests();
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/pulluser'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _users = jsonData.cast<Map<String, dynamic>>();
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

  Future<void> fetchEquipmentRequests() async {
    setState(() => _isLoading = true);
    try {
      // เปลี่ยนจากการส่ง userId ไปดึงข้อมูลเฉพาะ เป็นดึงทั้งหมด
      final response = await http.get(
        Uri.parse(apiUrl), // ลบ ?userId=$userId ออก
        headers: {'Authorization': 'Bearer $userId'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          requests =
              jsonData.map((item) => EquipmentRequest.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print(
            'Failed to load equipment requests: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching equipment requests: $e');
    }
  }

  Future<void> saveEquipmentRequest() async {
    if (_validateInputs()) {
      // อัพโหลดรูปภาพไปยัง server ก่อน
      List<String> uploadedImageUrls = [];
      if (_selectedImagePaths.isNotEmpty) {
        uploadedImageUrls = await _uploadImages(_selectedImagePaths);
      }

      final request = {
        'userId': userId,
        'name': _currentUser?['name'] ?? '',
        'phone': _currentUser?['number']?.toString() ?? '',
        'equipmentName': _equipmentNameController.text,
        'description': _descriptionController.text,
        'date': _selectedDate.toIso8601String(),
        'imagePaths': uploadedImageUrls, // ใช้ URL ที่อัพโหลดแล้ว
        'menu': _currentUser?['menu'] ?? 1,
      };

      try {
        http.Response response;

        if (selectedRequestIndex != null &&
            requests[selectedRequestIndex!].id.isNotEmpty) {
          // กรณีแก้ไข
          response = await http.put(
            Uri.parse('$apiUrl/${requests[selectedRequestIndex!].id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userId',
            },
            body: jsonEncode(request),
          );
        } else {
          // กรณีเพิ่มใหม่
          response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $userId',
            },
            body: jsonEncode(request),
          );
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(selectedRequestIndex != null
                  ? 'แก้ไขข้อมูลสำเร็จ'
                  : 'บันทึกข้อมูลสำเร็จ'),
              backgroundColor: Color(0xFF30C39E),
            ),
          );
          await fetchEquipmentRequests(); // ดึงข้อมูลใหม่จาก server
          _clearForm();
          setState(() {
            selectedRequestIndex = null;
            showForm = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'เกิดข้อผิดพลาด: ${response.statusCode}\n${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCurrentScreen() {
    if (selectedRequestIndex != null) {
      return _buildRequestDetails();
    } else if (showForm) {
      return _buildRequestsList(); // แสดงรายการอุปกรณ์
    } else {
      if (_isLoading) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF34D396)),
              ),
              SizedBox(height: 16),
              Text(
                'กำลังโหลดข้อมูลอุปกรณ์...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      } else if (requests.isEmpty) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;
        return _buildEmptyInitialScreen(
            width, height); // แสดงหน้าว่างเมื่อไม่มีรายการ
      } else {
        return _buildRequestsList(); // แสดงรายการอุปกรณ์เมื่อมีข้อมูล
      }
    }
  }

  Widget _buildEmptyInitialScreen(double width, double height) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              showForm = true;
            });
            _showEquipmentFormPopup();
          },
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

  Future<void> deleteEquipmentRequest(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userId',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบรายการสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        fetchEquipmentRequests();
        setState(() {
          selectedRequestIndex = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('เกิดข้อผิดพลาดในการลบข้อมูล: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewRequest() {
    _clearForm();
    _resetErrors();
    _showEquipmentFormPopup();
  }

  void _resetErrors() {
    _equipmentNameError = null;
    _descriptionError = null;
    _dateError = null;
    _imagesError = null;
  }

  bool _validateInputs() {
    bool isValid = true;

    if (_equipmentNameController.text.isEmpty) {
      setState(() => _equipmentNameError = 'กรุณาระบุชื่ออุปกรณ์');
      isValid = false;
    }

    if (_descriptionController.text.isEmpty) {
      setState(() => _descriptionError = 'กรุณากรอกคำอธิบาย');
      isValid = false;
    }

    if (_selectedImagePaths.isEmpty) {
      setState(() => _imagesError = 'กรุณาเพิ่มรูปภาพอย่างน้อย 1 รูป');
      isValid = false;
    }

    return isValid;
  }

  void _showFullScreenImage(List<String> imagePaths, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: imagePaths,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _getImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        // Copy รูปภาพไปยัง directory ที่ถาวรกว่า
        final String permanentPath = await _copyImageToPermanentLocation(image.path);
        setState(() {
          _selectedImagePaths.add(permanentPath);
        });
      }
    } catch (e) {
      _showErrorDialog(
          'ไม่สามารถเปิดกล้องได้ กรุณาตรวจสอบสิทธิ์การเข้าถึงกล้อง');
    }
  }

  Future<void> _getImageFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final int remainingSlots = 5 - _selectedImagePaths.length;
        if (remainingSlots <= 0) {
          _showErrorDialog('คุณสามารถอัปโหลดได้สูงสุด 5 รูปภาพ');
          return;
        }

        final List<XFile> selectedImages = images.length > remainingSlots
            ? images.sublist(0, remainingSlots)
            : images;

        // Copy รูปภาพทั้งหมดไปยัง directory ที่ถาวรกว่า
        final List<String> permanentPaths = [];
        for (final image in selectedImages) {
          final String permanentPath = await _copyImageToPermanentLocation(image.path);
          permanentPaths.add(permanentPath);
        }

        setState(() {
          _selectedImagePaths.addAll(permanentPaths);
        });
      }
    } catch (e) {
      _showErrorDialog('ไม่สามารถเปิดแกลเลอรี่ได้');
    }
  }

  // ฟังก์ชัน copy รูปภาพไปยัง directory ที่ถาวรกว่า
  Future<String> _copyImageToPermanentLocation(String sourcePath) async {
    try {
      // สร้าง directory สำหรับเก็บรูปภาพถาวร
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imageDir = Directory(path.join(appDir.path, 'equipment_images'));
      
      // สร้าง directory ถ้ายังไม่มี
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      // สร้างชื่อไฟล์ใหม่ที่ไม่ซ้ำ
      final String fileName = 'equipment_${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourcePath)}';
      final String destinationPath = path.join(imageDir.path, fileName);
      
      // Copy ไฟล์
      final File sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);
      
      print('📁 Copied image from $sourcePath to $destinationPath');
      return destinationPath;
    } catch (e) {
      print('❌ Error copying image: $e');
      // ถ้า copy ไม่ได้ ให้ใช้ path เดิม
      return sourcePath;
    }
  }

  // ฟังก์ชันอัพโหลดรูปภาพไปยัง server
  Future<List<String>> _uploadImages(List<String> imagePaths) async {
    List<String> imageUrls = [];
    var uri = Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/upload');

    for (var imagePath in imagePaths) {
      try {
        var request = http.MultipartRequest('POST', uri);
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            filename: 'equipment_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);
          imageUrls.add(jsonResponse['imageUrl']);
          print('📤 Uploaded image: ${jsonResponse['imageUrl']}');
        } else {
          print('❌ Upload failed for $imagePath: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Error uploading $imagePath: $e');
      }
    }

    return imageUrls;
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
                title: const Text('ถ่ายรูปใหม่'),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromCamera();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF30C39E)),
                title: const Text('เลือกรูปจากแกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromGallery();
                },
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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

  void _editRequest(int index) {
    final request = requests[index];

    // ตรวจสอบว่าเป็นอุปกรณ์ของตัวเองเท่านั้นจึงจะแก้ไขได้
    if (request.userId != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('คุณสามารถแก้ไขเฉพาะอุปกรณ์ของคุณเท่านั้น'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Editing request at index: $index');
    print('Request data: ${request.toJson()}');
    setState(() {
      _equipmentNameController.text = request.equipmentName;
      _descriptionController.text = request.description;
      _selectedDate = request.date;
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _selectedImagePaths = List.from(request.imagePaths);
      selectedRequestIndex = index;
      showForm = true;
    });

    _showEquipmentFormPopup();
  }

  void _showDeleteConfirmation(String id, String requestUserId) {
    // ตรวจสอบว่าเป็นอุปกรณ์ของตัวเองเท่านั้นจึงจะลบได้
    if (requestUserId != userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('คุณสามารถลบเฉพาะอุปกรณ์ของคุณเท่านั้น'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteEquipmentRequest(id);
              },
              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _equipmentNameController.clear();
    _descriptionController.clear();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _selectedImagePaths.clear();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedRequestIndex != null) {
          setState(() {
            selectedRequestIndex = null;
          });
          return false; // ป้องกันการปิดหน้าจอ
        }
        return true; // อนุญาตให้ปิดหน้าจอได้
      },
      child: Scaffold(
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
              if (selectedRequestIndex != null) {
                setState(() {
                  selectedRequestIndex = null;
                });
              } else if (showForm) {
                setState(() {
                  showForm = false;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: _buildCurrentScreen(),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildRequestsList() {
    return Column(
      children: [
        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF30C39E).withOpacity(0.1),
                              Color(0xFF25A085).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          Icons.devices_other_outlined,
                          size: 36,
                          color: Color(0xFF30C39E),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ยังไม่มีอุปกรณ์',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'เริ่มเพิ่มอุปกรณ์แรกของคุณ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final formattedDate =
                        DateFormat('dd MMM').format(request.date);
                    final isSelected = selectedRequestIndex == index;
                    final isCurrentUser = request.userId == userId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  Color(0xFF30C39E).withOpacity(0.05),
                                  Color(0xFF25A085).withOpacity(0.05),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFF30C39E).withOpacity(0.3)
                              : Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? Color(0xFF30C39E).withOpacity(0.1)
                                : Colors.black.withOpacity(0.02),
                            blurRadius: isSelected ? 8 : 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedRequestIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header - เพิ่มการแสดงว่าเป็นของตัวเองหรือไม่
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            isCurrentUser
                                                ? Color(0xFF30C39E)
                                                : Color(
                                                    0xFF9E30C3), // สีต่างกันถ้าไม่ใช่ของตัวเอง
                                            isCurrentUser
                                                ? Color(0xFF25A085)
                                                : Color(0xFF8525A0),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isCurrentUser
                                            ? Icons.person_outline
                                            : Icons.people_outline,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request.equipmentName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2D3748),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isCurrentUser
                                                      ? Color(0xFF30C39E)
                                                          .withOpacity(0.1)
                                                      : Color(0xFF9E30C3)
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: isCurrentUser
                                                        ? Color(0xFF25634B)
                                                        : Color(0xFF634B25),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              if (!isCurrentUser)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF9E30C3)
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    'ผู้ใช้: ${request.name}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF634B25),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12),

                                // Contact Info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF7FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.person_outline,
                                                size: 12,
                                                color: Color(0xFF4A5568),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                request.name,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF2D3748),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.phone_outlined,
                                              size: 12,
                                              color: Color(0xFF4A5568),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            request.phone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Images
                                if (request.imagePaths.isNotEmpty) ...[
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF30C39E)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.photo_library_outlined,
                                          size: 12,
                                          color: Color(0xFF25634B),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '${request.imagePaths.length} รูป',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4A5568),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  SizedBox(
                                    height: 60,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: request.imagePaths.length > 3
                                          ? 3
                                          : request.imagePaths.length,
                                      itemBuilder: (context, imgIndex) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: request.imagePaths[imgIndex].startsWith('http')
                                                ? Image.network(
                                                    request.imagePaths[imgIndex],
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 60,
                                                        height: 60,
                                                        color: Colors.grey[200],
                                                        child: Icon(Icons.broken_image, color: Colors.grey),
                                                      );
                                                    },
                                                  )
                                                : Image.file(
                                                    File(request.imagePaths[imgIndex]),
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 60,
                                                        height: 60,
                                                        color: Colors.grey[200],
                                                        child: Icon(Icons.broken_image, color: Colors.grey),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (request.imagePaths.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '+${request.imagePaths.length - 3} รูปเพิ่ม',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF718096),
                                        ),
                                      ),
                                    ),
                                ],

                                SizedBox(height: 12),

                                // Action Button
                                Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              Color(0xFF30C39E),
                                              Color(0xFF25A085)
                                            ],
                                          )
                                        : null,
                                    color:
                                        isSelected ? null : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(0xFF30C39E),
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedRequestIndex = index;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.visibility_outlined,
                                              size: 14,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Color(0xFF30C39E),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'ดูรายละเอียด',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Color(0xFF30C39E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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

        // Add Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF30C39E), Color(0xFF25A085)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF30C39E).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addNewRequest,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'เพิ่มอุปกรณ์ใหม่',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF30C39E),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedRequestIndex != null
                                ? 'แก้ไขอุปกรณ์'
                                : 'เพิ่มอุปกรณ์ใหม่',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ชื่อ-นามสกุล (จากโปรไฟล์)
                            _buildFormField(
                              label: 'ชื่อ-นามสกุล',
                              value: _currentUser?['name'] ?? '',
                              isReadOnly: true,
                            ),
                            SizedBox(height: 15),

                            // เบอร์โทรศัพท์ (จากโปรไฟล์)
                            _buildFormField(
                              label: 'เบอร์โทรศัพท์',
                              value: _currentUser?['number']?.toString() ?? '',
                              isReadOnly: true,
                            ),
                            SizedBox(height: 15),

                            // ชื่ออุปกรณ์
                            _buildTextField(
                              controller: _equipmentNameController,
                              label: 'ชื่ออุปกรณ์*',
                              hintText: 'ระบุชื่ออุปกรณ์',
                              errorText: _equipmentNameError,
                              onChanged: (value) {
                                if (_equipmentNameError != null) {
                                  setStateDialog(
                                      () => _equipmentNameError = null);
                                }
                              },
                            ),
                            SizedBox(height: 15),

                            // คำอธิบาย
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'คำอธิบาย*',
                              hintText: 'กรอกคำอธิบายเกี่ยวกับอุปกรณ์',
                              errorText: _descriptionError,
                              maxLines: 3,
                              onChanged: (value) {
                                if (_descriptionError != null) {
                                  setStateDialog(
                                      () => _descriptionError = null);
                                }
                              },
                            ),
                            SizedBox(height: 15),

                            // วันที่
                            Text(
                              'วันที่*',
                              style: TextStyle(
                                color: Color(0xFF30C39E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                suffixIcon:
                                    Icon(Icons.calendar_today, size: 20),
                                errorText: _dateError,
                              ),
                              onTap: () async {
                                await _selectDate(context);
                                setStateDialog(() {});
                              },
                            ),
                            SizedBox(height: 20),

                            // รูปภาพอุปกรณ์
                            Text(
                              'รูปภาพอุปกรณ์* (สูงสุด 5 รูป)',
                              style: TextStyle(
                                color: Color(0xFF30C39E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'เพิ่มรูปภาพอุปกรณ์ที่ต้องการแสดง',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 10),

                            // แสดงรูปภาพที่มีอยู่
                            if (_selectedImagePaths.isNotEmpty)
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImagePaths.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          margin: EdgeInsets.only(right: 10),
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.grey[300]!),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.file(
                                              File(_selectedImagePaths[index]),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Center(
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                          color: Colors.grey)),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 5,
                                          right: 5,
                                          child: GestureDetector(
                                            onTap: () {
                                              setStateDialog(() {
                                                _selectedImagePaths
                                                    .removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                            // ปุ่มเพิ่มรูปภาพ
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _selectedImagePaths.length < 5
                                        ? () async {
                                            await _showImageSourceOptions();
                                            setStateDialog(() {});
                                          }
                                        : null,
                                    icon: Icon(Icons.add_a_photo, size: 20),
                                    label: Text(
                                      'เพิ่มรูปภาพ',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _selectedImagePaths.length < 5
                                              ? Color(0xFF30C39E)
                                              : Colors.grey[400],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_imagesError != null)
                              Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Text(
                                  _imagesError!,
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                ),
                              ),
                            SizedBox(height: 20),

                            // หมายเหตุ
                            Text(
                              '* หมายถึงข้อมูลที่จำเป็นต้องกรอก',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 20),

                            // ปุ่มบันทึกและยกเลิก
                            Row(
                              children: [
                                Expanded(
                                    child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'ยกเลิก',
                                    style: TextStyle(
                                      color: Color(0xFF30C39E),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    side: BorderSide(color: Color(0xFF30C39E)),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                )),
                                SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_validateInputs()) {
                                        saveEquipmentRequest();
                                        Navigator.of(context).pop();
                                      } else {
                                        setStateDialog(() {});
                                      }
                                    },
                                    child: Text(
                                      'บันทึก',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF30C39E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildFormField(
      {required String label, required String value, bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF30C39E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        TextFormField(
          initialValue: value,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            filled: isReadOnly,
            fillColor: Colors.grey[100],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? errorText,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Color(0xFF30C39E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            errorText: errorText,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRequestDetails() {
    if (selectedRequestIndex == null) {
      return Center(child: CircularProgressIndicator());
    }

    final request = requests[selectedRequestIndex!];
    final formattedDate = DateFormat('dd/MM/yyyy').format(request.date);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนหัวข้อมูล - แสดงชื่อคน (owner) แบบใหม่
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                // ชื่อคน (owner)
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "โดย  ",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: request.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF30C39E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // เส้นคั่นสวยๆ
                Container(
                  height: 1,
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF30C39E).withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // แกลเลอรี่รูปภาพ
          if (request.imagePaths.isNotEmpty) ...[
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PageView.builder(
                  itemCount: request.imagePaths.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () =>
                          _showFullScreenImage(request.imagePaths, index),
                      child: request.imagePaths[index].startsWith('http')
                          ? Image.network(
                              request.imagePaths[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                        SizedBox(height: 8),
                                        Text('ไม่สามารถโหลดรูปภาพ', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(request.imagePaths[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                        SizedBox(height: 8),
                                        Text('ไม่สามารถโหลดรูปภาพ', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF30C39E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${request.imagePaths.length} รูปภาพ',
                  style: TextStyle(
                    color: Color(0xFF25634B),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ข้อมูลรายละเอียด (รวมชื่ออุปกรณ์)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                      Icons.devices, 'ชื่ออุปกรณ์', request.equipmentName),
                  const Divider(height: 20, thickness: 1),
                  _buildDetailItem(Icons.phone, 'เบอร์โทรศัพท์', request.phone),
                  const Divider(height: 20, thickness: 1),
                  _buildDetailItem(
                      Icons.calendar_today, 'วันที่', formattedDate),
                  const Divider(height: 20, thickness: 1),
                  _buildDetailItem(
                      Icons.description, 'คำอธิบาย', request.description),
                  const Divider(height: 20, thickness: 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // ปุ่มดำเนินการ
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _editRequest(selectedRequestIndex!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF30C39E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'แก้ไข',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (request.userId == userId)
                  ElevatedButton(
                    onPressed: () =>
                        _showDeleteConfirmation(request.id, request.userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ลบ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Color(0xFF30C39E)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF25634B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
                bottom: height * 0.01,
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
                      padding: EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(38),
                        child: Image.asset(
                          'assets/โฮม.png',
                          fit: BoxFit.contain,
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
                      padding: EdgeInsets.all(6),
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
                                fit: BoxFit.contain,
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
