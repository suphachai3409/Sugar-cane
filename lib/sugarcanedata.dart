import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
  String topic;

  SoilAnalysis({required this.date, this.image, required this.topic});
}

class SoilAnalysisProvider with ChangeNotifier {
  final List<SoilAnalysis> _analyses = [];

  List<SoilAnalysis> get analyses => _analyses;

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
  String? _weatherDescription;
  double? _temperature;
  String? _location;
  String? _date;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _fetchCurrentDate();
  }

  Future<void> _fetchWeather() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      String apiKey =
          "88b04d1d67ea346bd97a4a465832a484"; // Replace with your API key
      String weatherUrl =
          "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey";

      final response = await http.get(Uri.parse(weatherUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherDescription = data["weather"][0]["description"];
          _temperature = data["main"]["temp"];
          _location = data["name"];
        });
      } else {
        print("Failed to load weather data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
  }

  void _fetchCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy');
    setState(() {
      _date = formatter.format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFF34D396),
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {},
          ),
          title: Text(
            "อ้อย",
            style: TextStyle(color: Colors.white),
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
          backgroundColor: Colors.green[700],
          elevation: 0,
          bottom: TabBar(
            indicator: BoxDecoration(
              color: Colors.green[900],
              borderRadius: BorderRadius.circular(20),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF25634B),
            tabs: [
              Tab(icon: Icon(Icons.history), text: "ประวัติ"),
              Tab(icon: Icon(Icons.lightbulb), text: "แนะนำ"),
              Tab(icon: Icon(Icons.info), text: "ข้อมูลแปลง"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            HistoryTab(),
            SuggestionTab(
              weatherDescription: _weatherDescription,
              temperature: _temperature,
              location: _location,
              date: _date,
            ),
            Center(
              // Updated content for "ข้อมูลแปลง"
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ข้อมูลแปลง",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "ยังไม่มีข้อมูลแปลง",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestionTab extends StatelessWidget {
  final String? weatherDescription;
  final double? temperature;
  final String? location;
  final String? date;

  SuggestionTab(
      {this.weatherDescription, this.temperature, this.location, this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _topics.length,
            itemBuilder: (context, index) {
              return _buildOptionCard(_topics[index], context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null) ...[
            Text(
              "วันที่: $date",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
          if (location != null) ...[
            SizedBox(height: 8),
            Text(
              "ตำแหน่งปัจจุบัน: $location",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
          if (temperature != null) ...[
            SizedBox(height: 8),
            Text(
              "อุณหภูมิ: ${temperature!.toStringAsFixed(1)}°C",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
          if (weatherDescription != null) ...[
            SizedBox(height: 8),
            Text(
              "สภาพอากาศ: $weatherDescription",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionCard(String text, BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AnalyzeSoilScreen(topic: text)),
          );
        },
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Color(0xFF25634B)),
            ),
          ),
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
    return Consumer<SoilAnalysisProvider>(
      builder: (context, provider, child) {
        final groupedAnalyses = _groupByDate(provider.analyses);

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
      },
    );
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
        subtitle: Text(
          "วันที่: ${analysis.date}",
          style: TextStyle(color: Colors.white70),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _showDeleteConfirmationDialog(context, analysis);
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ImageDetailScreen(analysis: analysis)),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, SoilAnalysis analysis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("ยืนยันการลบ"),
          content: Text("คุณต้องการลบข้อมูลนี้หรือไม่?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("ยกเลิก"),
            ),
            TextButton(
              onPressed: () {
                Provider.of<SoilAnalysisProvider>(context, listen: false)
                    .removeAnalysis(analysis); // Using removeAnalysis here
                Navigator.of(context).pop();
              },
              child: Text("ลบ", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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

  AnalyzeSoilScreen({required this.topic});

  @override
  _AnalyzeSoilScreenState createState() => _AnalyzeSoilScreenState();
}

class _AnalyzeSoilScreenState extends State<AnalyzeSoilScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _dateController = TextEditingController();

  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("แจ้งเตือน"),
          content: Text("กรุณาใส่วันที่ก่อนบันทึก"),
          actions: [
            TextButton(
              child: Text("ตกลง"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
            Text(
              "หัวข้อ: ${widget.topic}",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF25634B)),
            ),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "วันที่",
                labelStyle: TextStyle(color: Color(0xFF25634B)),
                suffixIcon:
                    Icon(Icons.calendar_today, color: Color(0xFF25634B)),
              ),
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
            ElevatedButton(
              onPressed: _takePicture,
              child: Text("ถ่ายรูป"),
            ),
            if (_image != null) ...[
              SizedBox(height: 16),
              Image.file(_image!),
            ],
            ElevatedButton(
              onPressed: () {
                if (_dateController.text.isEmpty) {
                  _showAlertDialog(context);
                } else {
                  Provider.of<SoilAnalysisProvider>(context, listen: false)
                      .addAnalysis(SoilAnalysis(
                    date: _dateController.text,
                    image: _image,
                    topic: widget.topic,
                  ));

                  Navigator.pop(context);
                }
              },
              child: Text("บันทึก"),
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
