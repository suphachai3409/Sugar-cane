import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherInfo {
  final String description;
  final String icon;
  final double temperature;
  final double humidity;

  WeatherInfo({
    required this.description,
    required this.icon,
    required this.temperature,
    required this.humidity,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      temperature: json['main']['temp'] - 273.15, // แปลงจาก Kelvin เป็น Celsius
      humidity: json['main']['humidity'].toDouble(),
    );
  }
}

class WeatherService {
  final String apiKey = '870fc2fe45a92085095453a26490290f'; // ใส่ API key ของคุณที่นี่

  Future<WeatherInfo> getWeather(double latitude, double longitude) async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherInfo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}