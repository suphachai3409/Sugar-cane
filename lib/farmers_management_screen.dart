// ใน farmers_management_screen.dart - เพิ่มฟังก์ชันดูคำขอเบิกเงิน
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'cash_advance_requests_screen.dart'; // import หน้า cash_advance_requests_screen

class FarmersManagementScreen extends StatefulWidget {
  final String userId;
  
  const FarmersManagementScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _FarmersManagementScreenState createState() => _FarmersManagementScreenState();
}

class _FarmersManagementScreenState extends State<FarmersManagementScreen> {
  List<dynamic> _farmers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, int> _cashAdvanceCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
    _fetchCashAdvanceCounts();
  }

  Future<void> _fetchCashAdvanceCounts() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/cash-advance/requests/${widget.userId}/farmer'),
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
          _cashAdvanceCounts = counts;
        });
      }
    } catch (e) {
      print('Error fetching cash advance counts: $e');
    }
  }

  Future<void> _fetchFarmers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/profile/farmers/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userId}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _farmers = List<Map<String, dynamic>>.from(data['farmers'] ?? []);
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
          _errorMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูล (${response.statusCode})';
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

  // ฟังก์ชันดูคำขอเบิกเงินของลูกไร่
  void _viewCashAdvanceRequests(String farmerId, String farmerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashAdvanceRequestsScreen(
          userId: widget.userId, // userId ของเจ้าของ
          type: 'farmer', // ประเภทเป็น farmer
          targetUserId: farmerId, // userId ของลูกไร่
          targetUserName: farmerName,
        ),
      ),
    );
  }

  Widget _buildFarmerCard(Map<String, dynamic> farmer, int index) {
    final farmerId = farmer['userId']?['_id'] ?? farmer['_id'];
    final farmerName = farmer['userId']?['name'] ?? farmer['name'] ?? 'ไม่มีชื่อ';
    final requestCount = _cashAdvanceCounts[farmerId] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farmerName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('เบอร์โทร: ${farmer['userId']?['number'] ?? farmer['phone'] ?? 'ไม่มีข้อมูล'}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ElevatedButton(
                        onPressed: () => _viewCashAdvanceRequests(farmerId, farmerName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF25634B),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('คำขอเบิกเงิน'),
                      ),
                      if (requestCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'จัดการลูกไร่',
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
            onPressed: () {
              _fetchFarmers();
              _fetchCashAdvanceCounts();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      SizedBox(height: 16),
                      Text(
                        'เกิดข้อผิดพลาด',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _fetchFarmers();
                          _fetchCashAdvanceCounts();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _farmers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'ยังไม่มีลูกไร่',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'สร้างรหัสความสัมพันธ์เพื่อเพิ่มลูกไร่',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _fetchFarmers();
                        await _fetchCashAdvanceCounts();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _farmers.length,
                        itemBuilder: (context, index) {
                          final farmer = _farmers[index];
                          final farmerId = farmer['userId']?['_id'] ?? farmer['_id'];
                          final farmerName = farmer['userId']?['name'] ?? farmer['name'] ?? 'ไม่มีชื่อ';
                          final requestCount = _cashAdvanceCounts[farmerId] ?? 0;

                          return _buildFarmerCard(farmer, index);
                        },
                      ),
                    ),
    );
  }
}