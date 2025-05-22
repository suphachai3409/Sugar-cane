import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Plot1Screen extends StatefulWidget {
  final String userId;
  Plot1Screen({required this.userId});

  @override
  _Plot1ScreenState createState() => _Plot1ScreenState();
}

class _Plot1ScreenState extends State<Plot1Screen> {
  List<Map<String, dynamic>> plotList = [];
  bool isLoading = true;

  String selectedPlant = '';
  String selectedWater = '';
  String selectedSoil = '';
  String plotName = '';
  TextEditingController plotNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlotData();
  }

  // ดึงข้อมูลแปลงปลูกจาก database
  Future<void> _loadPlotData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/plots/${widget.userId}'), // ✅ แก้ไข URL ให้ตรงกับ backend
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> plots = jsonDecode(response.body); // ✅ backend ส่งกลับเป็น array โดยตรง
        setState(() {
          plotList = plots.cast<Map<String, dynamic>>();
          isLoading = false;
        });
        print('✅ Loaded ${plots.length} plots'); // ✅ debug
      } else {
        print('❌ Error response: ${response.statusCode} - ${response.body}'); // ✅ debug
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


  Future<void> _updatePlotData(String plotId) async {
    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/plots/$plotId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "plotName": plotName,
          "plantType": selectedPlant,
          "waterSource": selectedWater,
          "soilType": selectedSoil,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ อัพเดทข้อมูลแปลงปลูกสำเร็จ');
        // รีเฟรชข้อมูลใหม่
        await _loadPlotData();
        _showUpdateSuccessDialog(context);

        // Clear form
        setState(() {
          plotName = '';
          selectedPlant = '';
          selectedWater = '';
          selectedSoil = '';
          plotNameController.clear();
        });
      } else {
        print('❌ เกิดข้อผิดพลาดในการอัพเดท: ${response.body}');
        _showErrorDialog(context, 'เกิดข้อผิดพลาดในการอัพเดทข้อมูล');
      }
    } catch (e) {
      print('❌ Error updating plot data: $e');
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
        title: Text('แปลงปลูก'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // แสดงปุ่มเพิ่มแปลงด้านบนเมื่อมีข้อมูลแล้ว
        actions: plotList.isNotEmpty ? [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () {
                _showPlotNamePopup(context);
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
                  Text('เพิ่มแปลง', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ] : null,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
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
          // ปุ่มกลาง
          Positioned(
            top: height * 0.35,
            left: width * 0.35,
            child: GestureDetector(
              onTap: () {
                _showPlotNamePopup(context);
              },
              child: Column(
                children: [
                  Container(
                    width: width * 0.2,
                    height: height * 0.1,
                    decoration: ShapeDecoration(
                      color: Color(0xFF34D396),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(38),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'กดเพื่อสร้างแปลง',
                    style: TextStyle(
                      fontSize: width * 0.035,
                      color: Color(0xFF25624B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ปุ่มล่างสุด
          _buildBottomButtons(width, height),
        ],
      ),
    );
  }

  // หน้าจอเมื่อมีข้อมูล (รูปที่ 1)
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
            child: ListView.builder(
              itemCount: plotList.length,
              itemBuilder: (context, index) {
                final plot = plotList[index];
                return _buildPlotCard(plot, width, height);
              },
            ),
          ),
          // ปุ่มล่างสุด
          _buildBottomButtons(width, height),
        ],
      ),
    );
  }


  // Card แสดงข้อมูลแปลงปลูก - แก้ไขใหม่
  Widget _buildPlotCard(Map<String, dynamic> plot, double width, double height) {
    return Container(
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
          // รูปภาพ (placeholder)
          Container(
            width: width * 0.2,
            height: width * 0.2,
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
          // ข้อมูลแปลง
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
                    // ปุ่มแก้ไขและลบ
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
                              plotNameController.text = plotName;
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
              ],
            ),
          ),
        ],
      ),
    );
  }

// เพิ่มฟังก์ชันลบแปลงปลูก
  Future<void> _deletePlotData(String plotId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/api/plots/$plotId'),
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
  void _showDeleteConfirmDialog(BuildContext context, Map<String, dynamic> plot) {
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
    return Stack(
      children: [
        // Container พื้นหลัง
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
        // ปุ่มซ้าย
        Positioned(
          bottom: height * 0.01, // ✅ ควบคุม position เอง
          left: width * 0.07, // ✅ ควบคุม position เอง
          child: Container(
            width: width * 0.12,
            height: height * 0.05,
            decoration: ShapeDecoration(
              color: Color(0xFF34D396),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(38),
              ),
            ),
          ),
        ),
        // ปุ่มขวา
        Positioned(
          bottom: height * 0.01, // ✅ ควบคุม position เอง
          right: width * 0.07, // ✅ ควบคุม position เอง
          child: Container(
            width: width * 0.12,
            height: height * 0.05,
            decoration: ShapeDecoration(
              color: Color(0xFF34D396),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(38),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // บันทึกข้อมูลและ refresh หน้าจอ
  void _savePlotData() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/plots'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": widget.userId,
        "plotName": plotName,
        "plantType": selectedPlant,
        "waterSource": selectedWater,
        "soilType": selectedSoil,
      }),
    );

    if (response.statusCode == 200) {
      print('บันทึกข้อมูลแปลงปลูกสำเร็จ');
      // รีเฟรชข้อมูลใหม่
      await _loadPlotData();
      _showSuccessDialog(context);

      // Clear form
      setState(() {
        plotName = '';
        selectedPlant = '';
        selectedWater = '';
        selectedSoil = '';
        plotNameController.clear();
      });
    } else {
      print('เกิดข้อผิดพลาด: ${response.body}');
    }
  }

  // Popup สำหรับใส่ชื่อแปลงปลูก
  void _showPlotNamePopup(BuildContext context) {
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: height * 0.03),
                            // ไอคอน
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
                            if (plotNameController.text.trim().isNotEmpty) {
                              setState(() {
                                plotName = plotNameController.text.trim();
                              });
                              Navigator.pop(context);
                              _showFirstPopup(context);
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

  // Popup เลือกพืชไร่
  void _showFirstPopup(BuildContext context) {
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
                              _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg', 'plant', setDialogState),
                              _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg', 'plant', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg', 'plant', setDialogState),
                              _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg', 'plant', setDialogState),
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
                              _showPlotNamePopup(context);
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
                              _buildPopupItem('ขุดสระ', 'assets/ขุดสระ.png', 'water', setDialogState),
                              _buildPopupItem('น้ำบาดาล', 'assets/น้ำบาดาล.png', 'water', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('แหล่งน้ำธรรมชาติ', 'assets/ธรรมชาติ.png', 'water', setDialogState),
                              _buildPopupItem('น้ำชลประธาน', 'assets/น้ำชลประทาน.png', 'water', setDialogState),
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
                              _showFirstPopup(context);
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
                              _buildPopupItem('ดินทราย', 'assets/ดินทราย.png', 'soil', setDialogState),
                              _buildPopupItem('ดินร่วน', 'assets/ดินร่วน.png', 'soil', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ดินเหนียว', 'assets/ดินเหนียว.png', 'soil', setDialogState),
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
                            if (plotNameController.text.trim().isNotEmpty) {
                              setState(() {
                                plotName = plotNameController.text.trim();
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
                              _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg', 'plant', setDialogState),
                              _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg', 'plant', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg', 'plant', setDialogState),
                              _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg', 'plant', setDialogState),
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
                              _buildPopupItem('ขุดสระ', 'assets/ขุดสระ.png', 'water', setDialogState),
                              _buildPopupItem('น้ำบาดาล', 'assets/น้ำบาดาล.png', 'water', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('แหล่งน้ำธรรมชาติ', 'assets/ธรรมชาติ.png', 'water', setDialogState),
                              _buildPopupItem('น้ำชลประธาน', 'assets/น้ำชลประทาน.png', 'water', setDialogState),
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
                              _buildPopupItem('ดินทราย', 'assets/ดินทราย.png', 'soil', setDialogState),
                              _buildPopupItem('ดินร่วน', 'assets/ดินร่วน.png', 'soil', setDialogState),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPopupItem('ดินเหนียว', 'assets/ดินเหนียว.png', 'soil', setDialogState),
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
  Widget _buildPopupItem(String label, String imagePath, String type, StateSetter setDialogState) {
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