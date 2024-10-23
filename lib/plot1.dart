import 'package:flutter/material.dart';



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

          Positioned(
            top: 300,
            left: 140,
            child: Container(
                width: 90,
                height: 85,
                decoration: ShapeDecoration(
                  color: Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
              )
          ),

          Positioned(
            top: 400,
            left: 110,
            child:  Text(
                'กดเพื่อสร้างแปลง',
                style: TextStyle(
                  color: Color(0xFF25624B),
                  fontSize: 20,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  height: 0,
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
