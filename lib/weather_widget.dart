import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'weather_service.dart';
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/date_symbol_data_local.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  WeatherInfo? _weatherInfo;
  Position? _currentPosition;
  String _currentAddress = '';
  String _currentDateTime = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH').then((_) {
      _loadWeatherData();
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE d MMMM yyyy - HH:mm', 'th_TH');
    setState(() {
      _currentDateTime = formatter.format(now);
    });
    // อัปเดตเวลาทุกๆ 1 นาที
    Future.delayed(const Duration(minutes: 1), _updateDateTime);
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // รับตำแหน่งปัจจุบัน
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // รับที่อยู่จากตำแหน่ง
      final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude
      );
      setState(() {
        _currentAddress = address;
      });

      // รับข้อมูลสภาพอากาศ
      final weatherInfo = await _weatherService.getWeather(
          position.latitude,
          position.longitude
      );
      setState(() {
        _weatherInfo = weatherInfo;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 334,
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.98, -0.20),
          end: Alignment(-0.98, 0.2),
          colors: [Color(0xFF325FD1), Color(0xFF4F7EF9)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.white),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentDateTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentAddress,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          if (_weatherInfo != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weatherInfo!.temperature.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weatherInfo!.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ความชื้น: ${_weatherInfo!.humidity.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Image.network(
                  'https://openweathermap.org/img/w/${_weatherInfo!.icon}.png',
                  width: 80,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.cloud, size: 80, color: Colors.white),
                ),
              ],
            ),
        ],
      ),
    );
  }
}