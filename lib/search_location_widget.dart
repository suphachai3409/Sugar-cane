import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

// นำเข้าคลาส GeocodingService ที่สร้างไว้
import 'geocoding_service.dart';

class SearchLocationWidget extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const SearchLocationWidget({
    Key? key,
    required this.onLocationSelected
  }) : super(key: key);

  @override
  _SearchLocationWidgetState createState() => _SearchLocationWidgetState();
}

class _SearchLocationWidgetState extends State<SearchLocationWidget> {
  final TextEditingController _searchController = TextEditingController();
  final GeocodingService _geocodingService = GeocodingService();

  List<PlaceDetail> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ค้นหาตำแหน่งโดยมีการหน่วงเวลา (debounce) เพื่อลดจำนวนการเรียก API
  void _searchPlaces(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length >= 3) {
        setState(() {
          _isSearching = true;
        });

        try {
          final results = await _geocodingService.searchPlaces(query);
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        } catch (e) {
          setState(() {
            _isSearching = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการค้นหา: $e')),
          );
        }
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  // เลือกตำแหน่งจากผลการค้นหา
  void _selectLocation(PlaceDetail place) {
    widget.onLocationSelected(place.location);

    // ล้างผลการค้นหาและปิดหน้าต่างสำหรับการค้นหา
    setState(() {
      _searchResults = [];
      _searchController.text = place.formattedAddress;
    });

    // ซ่อนแป้นพิมพ์
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ช่องค้นหา
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหาตำแหน่ง',
              border: InputBorder.none,
              suffixIcon: _isSearching
                  ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF34D396),
                ),
              )
                  : IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  _searchPlaces(_searchController.text);
                },
              ),
            ),
            onChanged: _searchPlaces,
          ),
        ),

        // แสดงผลการค้นหา
        if (_searchResults.isNotEmpty)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: Icon(Icons.location_on, color: Color(0xFF34D396)),
                    title: Text(
                      place.formattedAddress,
                      style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: _buildAddressDetails(place),
                    dense: true,
                    onTap: () => _selectLocation(place),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // สร้าง widget แสดงรายละเอียดที่อยู่
  Widget _buildAddressDetails(PlaceDetail place) {
    String details = '';

    // จัดลำดับการแสดงรายละเอียดที่อยู่ตามความสำคัญ
    if (place.addressComponents.containsKey('sublocality_level_1')) {
      details += place.addressComponents['sublocality_level_1']! + ', ';
    }

    if (place.addressComponents.containsKey('administrative_area_level_1')) {
      details += place.addressComponents['administrative_area_level_1']!;
    }

    return Text(
      details,
      style: TextStyle(
                            fontFamily: 'NotoSansThai',fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}