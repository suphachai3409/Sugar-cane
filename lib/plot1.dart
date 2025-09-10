import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'google_maps_search.dart';
import 'plot_map_fullscreen.dart';
import 'sugarcanedata.dart';
import 'profile.dart';
import 'menu1.dart';
import 'menu2.dart';
import 'menu3.dart';

class Plot1Screen extends StatefulWidget {
  final String userId;
  final bool isWorkerMode;
  final bool isViewMode;
  final String? farmerName;
  final String? ownerId; // เพิ่ม ownerId
  final TextEditingController _plotNameController = TextEditingController();

  // แก้ไข Constructor ให้ถูกต้อง
  Plot1Screen({
    required this.userId,
    this.isWorkerMode = false,
    this.isViewMode = false,
    this.farmerName,
    this.ownerId,
  });

  @override
  _Plot1ScreenState createState() => _Plot1ScreenState();
}

class _Plot1ScreenState extends State<Plot1Screen> {
  List<Map<String, dynamic>> plotList = [];
  bool isLoading = true;
  String? _ownerId;
  LatLng? locationLatLng;
  String? locationAddress;
  String selectedPlant = '';
  String selectedWater = '';
  String selectedSoil = '';
  String plotName = '';
  final TextEditingController _plotNameController = TextEditingController();
  List<LatLng> polygonPoints = [];

  @override
  void initState() {
    super.initState();

    print('🎯 Plot1Screen initialized:');
    print('   - userId: ${widget.userId}');
    print('   - isWorkerMode: ${widget.isWorkerMode}');
    print('   - isViewMode: ${widget.isViewMode}');

    if (widget.isWorkerMode) {
      print('👷 Worker mode - Fetching owner data...');
      _fetchOwnerData().then((_) {
        if (_ownerId != null) {
          print('✅ Owner found: $_ownerId, loading plots...');
          _loadPlotData();
        } else {
          print('❌ No owner found');
          setState(() => isLoading = false);
        }
      });
    } else if (widget.isViewMode) {
      // โหมดดูข้อมูลลูกไร่ - ใช้ userId ของลูกไร่โดยตรง
      print('👨‍🌾 View mode - Loading farmer plots: ${widget.userId}');
      _loadPlotData();
    } else {
      print('👨‍🌾 Normal mode - Loading own plots...');
      _loadPlotData();
    }
  }

// ฟังก์ชันดึงข้อมูลเจ้าของจากคนงาน
  Future<void> _fetchOwnerData() async {
    try {
      print('🔄 Fetching owner data for worker: ${widget.userId}');

      final response = await http.get(
        Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/plots/owner/${widget.userId}'),
        headers: {"Content-Type": "application/json"},
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}'); // ✅ เพิ่ม logging นี้

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['ownerId'] != null) {
          print('✅ Found owner: ${data['ownerId']}');
          setState(() {
            _ownerId = data['ownerId'];
          });
        } else {
          print('❌ No owner data found in response');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        // ✅ แสดง error message จาก server
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            print('❌ Server error: ${errorData['message']}');
          } catch (e) {
            print('❌ Server error: ${response.body}');
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching owner data: $e');
    }
  }

// แก้ไขฟังก์ชัน _loadPlotData
  Future<void> _loadPlotData() async {
    try {
      String targetUserId;

      // ใช้ ownerId ถ้ามี (โหมดคนงาน) ไม่ก็ใช้ userId (โหมดเจ้าของ)
      if (widget.isWorkerMode && widget.ownerId != null) {
        targetUserId = widget.ownerId!;
        print('👷 Worker mode - Using ownerId: $targetUserId');
      } else {
        targetUserId = widget.userId;
        print('👨‍🌾 Normal mode - Using userId: $targetUserId');
      }

      // ใช้ endpoint สำหรับดึงแปลงของ user
      final response = await http.get(
        Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/plots/$targetUserId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> plots = jsonDecode(response.body);
        setState(() {
          plotList = plots.cast<Map<String, dynamic>>();
          isLoading = false;
        });
        print('✅ Loaded ${plots.length} plots for user: $targetUserId');
      } else {
        print('❌ Error response: ${response.statusCode} - ${response.body}');
        setState(() {
          plotList = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading plot data: $e');
      setState(() {
        plotList = [];
        isLoading = false;
      });
    }
  }

  final String apiUrl = 'https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/pulluser';
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

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

  Future<void> _updatePlotData(String plotId) async {
    if (plotId.isEmpty) {
      _showErrorDialog(context, 'ไม่พบ ID แปลงปลูก');
      return;
    }

    final url = Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/plots/$plotId');

    final bodyData = {
      "plotName": plotName,
      "plantType": selectedPlant,
      "waterSource": selectedWater,
      "soilType": selectedSoil,
      "latitude": locationLatLng!.latitude,
      "longitude": locationLatLng!.longitude,
      "ownerId": widget.ownerId ?? widget.userId, // เพิ่ม ownerId
      if (polygonPoints.isNotEmpty)
        "polygonPoints": polygonPoints
            .map((p) => {"latitude": p.latitude, "longitude": p.longitude})
            .toList(),
    };

    print('🔄 ===== อัปเดตข้อมูลแปลงปลูก =====');
    print('🔄 Plot ID: $plotId');
    print('🔄 ชื่อแปลง: $plotName');
    print('🔄 ชนิดพืช: $selectedPlant');
    print('🔄 แหล่งน้ำ: $selectedWater');
    print('🔄 ชนิดดิน: $selectedSoil');
    print(
        '🔄 ตำแหน่ง: ${locationLatLng!.latitude}, ${locationLatLng!.longitude}');
    print('🔄 จำนวน polygon points: ${polygonPoints.length}');

    if (polygonPoints.isNotEmpty) {
      print('🔄 รายละเอียด polygon points:');
      for (int i = 0; i < polygonPoints.length; i++) {
        var p = polygonPoints[i];
        print('🔄   จุดที่ ${i + 1}: lat=${p.latitude}, lng=${p.longitude}');
      }
    }
    print('🔄 ===============================');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        print('✅ ===== อัปเดตข้อมูลแปลงปลูกสำเร็จ =====');
        print('✅ Response body: ${response.body}');
        print('✅ ======================================');

        await _loadPlotData(); // โหลดข้อมูลใหม่
        _showUpdateSuccessDialog(context); // แสดง dialog แจ้งผลสำเร็จ

        // เคลียร์ค่าฟอร์ม
        setState(() {
          plotName = '';
          selectedPlant = '';
          selectedWater = '';
          selectedSoil = '';
          locationLatLng = null;
          polygonPoints = [];
          _plotNameController.clear();
        });
      } else {
        print('❌ ===== เกิดข้อผิดพลาดในการอัปเดต =====');
        print('❌ Status code: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        print('❌ ======================================');
        _showErrorDialog(context, 'เกิดข้อผิดพลาดในการอัปเดตข้อมูล');
      }
    } catch (e) {
      print('❌ Exception ขณะอัปเดตข้อมูล: $e');
      _showErrorDialog(context, 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แปลงปลูก',
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
        // ✅ แสดงปุ่มเพิ่มแปลงเฉพาะเมื่อไม่ใช่โหมดคนงาน
        actions: !widget.isWorkerMode && plotList.isNotEmpty
            ? [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapSearchScreen(),
                        ),
                      );
                      print('DEBUG result: $result');
                      print('DEBUG latLng: \\${result?['latLng']}');
                      print('DEBUG address: \\${result?['address']}');
                      print(
                          'DEBUG drawingPoints: \\${result?['drawingPoints']}');
                      if (result != null && result['address'] != null) {
                        print('🎯 ===== รับข้อมูลจาก Google Maps Search =====');
                        print('🎯 result keys: ${result.keys.toList()}');

                        // ตรวจสอบว่ามี latLng หรือ centerPoint
                        LatLng? selectedLatLng;
                        if (result['latLng'] != null) {
                          selectedLatLng = result['latLng'];
                          print(
                              '🎯 ใช้ latLng: ${selectedLatLng?.latitude}, ${selectedLatLng?.longitude}');
                        } else if (result['centerPoint'] != null) {
                          selectedLatLng = result['centerPoint'];
                          print(
                              '🎯 ใช้ centerPoint: ${selectedLatLng?.latitude}, ${selectedLatLng?.longitude}');
                        } else if (result['lat'] != null &&
                            result['lng'] != null) {
                          final lat = result['lat'] is double
                              ? result['lat']
                              : (result['lat'] as num).toDouble();
                          final lng = result['lng'] is double
                              ? result['lng']
                              : (result['lng'] as num).toDouble();
                          selectedLatLng = LatLng(lat, lng);
                          print(
                              '🎯 ใช้ lat/lng: ${selectedLatLng.latitude}, ${selectedLatLng.longitude}');
                        }

                        if (selectedLatLng != null) {
                          final String selectedAddress = result['address'];
                          List<LatLng> drawingPoints = [];
                          if (result['drawingPoints'] != null) {
                            drawingPoints = List.from(result['drawingPoints'])
                                .map((p) =>
                                    LatLng(p['latitude'], p['longitude']))
                                .toList();
                            print(
                                '🎯 จำนวน drawing points: ${drawingPoints.length}');
                            for (int i = 0; i < drawingPoints.length; i++) {
                              print(
                                  '🎯   จุดที่ ${i + 1}: lat=${drawingPoints[i].latitude}, lng=${drawingPoints[i].longitude}');
                            }
                          } else {
                            print('🎯 ไม่มี drawing points');
                          }
                          print('🎯 =========================================');
                          setState(() {
                            plotName = '';
                            locationLatLng = selectedLatLng;
                            locationAddress = selectedAddress;
                            polygonPoints = drawingPoints;
                          });
                          PlotDialogs.showPlotNamePopup(
                            context: context,
                            plotNameController: _plotNameController,
                            onNext: (plotName) {
                              setState(() {
                                this.plotName = plotName;
                              });
                              print('🟢 ===== ตั้งชื่อแปลงแล้ว (หลัก) =====');
                              print('🟢 ชื่อแปลง: $plotName');
                              print(
                                  '🟢 ตำแหน่ง: ${locationLatLng?.latitude}, ${locationLatLng?.longitude}');
                              print(
                                  '🟢 จำนวน polygon points: ${polygonPoints.length}');
                              if (polygonPoints.isNotEmpty) {
                                print('🟢 รายละเอียด polygon points:');
                                for (int i = 0; i < polygonPoints.length; i++) {
                                  print(
                                      '🟢   จุดที่ ${i + 1}: lat=${polygonPoints[i].latitude}, lng=${polygonPoints[i].longitude}');
                                }
                              }
                              print('🟢 ===============================');
                              _showFirstPopup(context, plotName);
                            },
                          );
                        } else {
                          print('! ไม่พบตำแหน่งที่ถูกต้อง');
                        }
                      } else {
                        print('! ยกเลิกการเลือกตำแหน่ง หรือค่าที่ได้ไม่ครบ');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34D396),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('เพิ่มแปลง',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ]
            : null, // ✅ ซ่อนปุ่มเมื่อเป็นโหมดคนงาน
      ),
      body: isLoading
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
                    'กำลังโหลดข้อมูลแปลงปลูก...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _buildBody(width, height),
    );
  }

  Widget _buildBody(double width, double height) {
    // ถ้าไม่มีข้อมูล แสดงปุ่มกลาง
    if (plotList.isEmpty) {
      return _buildEmptyState(width, height);
    }
    // ถ้ามีข้อมูล แสดงรายการ
    else {
      return _buildPlotList(width, height);
    }
  }

  // หน้าจอเมื่อไม่มีข้อมูล (รูปที่ 2)
  Widget _buildEmptyState(double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // ส่วนเนื้อหาหลัก
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ในโหมดดูข้อมูล จะไม่แสดงปุ่มเพิ่มแปลง
                if (!widget.isViewMode && !widget.isWorkerMode)
                  GestureDetector(
                    onTap: () async {
                      print("📌 เริ่มไปหน้า MapSearchScreen");

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapSearchScreen(),
                        ),
                      );

                      if (result != null && result['address'] != null) {
                        print(
                            '🎯 ===== รับข้อมูลจาก Google Maps Search (Empty State) =====');
                        print('🎯 result keys: ${result.keys.toList()}');

                        // ตรวจสอบว่ามี latLng หรือ centerPoint หรือ lat/lng
                        LatLng? selectedLatLng;
                        if (result['latLng'] != null) {
                          selectedLatLng = result['latLng'];
                          print(
                              '🎯 ใช้ latLng: ${selectedLatLng?.latitude}, ${selectedLatLng?.longitude}');
                        } else if (result['centerPoint'] != null) {
                          selectedLatLng = result['centerPoint'];
                          print(
                              '🎯 ใช้ centerPoint: ${selectedLatLng?.latitude}, ${selectedLatLng?.longitude}');
                        } else if (result['lat'] != null &&
                            result['lng'] != null) {
                          selectedLatLng = LatLng(result['lat'], result['lng']);
                          print(
                              '🎯 ใช้ lat/lng: ${selectedLatLng.latitude}, ${selectedLatLng.longitude}');
                        }

                        if (selectedLatLng != null) {
                          final String selectedAddress = result['address'];
                          List<LatLng> drawingPoints = [];
                          if (result['drawingPoints'] != null) {
                            drawingPoints = List.from(result['drawingPoints'])
                                .map((p) =>
                                    LatLng(p['latitude'], p['longitude']))
                                .toList();
                            print(
                                '🎯 จำนวน drawing points: ${drawingPoints.length}');
                            for (int i = 0; i < drawingPoints.length; i++) {
                              print(
                                  '🎯   จุดที่ ${i + 1}: lat=${drawingPoints[i].latitude}, lng=${drawingPoints[i].longitude}');
                            }
                          } else {
                            print('🎯 ไม่มี drawing points');
                          }

                          print(
                              "📍 ได้ตำแหน่งจาก map: $selectedLatLng, $selectedAddress");
                          if (drawingPoints.isNotEmpty) {
                            print(
                                "📍 มี polygon points: ${drawingPoints.length} จุด");
                          }
                          print('🎯 =========================================');

                          // 👉 เปิด popup ตั้งชื่อแปลง
                          PlotDialogs.showPlotNamePopup(
                            context: context,
                            plotNameController: _plotNameController,
                            onNext: (name) {
                              print(
                                  "✅ onNext ของชื่อแปลงถูกเรียกแล้ว ด้วยค่า: $name");

                              if (name.trim().isEmpty) {
                                _showErrorDialog(context, 'กรุณากรอกชื่อแปลง');
                                return;
                              }

                              setState(() {
                                plotName = name;
                                locationLatLng = selectedLatLng;
                                locationAddress = selectedAddress;
                                polygonPoints = drawingPoints;
                              });

                              print(
                                  "🟢 ===== ตั้งชื่อแปลงแล้ว (Empty State) =====");
                              print("🟢 ชื่อแปลง: $name");
                              print(
                                  "🟢 ตำแหน่ง: ${selectedLatLng!.latitude}, ${selectedLatLng.longitude}");
                              print(
                                  "🟢 จำนวน polygon points: ${drawingPoints.length}");
                              if (drawingPoints.isNotEmpty) {
                                print("🟢 รายละเอียด polygon points:");
                                for (int i = 0; i < drawingPoints.length; i++) {
                                  print(
                                      "🟢   จุดที่ ${i + 1}: lat=${drawingPoints[i].latitude}, lng=${drawingPoints[i].longitude}");
                                }
                              }
                              print(
                                  "🟢 ======================================");

                              _showFirstPopup(context, name);
                            },
                          );
                        } else {
                          print("⚠️ ไม่พบตำแหน่งที่ถูกต้อง");
                        }
                      } else {
                        print("⚠️ ยกเลิกการเลือกตำแหน่ง หรือค่าที่ได้ไม่ครบ");
                      }
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
                          'กดเพื่อสร้างแปลง',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF25634B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${widget.farmerName ?? "ลูกไร่"} ยังไม่มีแปลงปลูก',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF25634B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // ในโหมดดูข้อมูลจะไม่แสดงปุ่มล่าง
          if (!widget.isViewMode) _buildBottomButtons(width, height),
        ],
      ),
    );
  }

  // หน้าจอเมื่อมีข้อมูล
  Widget _buildPlotList(double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // รายการแปลงปลูก
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: height * 0.1,
            child: Column(
              children: [
                if (widget.isViewMode && widget.farmerName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'แปลงปลูกของ ${widget.farmerName!}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25634B),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: plotList.length,
                    itemBuilder: (context, index) {
                      final plot = plotList[index];
                      return _buildPlotCard(plot, width, height);
                    },
                  ),
                ),
              ],
            ),
          ),
          // ในโหมดดูข้อมูลจะไม่แสดงปุ่มล่าง
          if (!widget.isViewMode) _buildBottomButtons(width, height),
        ],
      ),
    );
  }

  // Card แสดงข้อมูลแปลงปลูก - แก้ไขใหม่
  Widget _buildPlotCard(
      Map<String, dynamic> plot, double width, double height) {
    // ดึง lat/lng จาก plot (ต้องแน่ใจว่ามีข้อมูล)
    final double? lat = plot['latitude'] is double
        ? plot['latitude']
        : (plot['latitude'] is int
            ? (plot['latitude'] as int).toDouble()
            : null);
    final double? lng = plot['longitude'] is double
        ? plot['longitude']
        : (plot['longitude'] is int
            ? (plot['longitude'] as int).toDouble()
            : null);

    LatLng? plotPosition;
    if (lat != null && lng != null) {
      plotPosition = LatLng(lat, lng);
    }

    // ใน _buildPlotCard ให้แสดง Polygon ถ้ามี polygonPoints >= 3 จุด
    final List<LatLng> plotPolygon = plot['polygonPoints'] != null
        ? List.from(plot['polygonPoints'])
            .map((p) => LatLng(p['latitude'], p['longitude']))
            .toList()
        : [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => sugarcanedata(
              plotId: plot['_id'],
              userId: widget.userId,
              plotName: plot['plotName'] ?? 'ไม่มีชื่อ',
              plantType: plot['plantType'],
              waterSource: plot['waterSource'],
              soilType: plot['soilType'],
              plotPosition: plotPosition,
              polygonPoints: plotPolygon,
              isWorkerMode: widget.isWorkerMode,
              isViewMode: widget.isViewMode, // ส่งค่าโหมดดูข้อมูลไปด้วย
              ownerId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini Google Map + ปุ่ม overlay มุมล่างขวา (Row เดียว)
            plotPosition != null
                ? Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: plotPosition,
                              zoom: 14,
                            ),
                            markers: {
                              Marker(
                                markerId:
                                    MarkerId('plot_marker_${plot['_id']}'),
                                position: plotPosition,
                              ),
                            },
                            polygons: plotPolygon.length >= 3
                                ? {
                                    Polygon(
                                      polygonId: PolygonId(
                                          'plot_polygon_${plot['_id']}'),
                                      points: plotPolygon,
                                      fillColor:
                                          Color(0xFF34D396).withOpacity(0.4),
                                      strokeColor: Color(0xFF34D396),
                                      strokeWidth: 3,
                                    ),
                                  }
                                : {},
                            zoomControlsEnabled: false,
                            scrollGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            zoomGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled:
                                true, // ถ้าใช้ Android/iOS ที่รองรับ
                          ),
                        ),
                        // ปุ่ม overlay มุมล่างขวา
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Row(
                            children: [
                              // ปุ่มเปิดขยาย
                              IconButton(
                                icon:
                                    Icon(Icons.map, color: Colors.red, size: 5),
                                tooltip: 'ขยายแผนที่',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlotMapFullScreen(
                                        center: plotPosition!,
                                        polygonPoints: plotPolygon,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: width * 0.50,
                    height: width * 0.50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: Color(0xFF34D396),
                      size: width * 0.08,
                    ),
                  ),
            SizedBox(width: 12),

            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plot['plotName'] ?? 'ไม่มีชื่อ',
                          style: TextStyle(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF25624B),
                          ),
                        ),
                      ),
                      // ปุ่มแก้ไขและลบ - จะไม่แสดงในโหมดดูข้อมูล
                      if (!widget.isWorkerMode && !widget.isViewMode)
                        Row(
                          children: [
                            // ปุ่มแก้ไข
                            GestureDetector(
                              onTap: () {
                                // ตั้งค่าข้อมูลเดิมก่อนแก้ไข
                                setState(() {
                                  plotName = plot['plotName'] ?? '';
                                  selectedPlant = plot['plantType'] ?? '';
                                  selectedWater = plot['waterSource'] ?? '';
                                  selectedSoil = plot['soilType'] ?? '';
                                  _plotNameController.text = plotName;

                                  // ตั้งค่า location และ polygon points
                                  if (plot['latitude'] != null &&
                                      plot['longitude'] != null) {
                                    locationLatLng = LatLng(
                                      plot['latitude'] is double
                                          ? plot['latitude']
                                          : (plot['latitude'] as int)
                                              .toDouble(),
                                      plot['longitude'] is double
                                          ? plot['longitude']
                                          : (plot['longitude'] as int)
                                              .toDouble(),
                                    );
                                  }

                                  if (plot['polygonPoints'] != null) {
                                    polygonPoints =
                                        List.from(plot['polygonPoints'])
                                            .map((p) => LatLng(
                                                p['latitude'], p['longitude']))
                                            .toList();
                                  }
                                });
                                _showEditPlotNamePopup(context, plot);
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                  size: width * 0.045,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // ปุ่มลบ
                            GestureDetector(
                              onTap: () {
                                _showDeleteConfirmDialog(context, plot);
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: width * 0.045,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${plot['plantType']} • ${plot['soilType']}',
                    style: TextStyle(
                      fontSize: width * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 4),
                      Text(
                        plot['waterSource'] ?? '',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        plotPolygon.length >= 3 ? Icons.map : Icons.location_on,
                        size: 16,
                        color: plotPolygon.length >= 3
                            ? Color(0xFF34D396)
                            : Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        plotPolygon.length >= 3
                            ? 'มีขอบเขตพื้นที่'
                            : 'จุดเดียว',
                        style: TextStyle(
                          fontSize: width * 0.03,
                          color: plotPolygon.length >= 3
                              ? Color(0xFF34D396)
                              : Colors.grey[500],
                          fontWeight: plotPolygon.length >= 3
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// เพิ่มฟังก์ชันลบแปลงปลูก
  Future<void> _deletePlotData(String plotId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/plots/$plotId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        print('✅ ลบแปลงปลูกสำเร็จ');
        // รีเฟรชข้อมูลใหม่
        await _loadPlotData();
        _showDeleteSuccessDialog(context);
      } else {
        print('❌ เกิดข้อผิดพลาดในการลบ: ${response.body}');
        _showErrorDialog(context, 'เกิดข้อผิดพลาดในการลบข้อมูล');
      }
    } catch (e) {
      print('❌ Error deleting plot data: $e');
      _showErrorDialog(context, 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    }
  }

// Dialog ยืนยันการลบ
  void _showDeleteConfirmDialog(
      BuildContext context, Map<String, dynamic> plot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: width * 0.1,
                height: width * 0.1,
                decoration: ShapeDecoration(
                  color: Colors.red,
                  shape: CircleBorder(),
                ),
                child: Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: width * 0.06,
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                'ยืนยันการลบ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'คุณต้องการลบแปลงปลูก "${plot['plotName']}" หรือไม่?\n\nการลบแล้วจะไม่สามารถกู้คืนได้',
            style: TextStyle(fontSize: width * 0.04),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'ลบ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePlotData(plot['_id']);
              },
            ),
          ],
        );
      },
    );
  }

// Dialog แสดงผลสำเร็จสำหรับการลบ
  void _showDeleteSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: width * 0.1,
                height: width * 0.1,
                decoration: ShapeDecoration(
                  color: Colors.green,
                  shape: CircleBorder(),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: width * 0.06,
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                'ลบสำเร็จ',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'แปลงปลูกถูกลบเรียบร้อยแล้ว',
            style: TextStyle(fontSize: width * 0.04),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ปิด',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ปุ่มล่างสุด - ✅ แก้ไข layout ให้ใช้ Positioned ควบคุมตำแหน่งเอง
  Widget _buildBottomButtons(double width, double height) {
    if (widget.isViewMode) {
      return SizedBox.shrink(); // ไม่แสดงอะไรในโหมดดูข้อมูล
    }

    return Stack(
      children: [
        // Container ปุ่ม
        Positioned(
          bottom: height * 0, // 2% จากด้านล่าง
          left: width * 0.03, // 3% จากด้านซ้าย
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
        // ปุ่มซ้าย
        Positioned(
          bottom: height * 0.01, // 3% จากด้านล่าง
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
                padding:
                    EdgeInsets.all(6), // เพิ่มระยะห่างจากขอบ (ลองปรับค่านี้ได้)
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
                padding:
                    EdgeInsets.all(6), // เพิ่มระยะห่างจากขอบ (ลองปรับค่านี้ได้)
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(38),
                  child: _isLoading
                      ? Container(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }

  // บันทึกข้อมูลและ refresh หน้าจอ
  void _savePlotData() async {
    if (locationLatLng == null) {
      print('❌ กรุณาเลือกตำแหน่งบนแผนที่ก่อนบันทึก');
      _showErrorDialog(context, 'กรุณาเลือกตำแหน่งบนแผนที่ก่อนบันทึก');
      return;
    }

    print('🟢 ===== ข้อมูลที่จะบันทึก =====');
    print(
        '🟢 ตำแหน่งหลัก: ${locationLatLng!.latitude}, ${locationLatLng!.longitude}');
    print('🟢 ชื่อแปลง: $plotName');
    print('🟢 ชนิดพืช: $selectedPlant');
    print('🟢 แหล่งน้ำ: $selectedWater');
    print('🟢 ชนิดดิน: $selectedSoil');
    print('🟢 จำนวน polygon points: ${polygonPoints.length}');

    if (polygonPoints.isNotEmpty) {
      print('🟢 รายละเอียด polygon points:');
      for (int i = 0; i < polygonPoints.length; i++) {
        var p = polygonPoints[i];
        print('   จุดที่ ${i + 1}: lat=${p.latitude}, lng=${p.longitude}');
      }
    } else {
      print('🟢 ไม่มี polygon points (เลือกจุดเดียว)');
    }
    print('🟢 ===============================');
    print("📤 userId sent: ${widget.userId}");
    print("📤 ===== ส่งข้อมูลไปยัง API ===== ");
    print("📤   - userId: ${widget.userId}");
    print("📤   - plotName: $plotName");
    print("📤   - plantType: $selectedPlant");
    print("📤   - waterSource: $selectedWater");
    print("📤   - soilType: $selectedSoil");
    print("📤   - latitude: ${locationLatLng!.latitude}");
    print("📤   - longitude: ${locationLatLng!.longitude}");
    print("📤   - polygonPoints: ${polygonPoints.length} จุด");

    if (polygonPoints.isNotEmpty) {
      print("📤   - รายละเอียด polygon ที่ส่ง:");
      for (int i = 0; i < polygonPoints.length; i++) {
        var p = polygonPoints[i];
        print(
            "📤     จุดที่ ${i + 1}: {\"latitude\": ${p.latitude}, \"longitude\": ${p.longitude}}");
      }
    }
    print("📤 =============================== ");

    final response = await http.post(
      Uri.parse('https://sugarcane-czzs8k3ah-suphachais-projects-d3438f04.vercel.app/api/plots'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": widget.userId,
        "ownerId": widget.ownerId ??
            widget.userId, // ใช้ ownerId ถ้ามี ถ้าไม่มีใช้ userId
        "plotName": plotName,
        "plantType": selectedPlant,
        "waterSource": selectedWater,
        "soilType": selectedSoil,
        "latitude": locationLatLng!.latitude,
        "longitude": locationLatLng!.longitude,
        if (polygonPoints.isNotEmpty)
          "polygonPoints": polygonPoints
              .map((p) => {"latitude": p.latitude, "longitude": p.longitude})
              .toList(),
      }),
    );

    if (response.statusCode == 200) {
      print('✅ ===== บันทึกข้อมูลแปลงปลูกสำเร็จ =====');
      print(
          '✅ ตำแหน่งที่บันทึก: lat=${locationLatLng?.latitude}, lng=${locationLatLng?.longitude}');
      print('✅ จำนวน polygon points ที่บันทึก: ${polygonPoints.length}');
      print('✅ Response body: ${response.body}');
      print('✅ ======================================');

      await _loadPlotData();
      _showSuccessDialog(context);

      setState(() {
        plotName = '';
        selectedPlant = '';
        selectedWater = '';
        selectedSoil = '';
        locationLatLng = null;
        polygonPoints = [];
        _plotNameController.clear();
      });
    } else {
      print('❌ ===== เกิดข้อผิดพลาดในการบันทึก =====');
      print('❌ Status code: ${response.statusCode}');
      print('❌ Response body: ${response.body}');
      print('❌ ข้อมูลที่พยายามส่ง:');
      print('❌   - plotName: $plotName');
      print('❌   - polygonPoints: ${polygonPoints.length} จุด');
      print('❌ ======================================');
    }
  }

  // Popup เลือกพืชไร่
  void _showFirstPopup(BuildContext context, String plotName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Container(
                width: width * 0.9,
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x7F646464),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.015),
                    Text(
                      'พืชไร่ชนิดที่ปลูก',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25624B),
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg',
                                  'plant', setDialogState),
                              _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg',
                                  'plant', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg',
                                  'plant', setDialogState),
                              _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg',
                                  'plant', setDialogState),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // ปิด popup ก่อน
                              PlotDialogs.showPlotNamePopup(
                                context: context,
                                plotNameController: _plotNameController,
                                onNext: (plotName) {
                                  // ทำสิ่งที่คุณต้องการหลังกรอกชื่อแปลงแล้ว
                                  print("ชื่อแปลง: $plotName");
                                },
                              );
                            },
                            child: Text("ย้อนกลับ"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSecondPopup(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF34D396),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ถัดไป'),
                          ),
                        ],
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

  // Popup เลือกแหล่งน้ำ
  void _showSecondPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Container(
                width: width * 0.9,
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x7F646464),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.015),
                    Text(
                      'แหล่งน้ำที่ใช้ปลูก',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25624B),
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ขุดสระ', 'assets/ขุดสระ.png',
                                  'water', setDialogState),
                              _buildPopupItem('น้ำบาดาล', 'assets/น้ำบาดาล.png',
                                  'water', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem(
                                  'แหล่งน้ำธรรมชาติ',
                                  'assets/ธรรมชาติ.png',
                                  'water',
                                  setDialogState),
                              _buildPopupItem(
                                  'น้ำชลประธาน',
                                  'assets/น้ำชลประทาน.png',
                                  'water',
                                  setDialogState),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showFirstPopup(context, plotName);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ย้อนกลับ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showThreePopup(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF34D396),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ถัดไป'),
                          ),
                        ],
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

  // Popup เลือกดิน
  void _showThreePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Container(
                width: width * 0.9,
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x7F646464),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.015),
                    Text(
                      'ดินที่ใช้ปลูก',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25624B),
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ดินทราย', 'assets/ดินทราย.png',
                                  'soil', setDialogState),
                              _buildPopupItem('ดินร่วน', 'assets/ดินร่วน.png',
                                  'soil', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem(
                                  'ดินเหนียว',
                                  'assets/ดินเหนียว.png',
                                  'soil',
                                  setDialogState),
                              SizedBox(width: width * 0.20),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSecondPopup(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ย้อนกลับ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _savePlotData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF34D396),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('บันทึกข้อมูล'),
                          ),
                        ],
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

  // Dialog แสดงผลสำเร็จ
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: width * 0.1,
                height: width * 0.1,
                decoration: ShapeDecoration(
                  color: Color(0xFF34D396),
                  shape: CircleBorder(),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: width * 0.06,
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                'บันทึกสำเร็จ',
                style: TextStyle(
                  color: Color(0xFF25624B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'แปลงปลูก "$plotName" ถูกบันทึกเรียบร้อยแล้ว',
            style: TextStyle(fontSize: width * 0.04),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ปิด',
                style: TextStyle(
                  color: Color(0xFF34D396),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ เพิ่ม Popup สำหรับแก้ไขชื่อแปลงปลูก
  void _showEditPlotNamePopup(BuildContext context, Map<String, dynamic> plot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: width * 0.9,
              height: height * 0.5,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(45),
                ),
                shadows: [
                  BoxShadow(
                    color: Color(0x7F646464),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: height * 0.015),
                  Text(
                    'แก้ไขชื่อแปลงปลูก',
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: height * 0.03),
                            // ไอคอน
                            Container(
                              width: width * 0.15,
                              height: width * 0.15,
                              decoration: ShapeDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: CircleBorder(),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.orange,
                                size: width * 0.08,
                              ),
                            ),
                            SizedBox(height: height * 0.02),
                            Text(
                              'แก้ไขชื่อแปลงปลูกของคุณ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: width * 0.035,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: height * 0.025),
                            // TextField
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _plotNameController,
                                decoration: InputDecoration(
                                  hintText: 'เช่น ไร่อ้อย',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: width * 0.035,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: width * 0.04,
                                    vertical: height * 0.015,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                    size: width * 0.05,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(height: height * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * 0.015),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // เปิดหน้า MapSearchScreen เพื่อเลือกตำแหน่งใหม่
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapSearchScreen(),
                              ),
                            );
                            if (result != null && result['address'] != null) {
                              print(
                                  '🎯 ===== รับข้อมูลจาก Google Maps Search (แก้ไขตำแหน่ง) =====');
                              print('🎯 result keys: ${result.keys.toList()}');

                              // ตรวจสอบว่ามี latLng หรือ centerPoint หรือ lat/lng
                              LatLng? newLatLng;
                              if (result['latLng'] != null) {
                                newLatLng = result['latLng'];
                                print(
                                    '🎯 ใช้ latLng: ${newLatLng?.latitude}, ${newLatLng?.longitude}');
                              } else if (result['centerPoint'] != null) {
                                newLatLng = result['centerPoint'];
                                print(
                                    '🎯 ใช้ centerPoint: ${newLatLng?.latitude}, ${newLatLng?.longitude}');
                              } else if (result['lat'] != null &&
                                  result['lng'] != null) {
                                newLatLng =
                                    LatLng(result['lat'], result['lng']);
                                print(
                                    '🎯 ใช้ lat/lng: ${newLatLng.latitude}, ${newLatLng.longitude}');
                              }

                              if (newLatLng != null) {
                                List<LatLng> newPolygonPoints = [];
                                if (result['drawingPoints'] != null) {
                                  newPolygonPoints = List.from(
                                          result['drawingPoints'])
                                      .map((p) =>
                                          LatLng(p['latitude'], p['longitude']))
                                      .toList();
                                  print(
                                      '🎯 จำนวน drawing points: ${newPolygonPoints.length}');
                                  for (int i = 0;
                                      i < newPolygonPoints.length;
                                      i++) {
                                    print(
                                        '🎯   จุดที่ ${i + 1}: lat=${newPolygonPoints[i].latitude}, lng=${newPolygonPoints[i].longitude}');
                                  }
                                } else {
                                  print('🎯 ไม่มี drawing points');
                                }
                                print(
                                    '🎯 =========================================');

                                setState(() {
                                  locationLatLng = newLatLng;
                                  locationAddress = result['address'];
                                  polygonPoints = newPolygonPoints;
                                });

                                String message = newPolygonPoints.length >= 3
                                    ? 'เปลี่ยนตำแหน่งและขอบเขตแปลงเรียบร้อย'
                                    : 'เปลี่ยนตำแหน่งแปลงเรียบร้อย';

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('แก้ไขตำแหน่งแปลง'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('ยกเลิก'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_plotNameController.text.trim().isNotEmpty) {
                              setState(() {
                                plotName = _plotNameController.text.trim();
                              });
                              Navigator.pop(context);
                              _showEditFirstPopup(context, plot);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'กรุณาใส่ชื่อแปลงปลูก',
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('ถัดไป'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ เพิ่ม Popup แก้ไขเลือกพืชไร่
  void _showEditFirstPopup(BuildContext context, Map<String, dynamic> plot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Container(
                width: width * 0.9,
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x7F646464),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.015),
                    Text(
                      'แก้ไขพืชไร่ชนิดที่ปลูก',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg',
                                  'plant', setDialogState),
                              _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg',
                                  'plant', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg',
                                  'plant', setDialogState),
                              _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg',
                                  'plant', setDialogState),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditPlotNamePopup(context, plot);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ย้อนกลับ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditSecondPopup(context, plot);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ถัดไป'),
                          ),
                        ],
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

  // ✅ เพิ่ม Popup แก้ไขเลือกแหล่งน้ำ
  void _showEditSecondPopup(BuildContext context, Map<String, dynamic> plot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Container(
                width: width * 0.9,
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x7F646464),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.015),
                    Text(
                      'แก้ไขแหล่งน้ำที่ใช้ปลูก',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ขุดสระ', 'assets/ขุดสระ.png',
                                  'water', setDialogState),
                              _buildPopupItem('น้ำบาดาล', 'assets/น้ำบาดาล.png',
                                  'water', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem(
                                  'แหล่งน้ำธรรมชาติ',
                                  'assets/ธรรมชาติ.png',
                                  'water',
                                  setDialogState),
                              _buildPopupItem(
                                  'น้ำชลประธาน',
                                  'assets/น้ำชลประทาน.png',
                                  'water',
                                  setDialogState),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditFirstPopup(context, plot);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ย้อนกลับ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditThirdPopup(context, plot);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ถัดไป'),
                          ),
                        ],
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

  // ✅ เพิ่ม Popup แก้ไขเลือกดิน
  void _showEditThirdPopup(BuildContext context, Map<String, dynamic> plot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Center(
              child: Container(
                width: width * 0.9,
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(45),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x7F646464),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.015),
                    Text(
                      'แก้ไขดินที่ใช้ปลูก',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ดินทราย', 'assets/ดินทราย.png',
                                  'soil', setDialogState),
                              _buildPopupItem('ดินร่วน', 'assets/ดินร่วน.png',
                                  'soil', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem(
                                  'ดินเหนียว',
                                  'assets/ดินเหนียว.png',
                                  'soil',
                                  setDialogState),
                              SizedBox(width: width * 0.20),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.015),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditSecondPopup(context, plot);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('ย้อนกลับ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updatePlotData(plot['_id']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('อัพเดทข้อมูล'),
                          ),
                        ],
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

  void _showUpdateSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: width * 0.1,
                height: width * 0.1,
                decoration: ShapeDecoration(
                  color: Colors.orange,
                  shape: CircleBorder(),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: width * 0.06,
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                'อัพเดทสำเร็จ',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'แปลงปลูก "$plotName" ถูกอัพเดทเรียบร้อยแล้ว',
            style: TextStyle(fontSize: width * 0.04),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ปิด',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: width * 0.1,
                height: width * 0.1,
                decoration: ShapeDecoration(
                  color: Colors.red,
                  shape: CircleBorder(),
                ),
                child: Icon(
                  Icons.error,
                  color: Colors.white,
                  size: width * 0.06,
                ),
              ),
              SizedBox(width: width * 0.03),
              Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: width * 0.04),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ปิด',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Widget สำหรับสร้างตัวเลือกใน popup
  Widget _buildPopupItem(
      String label, String imagePath, String type, StateSetter setDialogState) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    bool isSelected = false;
    if (type == 'plant') isSelected = (selectedPlant == label);
    if (type == 'water') isSelected = (selectedWater == label);
    if (type == 'soil') isSelected = (selectedSoil == label);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (type == 'plant') selectedPlant = label;
          if (type == 'water') selectedWater = label;
          if (type == 'soil') selectedSoil = label;
        });
        setDialogState(() {});
      },
      child: Column(
        children: [
          Container(
            width: width * 0.20,
            height: height * 0.10,
            decoration: ShapeDecoration(
              color: isSelected ? const Color(0xFF34D396) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
            child: Padding(
              padding: EdgeInsets.all(width * 0.015),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            label,
            style: TextStyle(
              fontSize: width * 0.035,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class PlotDialogs {
  static void showPlotNamePopup({
    required BuildContext context,
    required TextEditingController plotNameController,
    required Function(String plotName) onNext,
    Function(String plotName)?
        updatePlotData, // ✅ เปลี่ยนชื่อ parameter ให้ไม่มี underscore
  }) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: width * 0.9,
              height: height * 0.5,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(45),
                ),
                shadows: [
                  BoxShadow(
                    color: Color(0x7F646464),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: height * 0.015),
                  Text(
                    'ตั้งชื่อแปลงปลูก',
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25624B),
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                        child: Column(
                          children: [
                            SizedBox(height: height * 0.03),
                            Container(
                              width: width * 0.15,
                              height: width * 0.15,
                              decoration: ShapeDecoration(
                                color: Color(0xFF34D396).withOpacity(0.1),
                                shape: CircleBorder(),
                              ),
                              child: Icon(
                                Icons.agriculture,
                                color: Color(0xFF34D396),
                                size: width * 0.08,
                              ),
                            ),
                            SizedBox(height: height * 0.02),
                            Text(
                              'กรุณาใส่ชื่อแปลงปลูกของคุณ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: width * 0.035,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: height * 0.025),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: plotNameController,
                                decoration: InputDecoration(
                                  hintText: 'เช่น แปลงข้าวโพดหลังบ้าน',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: width * 0.035,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: width * 0.04,
                                    vertical: height * 0.015,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.edit,
                                    color: Color(0xFF34D396),
                                    size: width * 0.05,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * 0.015),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('ยกเลิก'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final name = plotNameController.text.trim();
                            if (name.isNotEmpty) {
                              Navigator.pop(context);
                              onNext(name); // ไป popup ถัดไป
                              updatePlotData?.call(name); // บันทึกลง MongoDB
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'กรุณาใส่ชื่อแปลงปลูก',
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF34D396),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('ถัดไป'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
