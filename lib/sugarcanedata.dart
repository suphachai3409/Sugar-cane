import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  String topic; // เพิ่มหัวข้อ

  // กำหนดคอนสตรัคเตอร์
  SoilAnalysis({required this.date, this.image, required this.topic});
}

class SoilAnalysisProvider with ChangeNotifier {
  List<SoilAnalysis> _analyses = [];

  List<SoilAnalysis> get analyses => _analyses;

  // ฟังก์ชันเพิ่มข้อมูลการวิเคราะห์
  void addAnalysis(SoilAnalysis analysis) {
    _analyses.add(analysis);
    notifyListeners();
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // จำนวนแท็บ
      child: Scaffold(
        backgroundColor: Colors.grey[100], // เพิ่มสีพื้นหลังเบาๆ
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.green),
            onPressed: () {},
          ),
          title: Text(
            "อ้อย",
            style: TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {},
              child: Text(
                "เลิกปลูก",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            indicator: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(20),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(
                icon: Icon(Icons.history),
                text: "ประวัติ",
              ),
              Tab(
                icon: Icon(Icons.lightbulb),
                text: "แนะนำ",
              ),
              Tab(
                icon: Icon(Icons.info),
                text: "ข้อมูลแปลง",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // เนื้อหาแท็บ: ประวัติ
            HistoryTab(),

            // เนื้อหาแท็บ: แนะนำ
            SuggestionTab(),

            // เนื้อหาแท็บ: ข้อมูลแปลง
            Center(child: Text("เนื้อหาแท็บ: ข้อมูลแปลง")),
          ],
        ),
      ),
    );
  }
}

class SuggestionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ส่วนแนะนำ
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ศุกร์, 09/08/2567",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "26°C\nฝนตกหนัก",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Icon(Icons.cloud, size: 48, color: Colors.white),
            ],
          ),
        ),

        // ปุ่มวิเคราะห์ดิน
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildOptionCard("วิเคราะห์ดิน", context),
                _buildOptionCard("บำรุงดิน", context),
                _buildOptionCard("ไถดินดาน", context),
                _buildOptionCard("ไถดะ", context),
                _buildOptionCard("ไถแปร", context),
                _buildOptionCard("ไถดิน", context),
                _buildOptionCard("ใส่ปุ๋ยรองพื้น", context),
                _buildOptionCard("ใส่ปุ๋ยกรุ่น", context),
                _buildOptionCard("ใส่ปุ๋ยแต่งหน้า", context),
                _buildOptionCard("ฉีดยาคุมวัชพืช", context),
                _buildOptionCard("กำจัดวัชพืช", context),
                _buildOptionCard("เริ่มเก็บเกี่ยว", context),
                _buildOptionCard("ขายผลผลิต", context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ฟังก์ชันสร้าง Card สำหรับแต่ละปุ่ม
  Widget _buildOptionCard(String text, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // ส่งค่า topic ไปที่ AnalyzeSoilScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AnalyzeSoilScreen(topic: text), // ส่งค่า topic
            ),
          );
        },
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
          ),
        ),
      ),
    );
  }
}

class AnalyzeSoilScreen extends StatefulWidget {
  final String topic; // รับ topic ที่ส่งมาจาก _buildOptionCard

  AnalyzeSoilScreen({required this.topic});

  @override
  _AnalyzeSoilScreenState createState() => _AnalyzeSoilScreenState();
}

class _AnalyzeSoilScreenState extends State<AnalyzeSoilScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  TextEditingController _dateController = TextEditingController();

  // ฟังก์ชันถ่ายรูป
  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
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
        title: Text("บันทึกการวิเคราะห์ดิน"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แสดงหัวข้อที่ส่งมา
            Text(
              "หัวข้อ: ${widget.topic}",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),

            // ฟอร์มเลือกวันที่
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: "วันที่",
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dateController.text =
                            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                      });
                    }
                  },
                ),
              ),
            ),

            SizedBox(height: 16),

            // ปุ่มถ่ายรูป
            ElevatedButton(
              onPressed: _takePicture,
              child: Text("ถ่ายรูป"),
            ),

            // แสดงรูปที่ถ่าย
            if (_image != null) ...[
              SizedBox(height: 16),
              Image.file(_image!),
            ],

            SizedBox(height: 16),

            // ปุ่มบันทึก
            ElevatedButton(
              onPressed: () {
                // เพิ่มข้อมูลการวิเคราะห์ดินใน provider
                Provider.of<SoilAnalysisProvider>(context, listen: false)
                    .addAnalysis(SoilAnalysis(
                  date: _dateController.text,
                  image: _image,
                  topic: widget.topic, // ส่งหัวข้อที่เลือกไปตอนบันทึก
                ));

                Navigator.pop(context);
              },
              child: Text("บันทึก"),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SoilAnalysisProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: provider.analyses.length,
          itemBuilder: (context, index) {
            SoilAnalysis analysis = provider.analyses[index];
            return ListTile(
              title: Text(analysis.topic),
              subtitle: Text(analysis.date),
              leading: analysis.image != null
                  ? Image.file(analysis.image!, width: 50, height: 50)
                  : Icon(Icons.image, size: 50),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                // ไปหน้าจอ ImageDetailScreen พร้อมส่งข้อมูล
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageDetailScreen(analysis: analysis),
                  ),
                );
              },
            );
          },
        );
      },
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
        title: Text("รายละเอียดการวิเคราะห์ดิน"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (analysis.image != null)
              Center(
                child: Image.file(
                  analysis.image!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: Icon(Icons.image_not_supported, size: 100),
              ),
            SizedBox(height: 16),
            Text(
              "หัวข้อ: ${analysis.topic}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "วันที่: ${analysis.date}",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
