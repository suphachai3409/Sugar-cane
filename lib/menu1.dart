import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // สำหรับภาษาไทย
import 'weather_widget.dart';
import 'plot1.dart';
import 'package:intl/date_symbol_data_local.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
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
        fontFamily: 'Kanit', // ถ้าต้องการใช้ฟอนต์ภาษาไทย
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
    return Scaffold(
      appBar: AppBar(
        title: Text('เจ้าของ'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Container เขียว
            Positioned(
              top: 250,
              left: 0,
              right: 0,
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

            // Container ฟ้าที่มี WeatherWidget
            Positioned(
              top: 20,
              left: 22,
              child: const WeatherWidget(), // ใช้ WeatherWidget แทน Container เดิม
            ),

            // Container ปุ่ม
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

            //แปลงไร่
            Positioned(
              top: 320,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Plot1Screen()),
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
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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

            // คนงาน
            Positioned(
              top: 320,
              right: 20,
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
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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

            //ลูกไร่
            Positioned(
              top: 500,
              left: 20,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          'assets/human1.png',
                          fit: BoxFit.cover,
                          width: 149,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(
                          'ลูกไร่',
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

            //อุปกรณ์
            Positioned(
              top: 500,
              right: 20,
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
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
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

            //ปุ่มล่างสุด ซ้าย
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
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                )
            ),

            //ปุ่มล่างสุด ขวา
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
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                )
            ),
          ],
        ),
      ),
    );
  }
}