import 'package:flutter/material.dart';

void main() {
  runApp(Plot1Screen());
}

class Plot1Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('แปลงปลูก'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Positioned(
                top: 300,
                left: 140,
                child: GestureDetector(
                  onTap: () {
                    // แสดง Popup แรก
                    _showFirstPopup(context);
                  },
                  child: Container(
                    width: 90,
                    height: 85,
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
                ),
              ),
              Positioned(
                top: 680,
                left: 10,
                right: 10,
                child: Container(
                  width: 363,
                  height: 73,
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
              Positioned(
                top: 690,
                left: 25,
                child: Container(
                  width: 50,
                  height: 45,
                  decoration: ShapeDecoration(
                    color: Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 690,
                right: 25,
                child: Container(
                  width: 50,
                  height: 45,
                  decoration: ShapeDecoration(
                    color: Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFirstPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 359,
            height: 427,
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
                SizedBox(height: 20),
                Text(
                  'พืชไร่ชนิดที่ปลูก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25624B),
                  ),
                ),
                SizedBox(height: 40),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg'),
                        _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg'),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg'),
                        _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg'),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // ปิด Popup แรก
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
                        Navigator.pop(context); // ปิด Popup แรก
                        _showSecondPopup(context); // เปิด Popup ที่สอง
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
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSecondPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 359,
            height: 427,
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
                SizedBox(height: 20),
                Text(
                  'พืชไร่ชนิดที่ปลูก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25624B),
                  ),
                ),
                SizedBox(height: 40),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('พืชไร่', 'assets/พืชไร่.jpg'),
                        _buildPopupItem('พืชสวน', 'assets/พืชสวน.jpg'),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('ผลไม้', 'assets/ผลไม้.jpg'),
                        _buildPopupItem('พืชผัก', 'assets/พืชผัก.jpg'),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // ปิด Popup แรก
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
                        Navigator.pop(context); // ปิด Popup แรก
                        _showthreePopup(context); // เปิด Popup ที่สาม
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
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showthreePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 359,
            height: 427,
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
                SizedBox(height: 20),
                Text(
                  'แหล่งน้ำที่ใช้ปลูก',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25624B),
                  ),
                ),
                SizedBox(height: 40),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('ขุดสระ', 'assets/พืชไร่.jpg'),
                        _buildPopupItem('น้ำบาดาล', 'assets/พืชสวน.jpg'),
                      ],
                    ),
                    SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPopupItem('แหล่งน้ำธรรมชาติ', 'assets/ผลไม้.jpg'),
                        _buildPopupItem('น้ำชลประธาน', 'assets/พืชผัก.jpg'),
                      ],
                    ),
                  ],
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // ปิด Popup แรก
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
                        Navigator.pop(context); // เปิด Popup ที่สาม
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
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildPopupItem(String label, String imagePath) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 63,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color(0x7F646464),
                blurRadius: 4,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
