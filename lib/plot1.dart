import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:collection';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'แอปแปลงปลูก',
      theme: ThemeData(
        primaryColor: Color(0xFF34D396),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xFF34D396),
          secondary: Color(0xFF25624B),
        ),
      ),
      home: Plot1Screen(),
    );
  }
}

// Google Places API Service
class GooglePlacesService {
  static const String _apiKey = 'AIzaSyAOqwGzcv9K8GTRX8brAWno85_fwP6G8tI'; // ใส่ API Key ของคุณที่นี่
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // ค้นหาสถานที่แบบ autocomplete รองรับภาษาไทย
  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      // ใช้ Place Autocomplete API
      final String url = '$_baseUrl/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&language=th'
          '&components=country:th'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List predictions = data['predictions'];
          return predictions.map((prediction) => PlaceSearchResult(
            name: prediction['structured_formatting']['main_text'] ?? prediction['description'],
            address: prediction['description'],
            placeId: prediction['place_id'],
          )).toList();
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    }

    return [];
  }

  // ดึงรายละเอียดสถานที่จาก Place ID
  static Future<PlaceDetail?> getPlaceDetails(String placeId) async {
    try {
      final String url = '$_baseUrl/details/json'
          '?place_id=$placeId'
          '&fields=geometry,name,formatted_address'
          '&language=th'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];

          return PlaceDetail(
            name: result['name'],
            formattedAddress: result['formatted_address'],
            location: LatLng(location['lat'], location['lng']),
          );
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }

    return null;
  }

  // Reverse Geocoding - ดึงชื่อสถานที่จากพิกัด
  static Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${position.latitude},${position.longitude}'
          '&language=th'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }

    return 'ไม่สามารถระบุตำแหน่งได้';
  }
}

class PlaceSearchResult {
  final String name;
  final String address;
  final String placeId;

  PlaceSearchResult({
    required this.name,
    required this.address,
    required this.placeId,
  });
}

class PlaceDetail {
  final String name;
  final String formattedAddress;
  final LatLng location;

  PlaceDetail({
    required this.name,
    required this.formattedAddress,
    required this.location,
  });
}

// Widget สำหรับค้นหาสถานที่
class SearchLocationWidget extends StatefulWidget {
  final Function(LatLng) onLocationSelected;

  const SearchLocationWidget({
    Key? key,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _SearchLocationWidgetState createState() => _SearchLocationWidgetState();
}

class _SearchLocationWidgetState extends State<SearchLocationWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await GooglePlacesService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Search error: $e');
    }
  }

  void _selectPlace(PlaceSearchResult place) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final placeDetail = await GooglePlacesService.getPlaceDetails(place.placeId);
      if (placeDetail != null) {
        widget.onLocationSelected(placeDetail.location);
      }
    } catch (e) {
      print('Error selecting place: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการค้นหาสถานที่')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหาสถานที่...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Color(0xFF34D396)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                  });
                },
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: _performSearch,
            style: TextStyle(fontSize: 16),
          ),
        ),

        if (_isLoading)
          Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: Color(0xFF34D396)),
          ),

        if (_searchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: math.min(_searchResults.length, 5),
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF34D396).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Color(0xFF34D396),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    place.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    place.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectPlace(place),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                );
              },
            ),
          ),
      ],
    );
  }
}

class Plot1Screen extends StatefulWidget {
  @override
  _Plot1ScreenState createState() => _Plot1ScreenState();
}

class _Plot1ScreenState extends State<Plot1Screen> {
  List<PlotInfo> plots = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แปลงปลูก'),
        backgroundColor: Color(0xFF34D396),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: plots.isEmpty ? _buildEmptyState() : _buildPlotsList(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              _navigateToMapScreen();
            },
            child: Container(
              width: 90,
              height: 85,
              decoration: BoxDecoration(
                color: Color(0xFF34D396),
                borderRadius: BorderRadius.circular(38),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF34D396).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'กดเพื่อสร้างแปลง',
            style: TextStyle(
              color: Color(0xFF34D396),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlotsList() {
    return Column(
      children: [
        // Header section
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF34D396), Color(0xFF25624B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'แปลงปลูกของคุณ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${plots.length} แปลง | ${_getTotalArea().toStringAsFixed(2)} ไร่',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        // Plots list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: plots.length,
              itemBuilder: (context, index) {
                return PlotCard(
                  plotInfo: plots[index],
                  onTap: () {
                    _showPlotDetails(plots[index]);
                  },
                  onEdit: () {
                    _editPlot(index);
                  },
                  onDelete: () {
                    _deletePlot(index);
                  },
                );
              },
            ),
          ),
        ),

        // Add new plot button
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                _navigateToMapScreen();
              },
              icon: Icon(Icons.add_location_alt, size: 24),
              label: Text(
                'เพิ่มแปลงใหม่',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF34D396),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 73,
      margin: EdgeInsets.only(left: 10, right: 10, bottom: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Container(
              width: 50,
              height: 45,
              decoration: ShapeDecoration(
                color: Color(0xFF34D396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: Icon(
                Icons.home,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 25),
            child: Container(
              width: 50,
              height: 45,
              decoration: ShapeDecoration(
                color: Color(0xFF34D396),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(38),
                ),
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getTotalArea() {
    return plots.fold(0.0, (sum, plot) => sum + plot.area);
  }

  void _showPlotDetails(PlotInfo plot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.eco, color: Color(0xFF34D396)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  plot.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('พื้นที่', '${plot.area.toStringAsFixed(2)} ไร่', Icons.crop_square),
              _buildDetailRow('ประเภทพืช', plot.plantType ?? '-', Icons.category),
              _buildDetailRow('ชนิดพืช', plot.specificPlant ?? '-', _getIconForPlantType(plot.plantType ?? '')),
              _buildDetailRow('แหล่งน้ำ', plot.waterSource ?? '-', Icons.water_drop),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF34D396), size: 20),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _editPlot(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantSelectionScreen(
          areaSize: plots[index].area,
          polygonPoints: plots[index].polygonPoints,
          isEditing: true,
          plotName: plots[index].name,
          plantType: plots[index].plantType,
          specificPlant: plots[index].specificPlant,
          waterSource: plots[index].waterSource,
        ),
      ),
    ).then((updatedPlotInfo) {
      if (updatedPlotInfo != null) {
        setState(() {
          plots[index] = updatedPlotInfo;
        });
      }
    });
  }

  void _deletePlot(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ลบแปลงปลูก'),
          content: Text('คุณต้องการลบแปลง "${plots[index].name}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  plots.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบแปลงปลูกเรียบร้อยแล้ว'),
                    backgroundColor: Color(0xFF34D396),
                  ),
                );
              },
              child: Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToMapScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GoogleMapScreen()),
    ).then((plotInfo) {
      if (plotInfo != null) {
        setState(() {
          plots.add(plotInfo);
        });
      }
    });
  }
}

class PlotCard extends StatelessWidget {
  final PlotInfo plotInfo;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlotCard({
    Key? key,
    required this.plotInfo,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8FFF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        plotInfo.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25624B),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) onEdit!();
                        if (value == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFF34D396)),
                              SizedBox(width: 8),
                              Text('แก้ไข'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('ลบ'),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(Icons.more_vert, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${plotInfo.area.toStringAsFixed(2)} ไร่',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF34D396),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: _getIconForPlantType(plotInfo.plantType ?? ''),
                        label: plotInfo.specificPlant ?? 'ยังไม่ได้เลือกพืช',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.water_drop_outlined,
                        label: plotInfo.waterSource ?? 'ยังไม่ได้เลือกแหล่งน้ำ',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPlantType(String type) {
    switch (type) {
      case 'พืชไร่':
        return Icons.grass;
      case 'พืชสวน':
        return Icons.spa;
      case 'ผลไม้':
        return Icons.emoji_food_beverage;
      case 'พืชผัก':
        return Icons.emoji_nature;
      default:
        return Icons.eco;
    }
  }
}

class GoogleMapScreen extends StatefulWidget {
  @override
  _GoogleMapScreenState createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  GoogleMapController? _mapController;
  Set<Polygon> _polygons = HashSet<Polygon>();
  Set<Marker> _markers = HashSet<Marker>();
  List<LatLng> _polygonPoints = [];
  bool _isDrawing = false;
  LatLng? _currentPosition;
  double _calculatedArea = 0.0;
  bool _isLoading = true;
  bool _isSearching = false;
  String _currentLocationName = "";

  // ตัวแปรสำหรับปรับปรุงการวาด
  bool _snapToGrid = false;
  double _gridSpacing = 0.00001; // ระยะห่าง Grid

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('กรุณาเปิดบริการระบุตำแหน่ง')),
        );
        setState(() => _isLoading = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่ได้รับอนุญาตให้เข้าถึงตำแหน่ง')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเข้าถึงตำแหน่งได้ กรุณาตั้งค่าในแอปพลิเคชันใหม่')),
        );
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _getLocationNameFromPosition(_currentPosition!);
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการระบุตำแหน่ง')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getLocationNameFromPosition(LatLng position) async {
    try {
      final address = await GooglePlacesService.getAddressFromLatLng(position);
      setState(() {
        _currentLocationName = address;
      });
    } catch (e) {
      print("Error in reverse geocoding: $e");
    }
  }

  void _moveToLocation(LatLng position) {
    _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 18)
    );
    setState(() {
      _isSearching = false;
    });

    _getLocationNameFromPosition(position);
  }

  void _handleReverseGeocoding(LatLng position) async {
    try {
      final address = await GooglePlacesService.getAddressFromLatLng(position);
      setState(() {
        _currentLocationName = address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(address),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error in reverse geocoding: $e");
    }
  }

  // ฟังก์ชันสำหรับ Snap to Grid
  LatLng _snapToGridIfEnabled(LatLng point) {
    if (!_snapToGrid) return point;

    double snappedLat = (point.latitude / _gridSpacing).round() * _gridSpacing;
    double snappedLng = (point.longitude / _gridSpacing).round() * _gridSpacing;

    return LatLng(snappedLat, snappedLng);
  }

  // ตรวจสอบว่าจุดใหม่ใกล้กับจุดแรกหรือไม่ (สำหรับปิดรูปร่าง)
  bool _isNearFirstPoint(LatLng newPoint) {
    if (_polygonPoints.isEmpty) return false;

    double distance = _calculateDistanceBetweenPoints(newPoint, _polygonPoints.first);
    return distance < 10; // ใกล้กันเป็น 10 เมตร
  }

  // ปรับปรุงการเพิ่มจุด
  void _addPolygonPoint(LatLng point) {
    LatLng snappedPoint = _snapToGridIfEnabled(point);

    // ตรวจสอบว่าใกล้กับจุดแรกหรือไม่ (ถ้ามีอย่างน้อย 3 จุดแล้ว)
    if (_polygonPoints.length >= 3 && _isNearFirstPoint(snappedPoint)) {
      // ปิดรูปร่างโดยอัตโนมัติ
      _finishDrawing();
      return;
    }

    setState(() {
      _polygonPoints.add(snappedPoint);
      _updatePolygon();
      _updateMarkers();

      if (_polygonPoints.length >= 3) {
        _calculateArea();
      }

      if (_polygonPoints.length == 1) {
        _getLocationNameFromPosition(snappedPoint);
      }
    });

    // แสดงข้อมูลจุดที่เพิ่ม
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่มจุดที่ ${_polygonPoints.length}'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  // ฟังก์ชันจบการวาด
  void _finishDrawing() {
    if (_polygonPoints.length >= 3) {
      setState(() {
        _isDrawing = false;
      });
      _calculateArea();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('วาดแปลงเสร็จสิ้น พื้นที่: ${_calculatedArea.toStringAsFixed(2)} ไร่'),
          backgroundColor: Color(0xFF34D396),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // อัปเดต Markers
  void _updateMarkers() {
    _markers.clear();

    for (int i = 0; i < _polygonPoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: _polygonPoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue
          ),
          infoWindow: InfoWindow(
            title: i == 0 ? 'จุดเริ่มต้น' : 'จุดที่ ${i + 1}',
            snippet: 'แตะเพื่อลบจุดนี้',
          ),
          onTap: () => _removePoint(i),
        ),
      );
    }
  }

  // ลบจุดที่เลือก
  void _removePoint(int index) {
    if (_polygonPoints.length <= 1) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ลบจุด'),
        content: Text('ต้องการลบจุดที่ ${index + 1} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _polygonPoints.removeAt(index);
                _updatePolygon();
                _updateMarkers();
                if (_polygonPoints.length >= 3) {
                  _calculateArea();
                } else {
                  _calculatedArea = 0.0;
                }
              });
              Navigator.pop(context);
            },
            child: Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Color(0xFF34D396),
              ),
            ),

          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(13.7563, 100.5018),
              zoom: 18,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 18)
                );
              }
            },
            polygons: _polygons,
            markers: _markers,
            onTap: _isDrawing ? _addPolygonPoint : _handleMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.hybrid, // ใช้ hybrid เพื่อดูพื้นที่ชัดเจนขึ้น
          ),

          // แสดงข้อมูลพื้นที่เมื่อวาดเสร็จ
          if (_polygonPoints.isNotEmpty && !_isDrawing)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF34D396),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.crop_square, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'พื้นที่แปลง: ${_calculatedArea.toStringAsFixed(2)} ไร่',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25624B),
                            ),
                          ),
                          if (_currentLocationName.isNotEmpty)
                            Text(
                              _currentLocationName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ช่องค้นหาสถานที่
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = true;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(38),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF34D396)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ค้นหาแปลงโดยระบุสถานที่',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ปุ่มตำแหน่งปัจจุบัน
          Positioned(
            top: 120,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Color(0xFF34D396)),
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentPosition!, 18)
                  );
                } else {
                  _determinePosition();
                }
              },
            ),
          ),

          // เครื่องมือวาดแปลง
          if (_isDrawing)
            Positioned(
              top: 120,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'เครื่องมือวาด',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF25624B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ปุ่ม Snap to Grid
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _snapToGrid = !_snapToGrid;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_snapToGrid ? 'เปิด Snap to Grid' : 'ปิด Snap to Grid'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _snapToGrid ? Color(0xFF34D396) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.grid_on,
                              size: 20,
                              color: _snapToGrid ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // ปุ่มจบการวาด
                        GestureDetector(
                          onTap: () {
                            if (_polygonPoints.length >= 3) {
                              _finishDrawing();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _polygonPoints.length >= 3 ? Color(0xFF34D396) : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 20,
                              color: _polygonPoints.length >= 3 ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_polygonPoints.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'จุดที่ ${_polygonPoints.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_polygonPoints.length >= 3)
                        Text(
                          '${_calculatedArea.toStringAsFixed(2)} ไร่',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF34D396),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

          // หน้าจอค้นหา
          if (_isSearching)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      AppBar(
                        title: Text('ค้นหาสถานที่'),
                        backgroundColor: Color(0xFF34D396),
                        foregroundColor: Colors.white,
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SearchLocationWidget(
                            onLocationSelected: (position) {
                              _moveToLocation(position);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // แสดงป้ายระยะทางระหว่างจุด
          if (_polygonPoints.isNotEmpty && !_isDrawing)
            ..._buildPolygonMarkers(),

          _buildBottomButtons(),
        ],
      ),
    );
  }

  List<Widget> _buildPolygonMarkers() {
    List<Widget> markers = [];

    for (int i = 0; i < _polygonPoints.length; i++) {
      LatLng current = _polygonPoints[i];
      LatLng next = _polygonPoints[(i + 1) % _polygonPoints.length];

      // คำนวณระยะทางระหว่างจุด
      double distance = _calculateDistanceBetweenPoints(current, next);

      // หาจุดกึ่งกลางระหว่างจุด
      LatLng midPoint = LatLng(
          (current.latitude + next.latitude) / 2,
          (current.longitude + next.longitude) / 2
      );

      // สร้างป้ายระยะทาง
      markers.add(
          _buildDistanceLabel(midPoint, distance)
      );
    }

    return markers;
  }

  Widget _buildDistanceLabel(LatLng position, double distance) {
    return _positionedMarker(
      position,
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(0xFF1976D2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${distance.toStringAsFixed(2)} ม',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _positionedMarker(LatLng position, Widget child) {
    return Positioned(
      child: child,
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      key: ValueKey(position.toString()),
    );
  }

  double _calculateDistanceBetweenPoints(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000;

    double lat1 = p1.latitude * math.pi / 180;
    double lon1 = p1.longitude * math.pi / 180;
    double lat2 = p2.latitude * math.pi / 180;
    double lon2 = p2.longitude * math.pi / 180;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  Widget _buildBottomButtons() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ปุ่มย้อน (สีเหลือง) - อยู่ด้านบน
          if (_isDrawing && _polygonPoints.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFC107),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      elevation: 4,
                    ),
                    onPressed: _undoLastPoint,
                    icon: Icon(
                      Icons.undo,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      'ย้อน',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // แถวปุ่มด้านล่าง
          Row(
            children: [
              // ปุ่มยกเลิก (สีแดง)
              Expanded(
                child: Container(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      if (_isDrawing) {
                        setState(() {
                          _isDrawing = false;
                          _polygonPoints.clear();
                          _updatePolygon();
                          _updateMarkers();
                          _calculatedArea = 0.0;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      _isDrawing ? 'ยกเลิก' : 'ยกเลิก',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 16),

              // ปุ่มหลัก (สีเขียว)
              Expanded(
                child: Container(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34D396),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      if (_isDrawing) {
                        if (_polygonPoints.length >= 3) {
                          _calculateArea();
                          _navigateToPlantSelection();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('กรุณาวาดอย่างน้อย 3 จุดเพื่อสร้างแปลง')),
                          );
                        }
                      } else {
                        setState(() {
                          _isDrawing = true;
                          _polygonPoints.clear();
                          _updatePolygon();
                          _updateMarkers();
                          _calculatedArea = 0.0;
                        });
                      }
                    },
                    child: Text(
                      _isDrawing ? 'ถัดไป' : 'วาดแปลง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng position) {
    _handleReverseGeocoding(position);
  }

  void _undoLastPoint() {
    if (_polygonPoints.isEmpty) return;

    setState(() {
      _polygonPoints.removeLast();
      _updatePolygon();
      _updateMarkers();

      if (_polygonPoints.length >= 3) {
        _calculateArea();
      } else {
        _calculatedArea = 0.0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบจุดล่าสุดแล้ว'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  void _updatePolygon() {
    _polygons.clear();

    if (_polygonPoints.length >= 3) {
      _polygons.add(
        Polygon(
          polygonId: PolygonId('planting_area'),
          points: _polygonPoints,
          fillColor: Color(0xFF34D396).withOpacity(0.3),
          strokeColor: Color(0xFF34D396),
          strokeWidth: 3,
        ),
      );
    } else if (_polygonPoints.length >= 2) {
      // แสดงเส้นเชื่อมจุดเมื่อมี 2 จุดขึ้นไป
      _polygons.add(
        Polygon(
          polygonId: PolygonId('drawing_line'),
          points: _polygonPoints,
          fillColor: Colors.transparent,
          strokeColor: Color(0xFF34D396),
          strokeWidth: 2,
        ),
      );
    }
  }

  void _calculateArea() {
    if (_polygonPoints.length < 3) return;

    double areaInSqMeters = _calculateAreaInSquareMeters(_polygonPoints);
    _calculatedArea = areaInSqMeters / 1600;

    setState(() {});
  }

  double _calculateAreaInSquareMeters(List<LatLng> points) {
    if (points.length < 3) return 0;

    double area = 0;
    final int earthRadius = 6371000;

    double centerLat = 0, centerLng = 0;
    for (LatLng point in points) {
      centerLat += point.latitude;
      centerLng += point.longitude;
    }
    centerLat /= points.length;
    centerLng /= points.length;

    LatLng centerPoint = LatLng(centerLat, centerLng);

    for (int i = 0; i < points.length; i++) {
      LatLng point1 = points[i];
      LatLng point2 = points[(i + 1) % points.length];

      double _haversineDistance(LatLng p1, LatLng p2) {
        double lat1 = p1.latitude * math.pi / 180;
        double lon1 = p1.longitude * math.pi / 180;
        double lat2 = p2.latitude * math.pi / 180;
        double lon2 = p2.longitude * math.pi / 180;

        double dLat = lat2 - lat1;
        double dLon = lon2 - lon1;

        double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(lat1) * math.cos(lat2) *
                math.sin(dLon / 2) * math.sin(dLon / 2);
        double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

        return earthRadius * c;
      }

      double side1 = _haversineDistance(centerPoint, point1);
      double side2 = _haversineDistance(centerPoint, point2);
      double side3 = _haversineDistance(point1, point2);

      double s = (side1 + side2 + side3) / 2;
      double triangleArea = math.sqrt(s * (s - side1) * (s - side2) * (s - side3));

      area += triangleArea;
    }

    return area;
  }

  void _navigateToPlantSelection() {
    if (_polygonPoints.isEmpty || _calculatedArea <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาวาดแปลงให้เสร็จก่อน')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantSelectionScreen(
          areaSize: _calculatedArea,
          polygonPoints: _polygonPoints,
          plotName: "แปลงปลูกใหม่",
        ),
      ),
    ).then((plotInfo) {
      if (plotInfo != null) {
        // ส่งข้อมูลกลับไปยังหน้าหลัก
        Navigator.pop(context, plotInfo);
      }
    });
  }
}

class PlotInfo {
  final String name;
  final double area;
  final List<LatLng> polygonPoints;
  final String? plantType;
  final String? specificPlant;
  final String? waterSource;

  PlotInfo({
    required this.name,
    required this.area,
    required this.polygonPoints,
    this.plantType,
    this.specificPlant,
    this.waterSource,
  });
}

class PlantSelectionScreen extends StatefulWidget {
  final double areaSize;
  final List<LatLng> polygonPoints;
  final bool isEditing;
  final String? plotName;
  final String? plantType;
  final String? specificPlant;
  final String? waterSource;

  const PlantSelectionScreen({
    Key? key,
    required this.areaSize,
    required this.polygonPoints,
    this.isEditing = false,
    this.plotName,
    this.plantType,
    this.specificPlant,
    this.waterSource,
  }) : super(key: key);

  @override
  _PlantSelectionScreenState createState() => _PlantSelectionScreenState();
}

class _PlantSelectionScreenState extends State<PlantSelectionScreen> {
  late String selectedPlantType;
  late String selectedSpecificPlant;
  late String selectedWaterSource;
  late TextEditingController _plotNameController;
  int currentStep = 0;

  @override
  void initState() {
    super.initState();
    selectedPlantType = widget.plantType ?? '';
    selectedSpecificPlant = widget.specificPlant ?? '';
    selectedWaterSource = widget.waterSource ?? '';
    _plotNameController = TextEditingController(text: widget.plotName ?? 'แปลงปลูกใหม่');
  }

  @override
  void dispose() {
    _plotNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'แก้ไขข้อมูลแปลง' : 'เพิ่มแปลงใหม่'),
        backgroundColor: Color(0xFF34D396),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                _buildStepIndicator(0, 'ชื่อแปลง'),
                Expanded(child: Container(height: 2, color: currentStep > 0 ? Color(0xFF34D396) : Colors.grey[300])),
                _buildStepIndicator(1, 'ชนิดพืช'),
                Expanded(child: Container(height: 2, color: currentStep > 1 ? Color(0xFF34D396) : Colors.grey[300])),
                _buildStepIndicator(2, 'แหล่งน้ำ'),
              ],
            ),
          ),

          // Area info card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF34D396), Color(0xFF25624B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF34D396).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.crop_square, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พื้นที่แปลงปลูก',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '${widget.areaSize.toStringAsFixed(2)} ไร่',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Step content
          Expanded(
            child: _buildStepContent(),
          ),

          // Navigation buttons
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentStep > 0) {
                        setState(() {
                          currentStep--;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      currentStep == 0 ? 'ยกเลิก' : 'ย้อนกลับ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentStep < 2) {
                        if (_validateCurrentStep()) {
                          setState(() {
                            currentStep++;
                          });
                        }
                      } else {
                        _saveData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34D396),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      currentStep == 2 ? 'บันทึกข้อมูล' : 'ถัดไป',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    bool isActive = currentStep >= step;
    bool isCurrent = currentStep == step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Color(0xFF34D396) : Colors.grey[300],
            border: isCurrent ? Border.all(color: Color(0xFF34D396), width: 3) : null,
          ),
          child: Center(
            child: isActive && step < currentStep
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Color(0xFF25624B) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        if (_plotNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('กรุณาระบุชื่อแปลง')),
          );
          return false;
        }
        return true;
      case 1:
        if (selectedPlantType.isEmpty || selectedSpecificPlant.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('กรุณาเลือกประเภทและชนิดพืช')),
          );
          return false;
        }
        return true;
      case 2:
        if (selectedWaterSource.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('กรุณาเลือกแหล่งน้ำ')),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildPlotNameInput();
      case 1:
        return _buildPlantTypeSelection();
      case 2:
        return _buildWaterSourceSelection();
      default:
        return Container();
    }
  }

  Widget _buildPlotNameInput() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตั้งชื่อแปลงปลูก',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF25624B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ชื่อที่ดีจะช่วยให้คุณจดจำและจัดการแปลงได้ง่ายขึ้น',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _plotNameController,
              style: TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'เช่น แปลงข้าวหลังบ้าน, แปลงผักสวนครัว',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(20),
                prefixIcon: Container(
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF34D396).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.eco, color: Color(0xFF34D396)),
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF34D396).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Color(0xFF34D396)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'แนะนำ: ใช้ชื่อที่บอกตำแหน่ง ขนาด หรือชนิดพืชที่ปลูก เพื่อให้ง่ายต่อการจดจำ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF25624B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTypeSelection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกประเภทพืชที่ปลูก',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF25624B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เลือกประเภทพืชหลักที่คุณจะปลูกในแปลงนี้',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),

          // Plant type selection
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildPlantTypeItem('พืชไร่', Icons.grass, 'ข้าว ข้าวโพด อ้อย'),
              _buildPlantTypeItem('พืชสวน', Icons.spa, 'กล้วย มะพร้าว กาแฟ'),
              _buildPlantTypeItem('ผลไม้', Icons.emoji_food_beverage, 'ทุเรียน มะม่วง ลำไย'),
              _buildPlantTypeItem('พืชผัก', Icons.emoji_nature, 'ผักคะน้า มะเขือ พริก'),
            ],
          ),

          // Specific plant selection
          if (selectedPlantType.isNotEmpty) ...[
            SizedBox(height: 32),
            Text(
              'เลือกชนิด${selectedPlantType}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25624B),
              ),
            ),
            SizedBox(height: 16),
            ..._getPlantOptionsByType(selectedPlantType).map((plant) =>
                _buildPlantOption(plant)
            ).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlantTypeItem(String label, IconData icon, String examples) {
    bool isSelected = selectedPlantType == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlantType = label;
          selectedSpecificPlant = '';
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFF34D396) : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Color(0xFF34D396).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF34D396) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Color(0xFF34D396) : Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                examples,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF34D396),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantOption(String plant) {
    bool isSelected = selectedSpecificPlant == plant;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedSpecificPlant = plant;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Color(0xFF34D396) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF34D396) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      plant[0],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    plant,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Color(0xFF34D396) : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF34D396),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterSourceSelection() {
    List<Map<String, dynamic>> waterSources = [
      {'title': 'น้ำฝน', 'icon': Icons.cloud, 'desc': 'ใช้น้ำฝนธรรมชาติ'},
      {'title': 'น้ำบาดาล', 'icon': Icons.format_color_fill, 'desc': 'ขุดบ่อบาดาล'},
      {'title': 'ขุดสระ', 'icon': Icons.water, 'desc': 'สร้างสระเก็บน้ำ'},
      {'title': 'แหล่งน้ำธรรมชาติ', 'icon': Icons.landscape, 'desc': 'แม่น้ำ ลำธาร'},
      {'title': 'น้ำชลประทาน', 'icon': Icons.waves, 'desc': 'ระบบชลประทาน'},
      {'title': 'น้ำประปา', 'icon': Icons.water_drop, 'desc': 'น้ำประปาหมู่บ้าน'},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกแหล่งน้ำที่ใช้ปลูก',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF25624B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เลือกแหล่งน้ำหลักที่ใช้ในการปลูกพืชของคุณ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: waterSources.length,
            itemBuilder: (context, index) {
              final source = waterSources[index];
              bool isSelected = selectedWaterSource == source['title'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedWaterSource = source['title'];
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Color(0xFF34D396) : Colors.grey[300]!,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? Color(0xFF34D396).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        blurRadius: isSelected ? 12 : 6,
                        offset: Offset(0, isSelected ? 6 : 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF34D396) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            source['icon'],
                            size: 28,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          source['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Color(0xFF34D396) : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          source['desc'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected) ...[
                          SizedBox(height: 8),
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF34D396),
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF34D396).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF34D396)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ข้อมูลแหล่งน้ำจะช่วยในการวางแผนการปลูกและการดูแลรักษา',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF25624B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getPlantOptionsByType(String type) {
    switch (type) {
      case 'พืชไร่':
        return ['ข้าว', 'ข้าวโพด', 'อ้อย', 'มันสำปะหลัง', 'ถั่วเหลือง'];
      case 'พืชสวน':
        return ['กล้วย', 'มะพร้าว', 'กาแฟ', 'ยางพารา', 'ปาล์มน้ำมัน'];
      case 'ผลไม้':
        return ['ทุเรียน', 'มะม่วง', 'ลำไย', 'ส้ม', 'มังคุด', 'ลิ้นจี่'];
      case 'พืชผัก':
        return ['ผักคะน้า', 'ผักกวางตุ้ง', 'ผักบุ้ง', 'มะเขือเทศ', 'พริก', 'แตงกวา'];
      default:
        return [];
    }
  }

  void _saveData() {
    String plotName = _plotNameController.text.trim();

    if (plotName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาระบุชื่อแปลง'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        currentStep = 0;
      });
      return;
    }

    if (selectedPlantType.isEmpty || selectedSpecificPlant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกประเภทและชนิดพืช'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        currentStep = 1;
      });
      return;
    }

    if (selectedWaterSource.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกแหล่งน้ำ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // สร้างข้อมูลแปลงปลูก
    final plotInfo = PlotInfo(
      name: plotName,
      area: widget.areaSize,
      polygonPoints: widget.polygonPoints,
      plantType: selectedPlantType,
      specificPlant: selectedSpecificPlant,
      waterSource: selectedWaterSource,
    );

    // แสดงข้อความแจ้งเตือนการบันทึกสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'บันทึกข้อมูลแปลง "$plotName" เรียบร้อยแล้ว',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF34D396),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // ส่งข้อมูลกลับไปยังหน้าที่เรียก
    Navigator.pop(context, plotInfo);
  }
}

// เพิ่ม IconData helper function ที่หายไป
IconData _getIconForPlantType(String type) {
  switch (type) {
    case 'พืชไร่':
      return Icons.grass;
    case 'พืชสวน':
      return Icons.spa;
    case 'ผลไม้':
      return Icons.emoji_food_beverage;
    case 'พืชผัก':
      return Icons.emoji_nature;
    default:
      return Icons.eco;
  }
}