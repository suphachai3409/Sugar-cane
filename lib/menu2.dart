import 'package:flutter/material.dart';
import 'plot1.dart';

void main() {
  runApp(Menu2Screen());
}

class Menu2Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('คนงาน'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              // Container เขียว
              Positioned(
                top: 250,
                left: 0,
                child: Container(
                  width: 380,
                  height: 486,
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
                top: 20,
                left: 22,
                child: Container(
                  width: 334,
                  height: 200,
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

              // Container ปุ่ม
              Positioned(
                top: 680,
                left: 10,
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

              Positioned(  //
                top: 260,
                left: 130,
                child: SizedBox(
                  width: 114,
                  height: 23,
                  child: Text(
                    'Main menu',
                    style: TextStyle(
                      color: Color(0xFF25624B),
                      fontSize: 20,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 0,
                    ),
                  ),
                ),
              ),


              Positioned(
                top: 320,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plot1Screen()), // ไปหน้า Plot1
                    );
                  },
                  child: Container(
                    width: 149,
                    height: 133,
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
                    child: Center(
                      child: Text(
                        'แปลงปลูก',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),



              Positioned(
                top: 320,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plot1Screen()), // ไปหน้า Plot1
                    );
                  },
                  child: Container(
                    width: 149,
                    height: 133,
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
                    child: Center(
                      child: Text(
                        'อุปกรณ์',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 500,
                right: 120,
                child: GestureDetector(
                  onTap: () {
                    // ตรวจสอบว่า Navigator.push ใช้ context ที่ถูกต้อง
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Plot1Screen()), // ไปหน้า Plot1
                    );
                  },
                  child: Container(
                    width: 149,
                    height: 133,
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
                    child: Center(
                      child: Text(
                        'เบิกล่วงหน้า',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
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
}
