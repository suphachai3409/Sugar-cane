import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่าบริการหาตำแหน่งเปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // ตรวจสอบการอนุญาตใช้บริการหาตำแหน่ง
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // ขอตำแหน่งปัจจุบัน
    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
      }
      return 'ไม่พบข้อมูลที่อยู่';
    } catch (e) {
      return 'ไม่สามารถดึงข้อมูลที่อยู่ได้';
    }
  }
}