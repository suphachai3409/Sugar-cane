// farmerscreen.dart - ส่วนที่แก้ไข
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'plot2.dart';
import 'cash_advance_requests_screen.dart'; // ✅ เพิ่ม import
import 'menu1.dart';
import 'menu2.dart';
import 'menu3.dart';

class FarmerSreen extends StatefulWidget {
  final String userId;

  const FarmerSreen({Key? key, required this.userId}) : super(key: key);

  @override
  _FarmerSreenState createState() => _FarmerSreenState();
}

class _FarmerSreenState extends State<FarmerSreen> {
  List<Map<String, dynamic>> farmers = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> cashAdvanceCounts = {}; // ✅ เพิ่มตัวแปรนับคำขอเบิกเงิน

  // เพิ่มตัวแปรสำหรับ fetchUserData
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchFarmers();
    _fetchCashAdvanceCounts(); // ✅ เรียกฟังก์ชันนับคำขอเบิกเงิน
  }

  // ✅ เพิ่มฟังก์ชันนับคำขอเบิกเงินสำหรับลูกไร่
  Future<void> _fetchCashAdvanceCounts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/cash-advance/requests/${widget.userId}/farmer'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Map<String, int> counts = {};

        if (data['success'] == true && data['requests'] != null) {
          for (var request in data['requests']) {
            String farmerId = request['userId'];
            counts[farmerId] = (counts[farmerId] ?? 0) + 1;
          }
        }

        setState(() {
          cashAdvanceCounts = counts;
        });
      }
    } catch (e) {
      print('Error fetching cash advance counts: $e');
    }
  }

  // ✅ ฟังก์ชันดูคำขอเบิกเงินของลูกไร่
  void _viewCashAdvanceRequests(String farmerId, String farmerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashAdvanceRequestsScreen(
          userId: widget.userId,
          type: 'farmer', // ✅ เปลี่ยนจาก 'worker' เป็น 'farmer'
          targetUserId: farmerId,
          targetUserName: farmerName,
        ),
      ),
    );
  }

  Future<void> fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiUrl = 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/pulluser';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _users = jsonData.cast<Map<String, dynamic>>();
          // ถ้ามี userId ให้หาข้อมูลผู้ใช้นั้น ถ้าไม่มีให้ใช้คนแรก
          if (widget.userId.isNotEmpty) {
            _currentUser = _users.firstWhere(
              (user) => user['_id'] == widget.userId,
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

  Future<void> fetchFarmers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('🔄 กำลังดึงข้อมูลลูกไร่สำหรับ ownerId: ${widget.userId}');

      final response = await http.get(
        Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/profile/farmers/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userId}',
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            farmers = List<Map<String, dynamic>>.from(data['farmers'] ?? []);
            isLoading = false;
          });
          print('✅ ดึงข้อมูลลูกไร่สำเร็จ: ${farmers.length} คน');
          // เพิ่ม debug print เพื่อดูข้อมูล
          for (int i = 0; i < farmers.length; i++) {
            print('👤 ลูกไร่ที่ $i: ${farmers[i]}');
            print(
                '   - ชื่อ: ${farmers[i]['userId']?['name'] ?? farmers[i]['name']}');
            print('   - อีเมล: ${farmers[i]['userId']?['email']}');
            print('   - เบอร์โทร: ${farmers[i]['userId']?['number']}');
          }
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'ไม่สามารถดึงข้อมูลได้';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              'เกิดข้อผิดพลาดในการดึงข้อมูล (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาด: $e';
        isLoading = false;
      });
    }
  }

  void _showFarmerDetailDialog(
      BuildContext context, Map<String, dynamic> farmer) {
    final farmerId = farmer['userId']?['_id'] ?? farmer['_id'];
    final farmerName =
        farmer['userId']?['name'] ?? farmer['name'] ?? 'ไม่มีชื่อ';
    final requestCount =
        cashAdvanceCounts[farmerId] ?? 0; // ✅ จำนวนคำขอเบิกเงิน

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'รายละเอียดลูกไร่',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  farmerName,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(0xFF34D396).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF34D396).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).pop(); // ปิด Dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Plot2Screen(
                                    userId: widget.userId,
                                    farmer: farmer,
                                  ),
                                ),
                              );
                            },
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.agriculture,
                                    color: Color(0xFF34D396),
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'ดูแปลงปลูก',
                                    style: TextStyle(
                                      color: Color(0xFF34D396),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // ✅ แทนที่เงินลงทุนด้วยคำขอเบิกเงิน
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF34D396).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF34D396).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _viewCashAdvanceRequests(
                                    farmerId, farmerName),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Color(0xFF34D396),
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'คำขอเบิกเงิน',
                                        style: TextStyle(
                                          color: Color(0xFF34D396),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (requestCount > 0)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  requestCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'ปิด',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF25634B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ลูกไร่',
          style: TextStyle(
            color: Color(0xFF25634B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF25634B)),
            onPressed: fetchFarmers,
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF34D396)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'กำลังโหลดข้อมูลลูกไร่...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'เกิดข้อผิดพลาด',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchFarmers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF34D396),
                              foregroundColor: Colors.white,
                            ),
                            child: Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    )
                  : farmers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ยังไม่มีลูกไร่',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'สร้างรหัสความสัมพันธ์เพื่อเพิ่มลูกไร่',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF34D396),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('กลับไป'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: farmers.length,
                          itemBuilder: (context, index) {
                            final farmer = farmers[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF34D396).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: farmer['userId']?['profileImage'] !=
                                              null &&
                                          farmer['userId']['profileImage']
                                              .toString()
                                              .isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: Image.network(
                                            'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/uploads/${farmer['userId']['profileImage']}',
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.engineering,
                                                color: Color(0xFF34D396),
                                                size: 30,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.engineering,
                                          color: Color(0xFF34D396),
                                          size: 30,
                                        ),
                                ),
                                title: Text(
                                  farmer['userId']?['name'] ??
                                      farmer['name'] ??
                                      'ไม่มีชื่อ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF25634B),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      'เบอร์โทร: ${farmer['userId']?['number'] ?? 'ไม่มีข้อมูล'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (farmer['userId']?['email'] != null) ...[
                                      SizedBox(height: 2),
                                      Text(
                                        'อีเมล: ${farmer['userId']['email']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                                onTap: () {
                                  _showFarmerDetailDialog(context, farmer);
                                },
                              ),
                            );
                          },
                        ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 1,
            left: 0,
            right: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }
}
