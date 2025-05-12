import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'weather_widget.dart';
import 'plot1.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Management App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Kanit', // ฟอนต์ภาษาไทย
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'), // Thai
        Locale('en', 'US'), // English
      ],
      home: const Menu1Screen(),
    );
  }
}

class Menu1Screen extends StatelessWidget {
  const Menu1Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ขนาดหน้าจอสำหรับการสร้าง responsive layout
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เจ้าของ'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Container เขียว - พื้นหลัง
            Positioned(
              top: height * 0.3,
              left: 0,
              right: 0,
              child: Container(
                width: width * 0.9,
                height: height * 0.5,
                decoration: ShapeDecoration(
                  color: const Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            // WeatherWidget - widget สภาพอากาศ
            Positioned(
              top: height * 0.02,
              left: width * 0.05,
              child: const WeatherWidget(),
            ),

            // หัวข้อ Main menu
            Positioned(
              top: height * 0.31,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Main menu',
                  style: TextStyle(
                    color: const Color(0xFF25624B),
                    fontSize: width * 0.055,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ปุ่มแปลงปลูก
            Positioned(
              top: height * 0.36,
              left: width * 0.06,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Plot1Screen()),
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
                    shadows: const [
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
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'แปลงปลูก',
                            style: TextStyle(
                              fontSize: width * 0.045,
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

            // ปุ่มคนงาน
            Positioned(
              top: height * 0.36,
              right: width * 0.06,
              child: Container(
                height: height * 0.165,
                width: width * 0.36,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                  shadows: const [
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
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'คนงาน',
                          style: TextStyle(
                            fontSize: width * 0.045,
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

            // ปุ่มลูกไร่
            Positioned(
              top: height * 0.57,
              left: width * 0.06,
              child: Container(
                height: height * 0.165,
                width: width * 0.36,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                  shadows: const [
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
                          'assets/human1.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'ลูกไร่',
                          style: TextStyle(
                            fontSize: width * 0.045,
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

            // ปุ่มอุปกรณ์
            Positioned(
              top: height * 0.57,
              right: width * 0.06,
              child: Container(
                height: height * 0.165,
                width: width * 0.36,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                  shadows: const [
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
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'อุปกรณ์',
                          style: TextStyle(
                            fontSize: width * 0.045,
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

            // Container สำหรับ Navigation bar ด้านล่าง
            Positioned(
              bottom: height * 0.01,
              left: width * 0.03,
              right: width * 0.03,
              child: Container(
                height: height * 0.07,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(83.50),
                  ),
                  shadows: const [
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

            // ปุ่ม Home
            Positioned(
              bottom: height * 0.018,
              left: width * 0.07,
              child: Container(
                width: width * 0.12,
                height: height * 0.055,
                decoration: ShapeDecoration(
                  color: const Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                ),
              ),
            ),

            // ปุ่ม Settings
            Positioned(
              bottom: height * 0.018,
              right: width * 0.07,
              child: Container(
                width: width * 0.12,
                height: height * 0.055,
                decoration: ShapeDecoration(
                  color: const Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}