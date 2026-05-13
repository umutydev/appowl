import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:custom_info_window/custom_info_window.dart'; // 🦉 ÖZEL PENCERE PAKETİ
import '../data/places_service.dart';
import '../models/place.dart';
import '../data/report_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  // 🦉 ÖZEL PENCERE KONTROLCÜSÜ
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  Set<Marker> _markers = {};
  List<Place> _currentCategoryPlaces = [];
  String _activeCategory = "";
  Position? _myPosition;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Eczane', 'icon': Icons.local_pharmacy, 'color': Colors.redAccent},
    {'name': 'Restoran', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': 'Market', 'icon': Icons.shopping_basket, 'color': Colors.amber},
    {'name': 'Hastane', 'icon': Icons.local_hospital, 'color': Colors.blue},
    {'name': 'Taksi', 'icon': Icons.local_taxi, 'color': Colors.orangeAccent},
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose(); // 🦉 Hafıza temizliği
    super.dispose();
  }

  Future<BitmapDescriptor> _getMarkerIconFromEmoji(String emoji) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 80.0;

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(text: emoji, style: const TextStyle(fontSize: 60));

    painter.layout();
    painter.paint(canvas, const Offset(0, 0));

    final img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _initLocation() async {
    try {
      var pos = await _getCurrentLocation();
      setState(() {
        _myPosition = pos;
        _refreshMarkers();
      });
    } catch (e) {
      debugPrint("Konum hatası: $e");
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Konum servisi kapalı.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('İzin reddedildi.');
    }
    return await Geolocator.getCurrentPosition();
  }

  void _refreshMarkers() {
    Set<Marker> newMarkers = {};

    if (_myPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(_myPosition!.latitude, _myPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          zIndex: 999,
          // 🦉 InfoWindow SİLİNDİ, ÖZEL PENCERE BAĞLANDI
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              _buildSimplePopup("Buradasın 🦉", "Konumun aktif ve güncel."),
              LatLng(_myPosition!.latitude, _myPosition!.longitude),
            );
          },
        ),
      );
    }

    for (var place in _currentCategoryPlaces) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          // 🦉 InfoWindow SİLİNDİ, ÖZEL PENCERE BAĞLANDI
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              _buildModernPopupCard(place),
              LatLng(place.latitude, place.longitude),
            );
          },
        ),
      );
    }

    _listenAndAddMapReports(newMarkers);
  }

  // 🦉 MEKANLAR İÇİN MODERN POPUP TASARIMI
  Widget _buildModernPopupCard(Place place) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.orangeAccent,
                size: 25,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.isOpenNow ? "● Şu an Açık" : "○ Şu an Kapalı",
                    style: TextStyle(
                      color: place.isOpenNow
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePopup(String title, String snippet) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            snippet,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _listenAndAddMapReports(Set<Marker> markersToUpdate) {
    ReportService.getMapReports().listen((snapshot) async {
      DateTime now = DateTime.now().toUtc();
      Set<Marker> liveMarkers = Set.from(markersToUpdate);

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime expireTime = DateTime.parse(data['expiresAt']).toUtc();
        int votes = data['votes'] ?? 0;

        if (expireTime.isAfter(now)) {
          bool isPolice = data['type'] == 'Polis';
          String emojiString = isPolice ? "👮" : "📸";
          BitmapDescriptor emojiIcon = await _getMarkerIconFromEmoji(
            emojiString,
          );

          liveMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['latitude'], data['longitude']),
              icon: emojiIcon,
              // 🦉 InfoWindow SİLİNDİ, ÖZEL PENCERE BAĞLANDI
              onTap: () {
                _customInfoWindowController.addInfoWindow!(
                  _buildReportPopup(doc.id, isPolice, votes),
                  LatLng(data['latitude'], data['longitude']),
                );
              },
            ),
          );
        }
      }
      if (mounted)
        setState(() {
          _markers = liveMarkers;
        });
    });
  }

  Widget _buildReportPopup(String reportId, bool isPolice, int votes) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isPolice ? "👮 Polis Çevirmesi" : "📸 Radar Var",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            "Doğrulama: $votes",
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          const SizedBox(height: 5),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(80, 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _showUpvoteDialog(reportId),
            child: const Text(
              "DOĞRULA",
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpvoteDialog(String reportId) {
    _customInfoWindowController.hideInfoWindow!();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "İhbarı Doğrula 🦉",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Bu bilginin doğruluğunu onaylıyor musun?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hayır"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await ReportService.upvoteMapReport(reportId);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Teşekkürler, ihbar doğrulandı!")),
              );
            },
            child: const Text("Evet, Doğru"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCategoryMarkers(String category) async {
    setState(() {
      _activeCategory = category;
    });
    try {
      final places = await PlacesService.fetchNearbyPlaces(category);
      setState(() {
        _currentCategoryPlaces = places;
        _refreshMarkers();
      });
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }

  void _showReportDialog(LatLng pos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Haritaya Ekle 📢",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Bu noktada ne var?",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ReportService.addMapReport(
                pos.latitude,
                pos.longitude,
                "Polis",
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              "👮 Polis",
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ReportService.addMapReport(
                pos.latitude,
                pos.longitude,
                "Radar",
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              "📸 Radar",
              style: TextStyle(color: Colors.yellowAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(40.8248, 29.3735),
            zoom: 14.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _markers,
          // 🦉 HARİTA BOŞLUĞUNA BASINCA POPUP KAPANSIN
          onTap: (position) {
            _customInfoWindowController.hideInfoWindow!();
          },
          // 🦉 KAMERA HAREKET EDERKEN POPUP TAKİP ETSİN
          onCameraMove: (position) {
            _customInfoWindowController.onCameraMove!();
          },
          onLongPress: (LatLng pos) => _showReportDialog(pos),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // 🦉 KONTROLCÜYÜ BURADA BAĞLIYORUZ
            _customInfoWindowController.googleMapController = controller;
            if (_myPosition != null) {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_myPosition!.latitude, _myPosition!.longitude),
                  15.0,
                ),
              );
            }
          },
        ),

        // 🦉 SİHİRLİ KATMAN BURADA (Marker'ların hemen üstünde)
        CustomInfoWindow(
          controller: _customInfoWindowController,
          height: 85,
          width: 240,
          offset: 55,
        ),

        Positioned(
          top: 50,
          left: 10,
          right: 10,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                bool isSelected = _activeCategory == cat['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat['name']),
                    selected: isSelected,
                    onSelected: (val) => _fetchCategoryMarkers(cat['name']),
                    backgroundColor: const Color(0xFF1E1E1E),
                    selectedColor: cat['color'],
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF1E1E1E),
            child: const Icon(Icons.my_location, color: Colors.orangeAccent),
            onPressed: () {
              if (_myPosition != null) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_myPosition!.latitude, _myPosition!.longitude),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
