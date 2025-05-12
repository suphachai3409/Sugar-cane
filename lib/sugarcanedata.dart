import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'weather_widget.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH', null);
  runApp(sugarcanedata()); // เพิ่ม runApp(MyApp()) ตรงนี้เพื่อให้แอปเริ่มทำงาน
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
      home: const sugarcanedata(),
    );
  }
}

class sugarcanedata extends StatelessWidget {
  const sugarcanedata({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoilAnalysisProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}

class SoilAnalysis {
  String date;
  File? image;
  String topic;
  String message;

  SoilAnalysis({
    required this.date,
    this.image,
    required this.topic,
    this.message = "",
  });
}

class SoilAnalysisProvider with ChangeNotifier {
  final List<SoilAnalysis> _analyses = [];

  List<SoilAnalysis> get analyses => _analyses;

  // เพิ่มเมธอดเพื่อตรวจสอบว่ามีการบันทึกหัวข้อนั้นไว้แล้วหรือไม่
  bool isTopicSaved(String topic) {
    return _analyses.any((analysis) => analysis.topic == topic);
  }

  // เพิ่มเมธอดเพื่อดึงข้อมูลการวิเคราะห์ตามหัวข้อ
  SoilAnalysis? getAnalysisByTopic(String topic) {
    try {
      return _analyses.firstWhere((analysis) => analysis.topic == topic);
    } catch (e) {
      return null;
    }
  }

  void addAnalysis(SoilAnalysis analysis) {
    _analyses.add(analysis);
    notifyListeners();
  }

  void removeAnalysis(SoilAnalysis analysis) {
    _analyses.remove(analysis);
    notifyListeners();
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          "อ้อย",
          style: TextStyle(color: Color(0xFF25634B)),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "เลิกปลูก",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Positioned(
              top: height * 0.02,
              left: width * 0.05,
              child: const WeatherWidget(),
            ),
            // Main green container as background for content
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
                // Now tabs will be placed inside this container
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        // Tab controls inside green container
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              color: Color(0xFF25634B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Color(0xFF25634B),
                            labelStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(icon: Icon(Icons.history), text: "ประวัติ"),
                              Tab(icon: Icon(Icons.lightbulb), text: "แนะนำ"),
                              Tab(icon: Icon(Icons.info), text: "ข้อมูลแปลง"),
                            ],
                          ),
                        ),
                        SizedBox(height: 0),
                        // Tab views inside green container
                        Expanded(
                          child: TabBarView(
                            children: [
                              HistoryTab(),
                              SuggestionTab(),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "ข้อมูลแปลง",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "ยังไม่มีข้อมูลแปลง",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Custom bottom navigation bar container (white background)
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

class SuggestionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SoilAnalysisProvider>(builder: (context, provider, child) {
      return ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          final topic = _topics[index];
          // ตรวจสอบว่าหัวข้อนี้มีการบันทึกแล้วหรือไม่
          final isSaved = provider.isTopicSaved(topic);

          return _buildOptionCard(topic, context, isSaved);
        },
      );
    });
  }

  Widget _buildOptionCard(String text, BuildContext context, bool isSaved) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Get current date for new entries
          final now = DateTime.now();
          final formatter = DateFormat('dd/MM/yyyy');
          final currentDate = formatter.format(now);

          // ตรวจสอบว่ามีข้อมูลเดิมหรือไม่
          final provider =
              Provider.of<SoilAnalysisProvider>(context, listen: false);
          final existingAnalysis = provider.getAnalysisByTopic(text);

          if (existingAnalysis != null) {
            // ถ้ามีข้อมูลอยู่แล้ว ให้เปิดหน้าแก้ไข
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyzeSoilScreen(
                  topic: text,
                  date: existingAnalysis.date,
                  image: existingAnalysis.image,
                  message: existingAnalysis.message,
                  isEditing: true,
                  analysis: existingAnalysis,
                ),
              ),
            );
          } else {
            // ถ้ายังไม่มีข้อมูล ให้เปิดหน้าเพิ่มใหม่
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyzeSoilScreen(
                  topic: text,
                  date: currentDate,
                ),
              ),
            );
          }
        },
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Color(0xFF25634B)),
                ),
              ),
            ),
            // แสดงไอคอนติกถูกถ้ามีการบันทึกแล้ว
            if (isSaved)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  final List<String> _topics = [
    "วิเคราะห์ดิน",
    "บำรุงดิน",
    "ไถดินดาน",
    "ไถดะ",
    "ไถแปร",
    "ไถดิน",
    "ใส่ปุ๋ยรองพื้น",
    "ใส่ปุ๋ยกรุ่น",
    "ใส่ปุ๋ยแต่งหน้า",
    "ฉีดยาคุมวัชพืช",
    "กำจัดวัชพืช",
    "เริ่มเก็บเกี่ยว",
    "ขายผลผลิต",
  ];
}

class HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SoilAnalysisProvider>(builder: (context, provider, child) {
      final groupedAnalyses = _groupByDate(provider.analyses);

      if (groupedAnalyses.isEmpty) {
        return Center(
          child: Text(
            "ยังไม่มีประวัติการบันทึกข้อมูล",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.all(16),
        children: groupedAnalyses.entries.map((entry) {
          final date = entry.key;
          final analyses = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Color(0xFF25634B)),
                        SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            color: Color(0xFF25634B),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Column(
                      children: analyses.map((analysis) {
                        return _buildAnalysisTile(analysis, context);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildAnalysisTile(SoilAnalysis analysis, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Color(0xFF34D396),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          analysis.topic,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalyzeSoilScreen(
                topic: analysis.topic,
                date: analysis.date,
                image: analysis.image,
                message: analysis.message,
                isEditing: true,
                analysis: analysis,
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, List<SoilAnalysis>> _groupByDate(List<SoilAnalysis> analyses) {
    final Map<String, List<SoilAnalysis>> grouped = {};
    for (var analysis in analyses) {
      grouped.putIfAbsent(analysis.date, () => []).add(analysis);
    }
    return grouped;
  }
}

class AnalyzeSoilScreen extends StatefulWidget {
  final String topic;
  final String? date;
  final File? image;
  final String? message;
  final bool isEditing;
  final SoilAnalysis? analysis;

  AnalyzeSoilScreen({
    required this.topic,
    this.date,
    this.image,
    this.message = "",
    this.isEditing = false,
    this.analysis,
  });

  @override
  _AnalyzeSoilScreenState createState() => _AnalyzeSoilScreenState();
}

class _AnalyzeSoilScreenState extends State<AnalyzeSoilScreen> {
  late TextEditingController _dateController;
  late TextEditingController _messageController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.date ?? "");
    _messageController = TextEditingController(text: widget.message ?? "");
    _image = widget.image;
  }

  Future<void> _takePicture() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "รายละเอียดข้อมูล" : "บันทึกข้อมูล"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'วันที่'),
              readOnly: true,
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (selectedDate != null) {
                  setState(() {
                    _dateController.text =
                        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
                  });
                }
              },
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: 'ข้อความ'),
              keyboardType: TextInputType.text,
              style: TextStyle(fontFamily: 'Sarabun'),
            ),
            ElevatedButton(
              onPressed: _takePicture,
              child: Text("ถ่ายรูป"),
            ),
            SizedBox(height: 16),
            // แสดงภาพถ่าย
            if (_image != null)
              Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
              ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final analysis = SoilAnalysis(
                  date: _dateController.text,
                  image: _image,
                  topic: widget.topic,
                  message: _messageController.text,
                );

                if (widget.isEditing) {
                  Provider.of<SoilAnalysisProvider>(context, listen: false)
                      .removeAnalysis(widget.analysis!);
                }

                Provider.of<SoilAnalysisProvider>(context, listen: false)
                    .addAnalysis(analysis);

                // แสดงข้อความบันทึกสำเร็จ
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('บันทึกข้อมูลสำเร็จ'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                Navigator.pop(context);
              },
              child: Text(widget.isEditing ? "บันทึกการแก้ไข" : "บันทึก"),
            ),
            if (widget.isEditing)
              ElevatedButton(
                onPressed: () {
                  // แสดง dialog ยืนยันการลบ
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("ยืนยันการลบ"),
                      content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลนี้?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // ปิด dialog
                          },
                          child: Text("ยกเลิก"),
                        ),
                        TextButton(
                          onPressed: () {
                            // ลบข้อมูลจาก Provider
                            Provider.of<SoilAnalysisProvider>(context,
                                    listen: false)
                                .removeAnalysis(widget.analysis!);

                            // แสดงข้อความลบสำเร็จ
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('ลบข้อมูลสำเร็จ'),
                                backgroundColor: Colors.redAccent,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            Navigator.pop(context); // ปิด dialog
                            Navigator.pop(context); // กลับไปที่หน้าก่อนหน้า
                          },
                          child: Text("ลบ"),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text("ลบ", style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

class ImageDetailScreen extends StatelessWidget {
  final SoilAnalysis analysis;

  ImageDetailScreen({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียด"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis.image != null) Image.file(analysis.image!),
            Text(
              "หัวข้อ: ${analysis.topic}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("วันที่: ${analysis.date}", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
