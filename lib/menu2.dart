import 'package:flutter/material.dart';
import 'plot1.dart';

void main() {
  runApp(Menu2Screen(userId: '',));  // เพิ่ม runApp(MyApp()) ตรงนี้เพื่อให้แอปเริ่มทำงาน
}

class Menu2Screen extends StatelessWidget {
final String userId;

Menu2Screen({required this.userId}); // ✅ ต้องมี userId ตรงนี้

@override
Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('ลูกไร่'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              // Container เขียว
              Positioned(
                top: height * 0.3, // 30% ของความสูงหน้าจอ
                left: 0,
                right: 0,
                child: Container(
                  width: width * 0.9, // 90% ของความกว้างหน้าจอ
                  height: height * 0.5,
                  decoration: ShapeDecoration(
                    color: Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              // Container ฟ้า
              Positioned(
                top: height * 0.02, // 2% ของความสูงหน้าจอ
                left: width * 0.01, // 5% ของความกว้างหน้าจอ
                child: Container(
                  width: width * 0.9, // 90% ของความกว้างหน้าจอ
                  height: height * 0.25,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 19),
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

              // Container ปุ่มขาว
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
                      fontSize: width * 0.055, // 5% ของความกว้างหน้าจอ
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),





              //แปลงไร่
              Positioned(
                top: height * 0.36,
                left: width * 0.06,
                child: GestureDetector(
                  onTap: () {
                    // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plot1Screen(userId: '',)), // ไปหน้า Plot1
                    );
                  },
                  child: Container(
                    height: height * 0.165,
                    width: width * 0.36,
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
                              'assets/kid.png',
                              fit: BoxFit.cover,
                              width: 149,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'แปลงปลูก',
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
                  ),
                ),
              ),





              //คนงาน
              Positioned(
                top: height * 0.36,
                right: width * 0.06,
                child: GestureDetector(
                  onTap: () {
                    // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plot1Screen(userId: '',)), // ไปหน้า Plot1
                    );
                  },
                  child: Container(
                    height: height * 0.165,
                    width: width * 0.36,
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
                              'assets/worker.jpg',
                              fit: BoxFit.cover,
                              width: 149,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'คนงาน',
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
                  ),
                ),
              ),





              //อุปกรณ์
              Positioned(
                top: height * 0.57,
                left: width * 0.06,
                child: GestureDetector(
                  onTap: () {
                    // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plot1Screen(userId: '',)), // ไปหน้า Plot1
                    );
                  },
                  child: Container(
                    height: height * 0.165,
                    width: width * 0.36,
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
                              'assets/trackter.png',
                              fit: BoxFit.cover,
                              width: 149,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'อุปกรณ์',
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
                  ),
                ),
              ),







              //เบิกเงินทุน
              Positioned(
                top: height * 0.57,
                right: width * 0.06,
                child: GestureDetector(
                  onTap: () {
                    // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plot1Screen(userId: '',)), // ไปหน้า Plot1
                    );
                  },
                  child: Container(
                    height: height * 0.165,
                    width: width * 0.36,
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
                              'assets/money.png',
                              fit: BoxFit.cover,
                              width: 149,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'ขอเบิกเงินทุน',
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
                  ),
                ),
              ),





              //ปุ่มล่างสุด ซ้าย
              Positioned(
                  bottom: height * 0.01, // 3% จากด้านล่าง
                  left: width * 0.07,
                  child: Container(
                    width: width * 0.12, // 12% ของความกว้างหน้าจอ
                    height: height * 0.05,
                    decoration: ShapeDecoration(
                      color: Color(0xFF34D396),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(38),
                      ),
                    ),
                  )
              ),


              //ปุ่มล่างสุด ขวา
              Positioned(
                  bottom: height * 0.01, // 3% จากด้านล่าง
                  right: width * 0.07,
                  child: Container(
                    width: width * 0.12, // 12% ของความกว้างหน้าจอ
                    height: height * 0.05,
                    decoration: ShapeDecoration(
                      color: Color(0xFF34D396),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(38),
                      ),
                    ),
                  )
              ),

            ],
          ),
        ),
      ),
    );
  }
}
