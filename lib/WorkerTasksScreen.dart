import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'sugarcanedata.dart';
import 'package:intl/intl.dart';

class WorkerTasksScreen extends StatefulWidget {
  final String userId;
  final bool isOwnerView; // เพิ่มพารามิเตอร์นี้
  final String? workerName; // เพิ่มพารามิเตอร์นี้
  const WorkerTasksScreen({
    Key? key,
    required this.userId,
    this.isOwnerView = false,
    this.workerName,
  }) : super(key: key);

  @override
  _WorkerTasksScreenState createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends State<WorkerTasksScreen> {
  List<dynamic> _tasks = [];
  List<dynamic> _recommendations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Future.wait([
        _fetchTasks(),
        _fetchRecommendations(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
      });
      print("Error fetching data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTasks() async {
    try {
      print('🔍 Fetching tasks for user ID: ${widget.userId}');

      final response = await http.get(
        Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/plots/tasks/${widget.userId}'),
        headers: {'user-id': widget.userId}, // ใช้ header นี้
      ).timeout(Duration(seconds: 10));

      print("Tasks API Response: ${response.statusCode}");
      print("Tasks API Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Number of tasks received: ${data.length}');

        setState(() {
          _tasks = data.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching tasks: $e");
      setState(() {
        _errorMessage = 'ไม่สามารถโหลดข้อมูลงาน: $e';
      });
    }
  }

  Future<void> _fetchRecommendations() async {
    try {
      print('🔍 Fetching recommendations for user: ${widget.userId}');

      final plotsResponse = await http.get(
        Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/plots/${widget.userId}'),
        headers: {'user-id': widget.userId},
      ).timeout(Duration(seconds: 10));

      print("Plots API Response: ${plotsResponse.statusCode}");

      if (plotsResponse.statusCode == 200) {
        final List<dynamic> userPlots = jsonDecode(plotsResponse.body);
        List<dynamic> allRecommendations = [];

        print('✅ Found ${userPlots.length} plots for user');

        for (var plot in userPlots) {
          final plotId = plot['_id']?.toString();
          if (plotId != null && plotId.isNotEmpty) {
            try {
              final recResponse = await http
                  .get(
                    Uri.parse(
                        'https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/plots/$plotId/recommendations'),
                  )
                  .timeout(Duration(seconds: 5));

              if (recResponse.statusCode == 200) {
                final List<dynamic> plotRecommendations =
                    jsonDecode(recResponse.body);
                for (var rec in plotRecommendations) {
                  allRecommendations.add({
                    ...rec,
                    'plotId': plotId,
                    'plotName': plot['plotName'] ?? 'ไม่ทราบแปลง',
                  });
                }
                print(
                    '✅ Found ${plotRecommendations.length} recommendations for plot $plotId');
              } else {
                print(
                    '⚠️ No recommendations for plot $plotId (${recResponse.statusCode})');
              }
            } catch (e) {
              print('⚠️ Error fetching recommendations for plot $plotId: $e');
            }
          }
        }

        setState(() {
          _recommendations = allRecommendations;
        });
        print('✅ Total recommendations received: ${_recommendations.length}');
      } else {
        print(
            '⚠️ Cannot fetch user plots, status: ${plotsResponse.statusCode}');
        setState(() {
          _recommendations = [];
        });
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
      setState(() {
        _recommendations = [];
      });
    }
  }

  List<dynamic> _getRecommendationsForTask(Map<String, dynamic> task) {
    if (task.isEmpty || _recommendations.isEmpty) return [];

    final String taskType = task['taskType']?.toString() ?? '';
    final String plotId = task['plotId']?.toString() ?? '';

    return _recommendations.where((rec) {
      final recTopic = rec['topic']?.toString() ?? '';
      final recPlotId = rec['plotId']?.toString() ?? '';

      final isTopicMatch = recTopic == taskType;
      final isPlotMatch = recPlotId == plotId;

      print(
          '🔍 Matching: "$taskType" vs "$recTopic", "$plotId" vs "$recPlotId" - $isTopicMatch & $isPlotMatch');
      return isTopicMatch && isPlotMatch;
    }).toList()
      ..sort((a, b) {
        final dateA = a['date']?.toString() ?? '';
        final dateB = b['date']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });
  }

  // เพิ่มเมธอด _viewTaskDetail สำหรับดูข้อมูลแบบ read-only
  void _viewTaskDetail(Map<String, dynamic> task) {
    final relatedRecommendations = _getRecommendationsForTask(task);
    final latestRec =
        relatedRecommendations.isNotEmpty ? relatedRecommendations.first : null;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icon(Icons.visibility, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'รายละเอียดงานที่เสร็จสมบูรณ์',
                        style: TextStyle(
                            fontFamily: 'NotoSansThai',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // ข้อมูลงาน
              _buildDetailRow('หัวข้อ', task['taskType'] ?? 'ไม่ทราบหัวข้อ'),
              _buildDetailRow('สถานะ', task['status'] ?? 'ไม่ทราบสถานะ'),
              _buildDetailRow(
                  'วันที่ครบกำหนด', task['dueDate'] ?? 'ไม่มีวันที่'),

              // ข้อมูลที่บันทึกไว้ (ถ้ามี)
              if (latestRec != null) ...[
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Text(
                  'ข้อมูลที่บันทึก:',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                    'วันที่บันทึก', latestRec['date'] ?? 'ไม่มีวันที่'),
                if (latestRec['message']?.isNotEmpty ?? false)
                  _buildDetailRow('ข้อความ', latestRec['message']!),
              ],

              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF34D396),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('ปิด'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<File> _convertToFileList(List<dynamic> imageData) {
    return imageData
        .where((item) => item != null)
        .map((item) {
          if (item is File) {
            return item;
          } else if (item is String) {
            return File(item);
          }
          return null;
        })
        .where((file) => file != null)
        .cast<File>()
        .toList();
  }

  void _navigateToTaskDetail(Map<String, dynamic> task,
      {Map<String, dynamic>? recommendation}) {
    if (task.isEmpty) return;

    final bool isCompleted = task['status']?.toString() == 'completed';
    final relatedRecommendations = _getRecommendationsForTask(task);
    final latestRec =
        relatedRecommendations.isNotEmpty ? relatedRecommendations.first : null;

    if (isCompleted && recommendation == null) {
      _viewTaskDetail(task);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalyzeSoilScreen(
          plotId: task['plotId'] ?? '',
          userId: widget.userId,
          topic: task['taskType'] ?? 'งาน',
          date: recommendation?['date'] ??
              latestRec?['date'] ??
              task['dueDate'] ??
              '',
          message: recommendation?['message'] ??
              latestRec?['message'] ??
              task['description'] ??
              '',
          images: _convertToFileList(recommendation?['images'] ??
              latestRec?['images'] ??
              task['images'] ??
              []),
          isEditing: recommendation != null,
          canAssignTask: false,
          isWorker: true,
          taskId: task['taskId'],
          onDataChanged: _fetchData,
        ),
      ),
    ).then((_) {
      _fetchData();
    });
  }

  void _showRecommendationHistory(Map<String, dynamic> task) {
    if (task.isEmpty) return;

    final relatedRecommendations = _getRecommendationsForTask(task);

    if (relatedRecommendations.isEmpty) {
      _fetchRecommendationsForTask(task).then((recommendations) {
        if (recommendations.isNotEmpty) {
          _showHistoryDialog(task, recommendations);
        } else {
          _showNoHistoryDialog(task);
        }
      });
    } else {
      _showHistoryDialog(task, relatedRecommendations);
    }
  }

  Future<List<dynamic>> _fetchRecommendationsForTask(
      Map<String, dynamic> task) async {
    try {
      final plotId = task['plotId']?.toString();
      if (plotId == null || plotId.isEmpty) return [];

      final response = await http
          .get(
            Uri.parse('https://sugarcane-eouu2t37j-suphachais-projects-d3438f04.vercel.app/api/plots/$plotId/recommendations'),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> recommendations = jsonDecode(response.body);
        final taskType = task['taskType']?.toString() ?? '';
        final filteredRecs = recommendations.where((rec) {
          return rec['topic']?.toString() == taskType;
        }).toList();

        return filteredRecs;
      }
    } catch (e) {
      print('Error fetching recommendations for task: $e');
    }
    return [];
  }

  void _showHistoryDialog(
      Map<String, dynamic> task, List<dynamic> recommendations) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                            'ประวัติการบันทึก',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            task['taskType'] ?? 'งาน',
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
              Expanded(
                child: recommendations.isEmpty
                    ? _buildNoHistoryContent()
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final rec = recommendations[index];
                          return _buildHistoryItem(rec, task, index);
                        },
                      ),
              ),
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
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToTaskDetail(task);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF34D396),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('บันทึกใหม่'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
      Map<String, dynamic> rec, Map<String, dynamic> task, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rec['date'] ?? 'ไม่มีวันที่',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.visibility, color: Colors.green, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        _viewRecommendationDetail(rec, task);
                      },
                      tooltip: 'ดูรายละเอียด',
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToTaskDetail(task, recommendation: rec);
                      },
                      tooltip: 'แก้ไข',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            if (rec['message']?.isNotEmpty ?? false)
              Text(
                rec['message']!,
                style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14),
              ),
            if (rec['images'] != null && (rec['images'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text(
                    'รูปภาพ: ${(rec['images'] as List).length} รูป',
                    style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 4),
            Text(
              'บันทึกเมื่อ: ${_formatDate(rec['createdAt'])}',
              style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _viewRecommendationDetail(
      Map<String, dynamic> rec, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
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
                    Icon(Icons.info, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'รายละเอียดการบันทึก',
                        style: TextStyle(
                            fontFamily: 'NotoSansThai',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildDetailRow('หัวข้อ', rec['topic'] ?? task['taskType']),
              _buildDetailRow('วันที่', rec['date'] ?? 'ไม่มีวันที่'),
              SizedBox(height: 16),
              if (rec['message']?.isNotEmpty ?? false) ...[
                Text(
                  'ข้อความ:',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(rec['message']!),
                ),
                SizedBox(height: 16),
              ],
              if (rec['images'] != null &&
                  (rec['images'] as List).isNotEmpty) ...[
                Text(
                  'รูปภาพ:',
                  style: TextStyle(
                            fontFamily: 'NotoSansThai',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (rec['images'] as List).length,
                    itemBuilder: (context, index) {
                      final imagePath =
                          (rec['images'] as List)[index]?.toString();
                      if (imagePath == null) return SizedBox();
                      return Container(
                        width: 150,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(imagePath)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
              ],
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF34D396),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: Text('ปิด'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
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
                color: Color(0xFF25634B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                            fontFamily: 'NotoSansThai',color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoHistoryDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ประวัติการบันทึก - ${task['taskType']}'),
        content: _buildNoHistoryContent(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToTaskDetail(task);
            },
            child: Text('บันทึกใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoHistoryContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีประวัติการบันทึก',
            style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'กด "บันทึกใหม่" เพื่อเริ่มบันทึก',
            style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'ไม่ทราบวันที่';
    if (date is String) return date;
    if (date is DateTime) return DateFormat('dd/MM/yyyy HH:mm').format(date);
    return date.toString();
  }

  Widget _buildTaskCard(int index) {
    if (index < 0 || index >= _tasks.length) return SizedBox();

    final task = _tasks[index];
    final Map<String, dynamic> taskMap =
        task is Map<String, dynamic> ? task : {};

    final String taskType = taskMap['taskType']?.toString() ?? 'ไม่มีชื่องาน';
    final String status = taskMap['status']?.toString() ?? 'ไม่ทราบสถานะ';
    final bool isCompleted = status == 'completed';

    final relatedRecommendations = _getRecommendationsForTask(taskMap);
    final hasHistory = relatedRecommendations.isNotEmpty;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToTaskDetail(taskMap),
        onLongPress:
            isCompleted ? () => _showRecommendationHistory(taskMap) : null,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isCompleted ? Colors.green[100] : Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work,
                      color: isCompleted ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      taskType,
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                  ),
                  if (isCompleted)
                    IconButton(
                      icon: Icon(Icons.history, color: Colors.blue, size: 22),
                      onPressed: () => _showRecommendationHistory(taskMap),
                      tooltip: 'ดูประวัติการบันทึก',
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',
                        color: isCompleted
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '📅 วันที่ครบกำหนด: ${taskMap['dueDate'] ?? 'ไม่มีวันที่'}',
                style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 4),
              if (isCompleted && hasHistory) ...[
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'มีการบันทึกข้อมูลแล้ว',
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRecommendationHistory(taskMap),
                    icon: Icon(Icons.history, size: 16),
                    label: Text('ดูประวัติการบันทึก'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
              ] else if (isCompleted) ...[
                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.isOwnerView && widget.workerName != null
            ? Text('งานของ ${widget.workerName!}')
            : Text('งานที่ได้รับมอบหมาย'),
        
        foregroundColor: Color(0xFF25634B),
        actions: [
          if (!widget.isOwnerView) // เซ็นการกระทำรีเฟรชเฉพาะโหมดคนงาน
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchData,
              tooltip: 'รีเฟรชข้อมูล',
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
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: Text('ลองใหม่'),
                      ),
                    ],
                  ),
                )
              : _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'ไม่มีงานที่ได้รับมอบหมาย',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'รอการมอบหมายงานจากผู้จัดการ',
                            style: TextStyle(
                            fontFamily: 'NotoSansThai',
                                fontSize: 14, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) {
                                return _buildTaskCard(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
