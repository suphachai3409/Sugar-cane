import 'package:flutter/material.dart';

void main() {
  runApp(ResponsiveHomeScreen());
}

class ResponsiveHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ดึงค่าขนาดหน้าจอ
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Container สีเขียว (ปรับขนาดตามหน้าจอ)
          Positioned(
            top: height * 0.3, // 30% ของความสูงหน้าจอ
            left: 0,
            right: 0,
            child: Container(
              width: width * 0.9, // 90% ของความกว้างหน้าจอ
              height: height * 0.5, // 50% ของความสูงหน้าจอ
              decoration: ShapeDecoration(
                color: Color(0xFF34D396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),

          // Container ฟ้า (ปรับขนาดตามหน้าจอ)
          Positioned(
            top: height * 0.02, // 2% ของความสูงหน้าจอ
            left: width * 0.05, // 5% ของความกว้างหน้าจอ
            child: Container(
              width: width * 0.9, // 90% ของความกว้างหน้าจอ
              height: height * 0.25, // 25% ของความสูงหน้าจอ
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.06, // 6% ของความกว้างหน้าจอ
                vertical: height * 0.02, // 2% ของความสูงหน้าจอ
              ),
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.98, -0.20),
                  end: Alignment(-0.98, 0.2),
                  colors: [Color(0xFF325FD1), Color(0xFF4F7EF9)],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Container ปุ่มล่าง (ปรับขนาดตามหน้าจอ)
          Positioned(
            bottom: height * 0.02, // 2% จากด้านล่าง
            left: width * 0.03, // 3% จากด้านซ้าย
            right: width * 0.03, // 3% จากด้านขวา
            child: Container(
              height: height * 0.08, // 8% ของความสูงหน้าจอ
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

          // Text 'Main menu'
          Positioned(
            top: height * 0.31, // 31% ของความสูงหน้าจอ
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Main menu',
                style: TextStyle(
                  color: Color(0xFF25624B),
                  fontSize: width * 0.05, // 5% ของความกว้างหน้าจอ
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Grid layout สำหรับเมนู 4 รายการ
          Positioned(
            top: height * 0.36, // 36% ของความสูงหน้าจอ
            left: width * 0.05, // 5% ของความกว้างหน้าจอ
            right: width * 0.05, // 5% ของความกว้างหน้าจอ
            child: Container(
              height: height * 0.4, // 40% ของความสูงหน้าจอ
              child: GridView.count(
                crossAxisCount: 2, // 2 คอลัมน์
                crossAxisSpacing: width * 0.04, // 4% ของความกว้างหน้าจอ
                mainAxisSpacing: height * 0.02, // 2% ของความสูงหน้าจอ
                physics: NeverScrollableScrollPhysics(), // ปิดการเลื่อน
                children: [
                  // แปลงปลูก
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Plot1Screen()),
                      );
                    },
                    child: _buildMenuItem('assets/kid.png', 'แปลงปลูก'),
                  ),

                  // คนงาน
                  _buildMenuItem('assets/worker.jpg', 'คนงาน'),

                  // ลูกไร่
                  _buildMenuItem('assets/human1.png', 'ลูกไร่'),

                  // อุปกรณ์
                  _buildMenuItem('assets/trackter.png', 'อุปกรณ์'),
                ],
              ),
            ),
          ),

          // ปุ่มล่างซ้าย
          Positioned(
            bottom: height * 0.03, // 3% จากด้านล่าง
            left: width * 0.07, // 7% จากด้านซ้าย
            child: Container(
              width: width * 0.12, // 12% ของความกว้างหน้าจอ
              height: height * 0.05, // 5% ของความสูงหน้าจอ
              decoration: ShapeDecoration(
                color: Color(0xFF34D396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
            ),
          ),

          // ปุ่มล่างขวา
          Positioned(
            bottom: height * 0.03, // 3% จากด้านล่าง
            right: width * 0.07, // 7% จากด้านขวา
            child: Container(
              width: width * 0.12, // 12% ของความกว้างหน้าจอ
              height: height * 0.05, // 5% ของความสูงหน้าจอ
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
    );
  }

  // วิธีสร้างเมนูไอเทม
  Widget _buildMenuItem(String imagePath, String title) {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// สมมติว่าคลาสนี้มีอยู่แล้ว
class Plot1Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('แปลงปลูก')),
      body: Center(child: Text('หน้าแปลงปลูก')),
    );
  }
}