import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
    // เลือกรูปภาพจาก gallery หรือ camera
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // อัพโหลดรูปภาพ
      var uri = Uri.parse('http://10.0.2.2:3000/api/upload');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          pickedFile.path,
          filename: 'approval_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        String approvalImageUrl = jsonResponse['imageUrl'];

        // อัปเดตสถานะคำขอพร้อมรูปภาพการอนุมัติ
        final updateResponse = await http.put(
          Uri.parse('http://10.0.2.2:3000/api/cash-advance/request/$requestId'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            'status': 'approved',
            'approvalImage': approvalImageUrl,
            'approvedAt': DateTime.now().toIso8601String(),
          }),
        );

        if (updateResponse.statusCode == 200) {
          await _fetchRequests();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อนุมัติคำขอเรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
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
            'http://10.0.2.2:3000/api/cash-advance/requests/${widget.userId}/${widget.type}'),
        headers: {
          "Content-Type": "application/json",
          "user-id": widget.userId // ✅ ส่ง header user-id ของเจ้าของ
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // ✅ กรองเฉพาะคำขอของ target user
          final filteredRequests = (data['requests'] as List).where((request) {
            final requestUserId =
                request['userId']?['_id'] ?? request['userId'];
            return requestUserId == widget.targetUserId;
          }).toList();

          print(
              '✅ Found ${filteredRequests.length} requests for user: ${widget.targetUserId}');

          setState(() {
            _requests = filteredRequests;
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
        Uri.parse('http://10.0.2.2:3000/api/cash-advance/request/$requestId'),
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
        title: Text('คำขอเบิกเงินของ ${widget.targetUserName}'),
        backgroundColor: Color(0xFF34D396),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'เกิดข้อผิดพลาด',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchRequests,
                        child: Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? Center(child: Text('ไม่มีคำขอเบิกเงิน'))
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return _buildRequestCard(request, index);
                      },
                    ),
    );
  }

// เพิ่มฟังก์ชันสร้างการ์ด
  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชื่อ: ${request['name']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('เบอร์โทร: ${request['phone']}'),
            SizedBox(height: 8),
            Text('จำนวนเงิน: ${request['amount']} บาท'),
            SizedBox(height: 8),
            Text(
                'วันที่: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(request['date']))}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _approveRequestWithImage(request['_id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('อนุมัติพร้อมแนบรูป'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      _updateRequestStatus(request['_id'], 'rejected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('ปฏิเสธ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
