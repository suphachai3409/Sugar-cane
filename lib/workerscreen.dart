import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'WorkerTasksScreen.dart';
import 'moneytransfer.dart';
import 'cash_advance_requests_screen.dart';

class WorkerScreen extends StatefulWidget {
  final String userId;

  const WorkerScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _WorkerScreenState createState() => _WorkerScreenState();
}

class _WorkerScreenState extends State<WorkerScreen> {
  List<Map<String, dynamic>> workers = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, int> cashAdvanceCounts = {};

  @override
  void initState() {
    super.initState();
    fetchWorkers();
    _fetchCashAdvanceCounts();
  }

  Future<void> _fetchCashAdvanceCounts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/api/cash-advance/requests/${widget.userId}/worker'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Map<String, int> counts = {};

        if (data['success'] == true && data['requests'] != null) {
          for (var request in data['requests']) {
            String workerId = request['userId'];
            counts[workerId] = (counts[workerId] ?? 0) + 1;
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

  // ฟังก์ชันดูงานของคนงาน
  void _viewWorkerTasks(String workerId, String workerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerTasksScreen(
          userId: workerId,
          isOwnerView: true,
          workerName: workerName,
        ),
      ),
    );
  }

// ฟังก์ชันดูคำขอเบิกเงินของคนงาน
  void _viewCashAdvanceRequests(String workerId, String workerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashAdvanceRequestsScreen(
          userId: widget.userId, // ✅ ต้องเป็น userId ของเจ้าของ
          type: 'worker',
          targetUserId: workerId, // ✅ userId ของคนงาน
          targetUserName: workerName,
        ),
      ),
    );
  }

// ฟังก์ชันรีเฟรชข้อมูล
  Future<void> _refreshData() async {
    await Future.wait([
      fetchWorkers(),
      _fetchCashAdvanceCounts(),
    ]);
  }

  Future<void> fetchWorkers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('🔄 กำลังดึงข้อมูลคนงานสำหรับ ownerId: ${widget.userId}');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/profile/workers/${widget.userId}'),
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
            workers = List<Map<String, dynamic>>.from(data['workers'] ?? []);
            isLoading = false;
          });
          print('✅ ดึงข้อมูลคนงานสำเร็จ: ${workers.length} คน');
          // เพิ่ม debug print เพื่อดูข้อมูล
          for (int i = 0; i < workers.length; i++) {
            print('👤 คนงานที่ $i: ${workers[i]}');
            print(
                '   - ID: ${workers[i]['userId']?['_id'] ?? workers[i]['_id']}');
            print(
                '   - ชื่อ: ${workers[i]['userId']?['name'] ?? workers[i]['name']}');
            print('   - อีเมล: ${workers[i]['userId']?['email']}');
            print('   - เบอร์โทร: ${workers[i]['userId']?['number']}');
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
          'คนงาน',
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
            onPressed: fetchWorkers,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
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
                        onPressed: fetchWorkers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF34D396),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : workers.isEmpty
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
                            'ยังไม่มีคนงาน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'สร้างรหัสความสัมพันธ์เพื่อเพิ่มคนงาน',
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
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: workers.length,
                        itemBuilder: (context, index) {
                          final worker = workers[index];
                          final workerId =
                              worker['userId']?['_id'] ?? worker['_id'];
                          final workerName = worker['userId']?['name'] ??
                              worker['name'] ??
                              'ไม่มีชื่อ';
                          final requestCount = cashAdvanceCounts[workerId] ?? 0;

                          return _buildWorkerCard(
                              worker, workerId, workerName, requestCount);
                        },
                      ),
                    ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker, String workerId,
      String workerName, int requestCount) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workerName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
                'เบอร์โทร: ${worker['userId']?['number'] ?? worker['phone'] ?? 'ไม่มีข้อมูล'}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewWorkerTasks(workerId, workerName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34D396),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('งานที่รับ'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Stack(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _viewCashAdvanceRequests(workerId, workerName),
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
}
