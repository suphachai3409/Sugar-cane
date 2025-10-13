import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl.startsWith('http') 
                    ? imageUrl 
                    : 'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/uploads/$imageUrl',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  final fullImageUrl = imageUrl.startsWith('http') 
                      ? imageUrl 
                      : 'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/uploads/$imageUrl';
                  print('❌ Cash advance full screen image load error: $error');
                  print('❌ Failed URL: $fullImageUrl');
                  return Center(
                    child: Icon(Icons.error, color: Colors.white, size: 50),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    final fullImageUrl = imageUrl.startsWith('http') 
                        ? imageUrl 
                        : 'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/uploads/$imageUrl';
                    print('✅ Cash advance full screen image loaded: $fullImageUrl');
                    return child;
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),

          // ปุ่ม X สำหรับปิด
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
        ],
      ),
    );
  }
}

class CashAdvanceRequestsScreen extends StatefulWidget {
  final String userId;
  final String type; // 'worker' หรือ 'farmer'
  final String targetUserId;
  final String targetUserName;

  const CashAdvanceRequestsScreen({
    Key? key,
    required this.userId,
    required this.type,
    required this.targetUserId,
    required this.targetUserName,
  }) : super(key: key);

  @override
  _CashAdvanceRequestsScreenState createState() =>
      _CashAdvanceRequestsScreenState();
}

class _CashAdvanceRequestsScreenState extends State<CashAdvanceRequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _approveRequestWithImage(String requestId) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // แสดง loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );

        var uri = Uri.parse('https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/api/upload');
        var request = http.MultipartRequest('POST', uri);
        request.files
            .add(await http.MultipartFile.fromPath('image', pickedFile.path));

        var response = await request.send();

        // ปิด loading
        Navigator.pop(context);

        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);
          String approvalImageUrl = jsonResponse['imageUrl'];

          final updateResponse = await http.put(
            Uri.parse(
                'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/api/cash-advance/request/$requestId'),
            headers: {
              "Content-Type": "application/json",
              "user-id": widget.userId
            },
            body: jsonEncode({
              'status': 'approved',
              'approvalImage': approvalImageUrl,
              'approvedAt': DateTime.now().toIso8601String(),
            }),
          );

          if (updateResponse.statusCode == 200) {
            // ✅ อัปเดตรายการเฉพาะตัวที่เปลี่ยนสถานะ ไม่โหลดใหม่ทั้งหน้า
            setState(() {
              final index =
                  _requests.indexWhere((req) => req['_id'] == requestId);
              if (index != -1) {
                _requests[index]['status'] = 'approved';
                _requests[index]['approvalImage'] = approvalImageUrl;
                _requests[index]['approvedAt'] =
                    DateTime.now().toIso8601String();
              }
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('อนุมัติคำขอเรียบร้อย'),
                  backgroundColor: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      Navigator.pop(context); // ปิด loading ถ้ามี error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

// เพิ่มฟังก์ชันปฏิเสธคำขอ
  Future<void> _rejectRequestWithReason(String requestId) async {
    final reasonController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ระบุเหตุผลการปฏิเสธ',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'กรุณาระบุเหตุผลในการปฏิเสธคำขอนี้',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณาระบุเหตุผลการปฏิเสธ';
                      }
                      if (value.length < 5) {
                        return 'กรุณาระบุเหตุผลอย่างน้อย 5 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child:
                          Text('ยกเลิก', style: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey)),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          await _rejectRequest(
                              requestId, reasonController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('ตกลง'),
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

  Future<void> _rejectRequest(String requestId, String reason) async {
    try {
      final updateResponse = await http.put(
        Uri.parse('https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/api/cash-advance/request/$requestId'),
        headers: {"Content-Type": "application/json", "user-id": widget.userId},
        body: jsonEncode({
          'status': 'rejected',
          'rejectionReason': reason,
          'rejectedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (updateResponse.statusCode == 200) {
        // ✅ อัปเดตรายการเฉพาะตัวที่เปลี่ยนสถานะ
        setState(() {
          final index = _requests.indexWhere((req) => req['_id'] == requestId);
          if (index != -1) {
            _requests[index]['status'] = 'rejected';
            _requests[index]['rejectionReason'] = reason;
            _requests[index]['rejectedAt'] = DateTime.now().toIso8601String();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('ปฏิเสธคำขอเรียบร้อย'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

// ฟังก์ชันส่งการแจ้งเตือน
  void _sendNotificationToUser(String requestId, String status) {
    // ここで Firebase Cloud Messaging หรือ notification system อื่นๆ
    print('📢 Sending notification for request $requestId, status: $status');
  }

  Future<void> _fetchRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print(
          '🔍 Fetching cash advance requests for owner: ${widget.userId}, type: ${widget.type}');

      final response = await http.get(
        Uri.parse(
            'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/api/cash-advance/user-requests/${widget.targetUserId}'),
        headers: {
          "Content-Type": "application/json",
          "user-id": widget.targetUserId // ✅ ใช้ targetUserId แทน userId
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          
          // ✅ ใช้ข้อมูลทั้งหมดที่ได้จาก API และเรียงลำดับตามวันที่ (ใหม่สุดก่อน)
          final allRequests = (data['requests'] as List).toList()
            ..sort((a, b) {
              // เรียงลำดับตามวันที่ (ใหม่สุดก่อน)
              final dateA = DateTime.parse(a['date'] ?? '1970-01-01');
              final dateB = DateTime.parse(b['date'] ?? '1970-01-01');
              return dateB.compareTo(dateA);
            });

          print(
              '✅ Found ${allRequests.length} requests for user: ${widget.targetUserId}');
          

          setState(() {
            _requests = allRequests;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'ไม่สามารถดึงข้อมูลได้';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'เกิดข้อผิดพลาดในการดึงข้อมูล (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/api/cash-advance/request/$requestId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        await _fetchRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตสถานะเรียบร้อย'),
            backgroundColor: Colors.green,
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

  // ใน CashAdvanceRequestsScreen.dart - แก้ไขการแสดง error
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'คำขอเบิกเงินของ ${widget.targetUserName}',
          style: TextStyle(
                            fontFamily: 'NotoSansThai',
            color: Color(0xFF25634B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF25634B),
        elevation: 2,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF34D396)),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดประวัติการเงิน...',
                    style: TextStyle(
                            fontFamily: 'NotoSansThai',color: Color(0xFF25634B)),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'เกิดข้อผิดพลาด',
                        style: TextStyle(
                            fontFamily: 'NotoSansThai',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchRequests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'ไม่มีประวัติการเงิน',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'ยังไม่มีคำขอเบิกเงินจากผู้ใช้รายนี้',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            margin: EdgeInsets.symmetric(horizontal: 32),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.info, color: Colors.blue[600], size: 24),
                                SizedBox(height: 8),
                                Text(
                                  'ข้อมูลจาก API: ไม่พบคำขอเบิกเงิน',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'User ID: ${widget.targetUserId}',
                                  style: TextStyle(
                                    fontFamily: 'NotoSansThai',
                                    fontSize: 10,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchRequests,
                      color: Color(0xFF34D396),
                      child: Column(
                        children: [
                          // แสดงสรุปประวัติการเงิน
                          Container(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF34D396).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF34D396).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet, color: Color(0xFF34D396), size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ประวัติการเงิน',
                                        style: TextStyle(
                                          fontFamily: 'NotoSansThai',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF25634B),
                                        ),
                                      ),
                                      Text(
                                        '${_requests.length} รายการ',
                                        style: TextStyle(
                                          fontFamily: 'NotoSansThai',
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // แสดงรายการคำขอ
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _requests.length,
                              itemBuilder: (context, index) {
                                final request = _requests[index];
                                return _buildRequestCard(request, index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

// เพิ่มฟังก์ชันสร้างการ์ด
  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final date = DateTime.parse(request['date']);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final isPending = request['status'] == 'pending';
    final isApproved = request['status'] == 'approved';
    final isRejected = request['status'] == 'rejected';
    final isCompleted = isApproved || isRejected; // เพิ่มตัวแปร isCompleted
    

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ แสดงสถานะ (แบบใหม่เหมือน worker task)
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange[100]
                        : isApproved
                            ? Colors.green[100]
                            : Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPending
                        ? Icons.schedule
                        : isApproved
                            ? Icons.check_circle
                            : Icons.cancel,
                    color: isPending
                        ? Colors.orange
                        : isApproved
                            ? Colors.green
                            : Colors.red,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isPending
                        ? 'รอดำเนินการ'
                        : isCompleted
                            ? 'เสร็จสิ้น'
                            : 'ไม่ทราบสถานะ',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25634B),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange[50]
                        : isApproved
                            ? Colors.green[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPending
                          ? Colors.orange
                          : isApproved
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  child: Text(
                    isPending
                        ? 'รอดำเนินการ'
                        : isCompleted
                            ? 'เสร็จสิ้น'
                            : 'ไม่ทราบสถานะ',
                    style: TextStyle(
                      fontFamily: 'NotoSansThai',
                      color: isPending
                          ? Colors.orange[800]
                          : isCompleted
                              ? Colors.green[800]
                              : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // ✅ แสดงวัตถุประสงค์
            if (request['purpose'] != null &&
                request['purpose'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'วัตถุประสงค์:',
                    style: TextStyle(
                            fontFamily: 'NotoSansThai',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                        fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    request['purpose'].toString(),
                    style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),
                ],
              ),

            // ✅ แสดงข้อมูลพื้นฐาน
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Color(0xFF25634B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${request['name']}',
                    style: TextStyle(
                            fontFamily: 'NotoSansThai',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Color(0xFF25634B)),
                SizedBox(width: 8),
                Text('${request['phone']}', style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14)),
              ],
            ),
            SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Color(0xFF25634B)),
                SizedBox(width: 8),
                Text(
                  '${request['amount']} บาท',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25634B)),
                ),
              ],
            ),
            SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF25634B)),
                SizedBox(width: 8),
                Text('$formattedDate', style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14)),
              ],
            ),

            // ✅ แสดงเหตุผลการปฏิเสธ (ถ้ามี)
            if (isRejected && request['rejectionReason'] != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เหตุผลการปฏิเสธ:',
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',
                          fontWeight: FontWeight.bold, color: Colors.red[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      request['rejectionReason']!,
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',
                          color: Colors.red[700], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],

            // แสดงรูปภาพที่แนบมา (ถ้ามี)
            if (request['images'] != null && request['images'].isNotEmpty) ...[
              SizedBox(height: 12),
              Text('รูปภาพที่แนบมา:',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                      fontWeight: FontWeight.bold, color: Color(0xFF25634B))),
              SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: request['images'].length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => FullScreenImage(
                            imageUrl: request['images'][index],
                            onClose: () => Navigator.pop(context),
                          ),
                        ));
                      },
                      child: Container(
                        width: 100,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                          image: DecorationImage(
                            image: NetworkImage(
                                request['images'][index].toString().startsWith('http') 
                                    ? request['images'][index].toString()
                                    : 'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/uploads/${request['images'][index]}'),
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
            ],

            // แสดงปุ่มลบเฉพาะเมื่อต้องการลบจริงๆ (ไม่แสดงโดยอัตโนมัติ)
            // if (isApproved || isRejected) ...[
            //   SizedBox(height: 16),
            //   Center(
            //     child: ElevatedButton.icon(
            //       onPressed: () => _showDeleteConfirmation(request['_id']),
            //       icon: Icon(Icons.delete, size: 18),
            //       label: Text('ลบคำขอ'),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.red,
            //         foregroundColor: Colors.white,
            //         shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(8)),
            //       ),
            //     ),
            //   ),
            // ],

            // แสดงปุ่มสำหรับคำขอที่ pending เท่านั้น
            if (isPending) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _approveRequestWithImage(request['_id']),
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('อนุมัติ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _rejectRequestWithReason(request['_id']),
                    icon: Icon(Icons.cancel, size: 18),
                    label: Text('ปฏิเสธ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],

            // แสดงรูปภาพการอนุมัติ (ถ้ามี)
            if (isApproved && request['approvalImage'] != null) ...[
              SizedBox(height: 12),
              Text('รูปภาพการอนุมัติ:',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                      fontWeight: FontWeight.bold, color: Color(0xFF25634B))),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => FullScreenImage(
                      imageUrl: request['approvalImage']!,
                      onClose: () => Navigator.pop(context),
                    ),
                  ));
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
                        request['approvalImage'].toString().startsWith('http') 
                            ? request['approvalImage'].toString()
                            : 'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/uploads/${request['approvalImage']}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          final imageUrl = request['approvalImage'].toString().startsWith('http') 
                              ? request['approvalImage'].toString()
                              : 'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/uploads/${request['approvalImage']}';
                          print('❌ Cash advance approval image load error: $error');
                          print('❌ Failed URL: $imageUrl');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text('ไม่สามารถโหลดรูปภาพ',
                                    style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            final imageUrl = request['approvalImage'].toString().startsWith('http') 
                                ? request['approvalImage'].toString()
                                : 'https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/uploads/${request['approvalImage']}';
                            print('✅ Cash advance approval image loaded: $imageUrl');
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(),
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
            ],

            // แสดงข้อมูลเพิ่มเติมสำหรับคำขอที่เสร็จสิ้นแล้ว
            if (isCompleted) ...[
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              
              // แสดงสถานะการดำเนินการ
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isApproved ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isApproved ? Colors.green[200]! : Colors.red[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isApproved ? Icons.check_circle : Icons.cancel,
                          size: 20,
                          color: isApproved ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          isApproved ? 'คำขอได้รับการอนุมัติ' : 'คำขอถูกปฏิเสธ',
                          style: TextStyle(
                            fontFamily: 'NotoSansThai',
                            color: isApproved ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      isApproved
                          ? 'อนุมัติเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['approvedAt']))}'
                          : 'ปฏิเสธเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['rejectedAt'] ?? request['updatedAt']))}',
                      style: TextStyle(
                        fontFamily: 'NotoSansThai',
                        color: isApproved ? Colors.green[700] : Colors.red[700],
                        fontSize: 14,
                      ),
                    ),
                    
                    // แสดงข้อมูลเพิ่มเติมสำหรับคำขอที่อนุมัติ
                    if (isApproved) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                          SizedBox(width: 8),
                          Text(
                            'จำนวนเงินที่อนุมัติ: ${request['amount']} บาท',
                            style: TextStyle(
                              fontFamily: 'NotoSansThai',
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // แสดงปุ่มจัดการประวัติสำหรับคำขอที่เสร็จสิ้น
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showRequestHistory(request),
                    icon: Icon(Icons.history, size: 16),
                    label: Text('ประวัติ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(request['_id']),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('ลบ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              
              // ซ่อนประวัติการดำเนินการใน card เพราะมีปุ่มประวัติแล้ว
              // SizedBox(height: 12),
              // Container(
              //   padding: EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.blue[50],
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.blue[200]!),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Row(
              //         children: [
              //           Icon(Icons.history, color: Colors.blue[700], size: 20),
              //           SizedBox(width: 8),
              //           Text(
              //             'ประวัติการดำเนินการ',
              //             style: TextStyle(
              //               fontFamily: 'NotoSansThai',
              //               color: Colors.blue[700],
              //               fontWeight: FontWeight.bold,
              //               fontSize: 16,
              //             ),
              //           ),
              //         ],
              //       ),
              //       SizedBox(height: 8),
              //       _buildHistoryItem('วันที่ขอ', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['date']))),
              //       _buildHistoryItem('จำนวนเงิน', '${request['amount']} บาท'),
              //       _buildHistoryItem('วัตถุประสงค์', request['purpose'] ?? 'ไม่ระบุ'),
              //       if (isApproved) ...[
              //         _buildHistoryItem('สถานะ', 'อนุมัติแล้ว'),
              //         _buildHistoryItem('วันที่อนุมัติ', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['approvedAt']))),
              //       ] else if (isRejected) ...[
              //         _buildHistoryItem('สถานะ', 'ปฏิเสธแล้ว'),
              //         _buildHistoryItem('วันที่ปฏิเสธ', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['rejectedAt'] ?? request['updatedAt']))),
              //         if (request['rejectionReason'] != null)
              //           _buildHistoryItem('เหตุผลปฏิเสธ', request['rejectionReason']),
              //       ],
              //     ],
              //   ),
              // ),
            ],
          ],
        ),
      ),
    );
  }

  // แสดงประวัติคำขอเบิกเงิน
  void _showRequestHistory(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ประวัติคำขอเบิกเงิน',
                              style: TextStyle(
                                fontFamily: 'NotoSansThai',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${request['name']} - ${request['amount']} บาท',
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
                
                // แสดงข้อมูลคำขอ
                _buildHistoryDetailRow('ชื่อผู้ขอ', request['name'] ?? 'ไม่ระบุ'),
                _buildHistoryDetailRow('เบอร์โทร', request['phone'] ?? 'ไม่ระบุ'),
                _buildHistoryDetailRow('จำนวนเงิน', '${request['amount']} บาท'),
                _buildHistoryDetailRow('วัตถุประสงค์', request['purpose'] ?? 'ไม่ระบุ'),
                _buildHistoryDetailRow('วันที่ขอ', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['date']))),
                
                if (request['status'] == 'approved') ...[
                  _buildHistoryDetailRow('สถานะ', 'อนุมัติแล้ว'),
                  _buildHistoryDetailRow('วันที่อนุมัติ', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['approvedAt']))),
                ] else if (request['status'] == 'rejected') ...[
                  _buildHistoryDetailRow('สถานะ', 'ปฏิเสธแล้ว'),
                  _buildHistoryDetailRow('วันที่ปฏิเสธ', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(request['rejectedAt'] ?? request['updatedAt']))),
                  if (request['rejectionReason'] != null)
                    _buildHistoryDetailRow('เหตุผลปฏิเสธ', request['rejectionReason']),
                ] else ...[
                  _buildHistoryDetailRow('สถานะ', 'รอดำเนินการ'),
                ],
                
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.grey[800],
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('ปิด'),
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

  Widget _buildHistoryDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label: ",
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.bold,
                color: Color(0xFF25634B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label: ",
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'NotoSansThai',
                color: Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // แสดง dialog ยืนยันการลบ
  void _showDeleteConfirmation(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบคำขอนี้จากประวัติใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteRequest(requestId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

// ฟังก์ชันลบคำขอ
  Future<void> _deleteRequest(String requestId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://sugarcane-9bacy8d0d-suphachais-projects-d3438f04.vercel.app/api/cash-advance/request/$requestId'),
        headers: {'user-id': widget.userId},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          // อัปเดตรายการโดยไม่ต้องโหลดใหม่ทั้งหน้า
          setState(() {
            _requests.removeWhere((request) => request['_id'] == requestId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบคำขอเรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการลบคำขอ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
