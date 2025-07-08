import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// พัฒนาคลาสสำหรับใช้งาน Google Geocoding API
class GeocodingService {
  // คีย์ API (ต้องใส่คีย์ของคุณเอง)
  final String apiKey = 'AIzaSyAOqwGzcv9K8GTRX8brAWno85_fwP6G8tI';

  // ค้นหาตำแหน่งจากชื่อสถานที่หรือที่อยู่
  Future<List<PlaceDetail>> searchPlaces(String query) async {
    // เข้ารหัส URL สำหรับภาษาไทย
    final encodedQuery = Uri.encodeComponent(query);

    // สร้าง URL สำหรับ API Request (เพิ่มพารามิเตอร์ language=th เพื่อรองรับภาษาไทย)
    final url = 'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$encodedQuery'
        '&language=th'
        '&region=th'
        '&key=$apiKey';

    try {
      // ส่ง HTTP Request
      final response = await http.get(Uri.parse(url));

      // ตรวจสอบสถานะการตอบกลับ
      if (response.statusCode == 200) {
        // แปลงข้อมูล JSON
        final data = json.decode(response.body);

        // ตรวจสอบสถานะจาก API
        if (data['status'] == 'OK') {
          // แปลงข้อมูลเป็นรายการสถานที่
          final results = data['results'] as List;
          return results.map((result) => PlaceDetail.fromJson(result)).toList();
        } else {
          // กรณีที่ API ส่งสถานะความผิดพลาด
          throw Exception('Geocoding API error: ${data['status']}');
        }
      } else {
        // กรณี HTTP error
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      // จัดการข้อผิดพลาดอื่น ๆ
      throw Exception('Error searching places: $e');
    }
  }

  // ดึงข้อมูลตำแหน่งจากละติจูดและลองจิจูด (Reverse Geocoding)
  Future<List<PlaceDetail>> getAddressFromLatLng(LatLng position) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${position.latitude},${position.longitude}'
        '&language=th'
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results.map((result) => PlaceDetail.fromJson(result)).toList();
        } else {
          throw Exception('Reverse geocoding API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting address: $e');
    }
  }
}

// คลาสเก็บข้อมูลรายละเอียดสถานที่
class PlaceDetail {
  final String placeId;
  final String formattedAddress;
  final LatLng location;
  final String locationType;
  final Map<String, String> addressComponents;

  PlaceDetail({
    required this.placeId,
    required this.formattedAddress,
    required this.location,
    required this.locationType,
    required this.addressComponents,
  });

  // แปลงข้อมูล JSON เป็นออบเจ็กต์
  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    // แยกข้อมูลตำแหน่ง
    final geometry = json['geometry'];
    final location = geometry['location'];

    // แยกข้อมูลองค์ประกอบที่อยู่
    final components = json['address_components'] as List;
    final addressComponents = <String, String>{};

    // แปลงองค์ประกอบที่อยู่เป็น Map
    for (var component in components) {
      final types = component['types'] as List;
      final longName = component['long_name'] as String;

      for (var type in types) {
        addressComponents[type.toString()] = longName;
      }
    }

    return PlaceDetail(
      placeId: json['place_id'],
      formattedAddress: json['formatted_address'],
      location: LatLng(
        location['lat'],
        location['lng'],
      ),
      locationType: geometry['location_type'],
      addressComponents: addressComponents,
    );
  }
}