import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  runApp(Menu3Screen()); // เพิ่ม runApp(MyApp()) ตรงนี้เพื่อให้แอปเริ่มทำงาน
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
      home: const Menu3Screen(),
    );
  }
}

class Menu3Screen extends StatelessWidget {
  const Menu3Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(''),
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
                  )),

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
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
