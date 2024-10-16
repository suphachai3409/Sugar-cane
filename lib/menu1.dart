import 'package:flutter/material.dart';

void main() {
  runApp(Menu1Screen());  // เพิ่ม runApp(MyApp()) ตรงนี้เพื่อให้แอปเริ่มทำงาน
}

class Menu1Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Two Containers Example'),
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
              


            ],
          ),
        ),
      ),
    );
  }
}
