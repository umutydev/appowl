import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Set<Marker> _markers = {};
  List<Place> _currentCategoryPlaces = [];
  String _activeCategory = "";
  Position? _myPosition;

  StreamSubscription<QuerySnapshot>? _reportSubscription;

  // 🦉 EMOJİ İKONLARI
  BitmapDescriptor? _policeIcon;
  BitmapDescriptor? _radarIcon;
  final Map<String, BitmapDescriptor> _categoryIcons = {};

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Eczane',
      'icon': Icons.local_pharmacy,
      'color': Colors.redAccent,
      'emoji': '💊',
    },
    {
      'name': 'Restoran',
      'icon': Icons.restaurant,
      'color': Colors.orange,
      'emoji': '🍔',
    },
    {
      'name': 'Market',
      'icon': Icons.shopping_basket,
      'color': Colors.amber,
      'emoji': '🛒',
    },
    {
      'name': 'Hastane',
      'icon': Icons.local_hospital,
      'color': Colors.blue,
      'emoji': '🏥',
    },
    {
      'name': 'Taksi',
      'icon': Icons.local_taxi,
      'color': Colors.orangeAccent,
      'emoji': '🚕',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcons();
    _initLocation();
  }

  @override
  void dispose() {
    _reportSubscription?.cancel();
    super.dispose();
  }

  // 🦉 İKONLARI HAZIRLAYAN FONKSİYON
  Future<void> _loadCustomMarkerIcons() async {
    try {
      // 🚨 DİREKT EMOJİLER TANIMLANDI
      _policeIcon = await _getMarkerIconFromEmoji("👮");
      _radarIcon = await _getMarkerIconFromEmoji("📸");

      for (var cat in _categories) {
        _categoryIcons[cat['name']] = await _getMarkerIconFromEmoji(
          cat['emoji'],
        );
      }

      if (mounted)
        setState(() {
          _refreshMarkers();
        });
    } catch (e) {
      debugPrint("Emoji yükleme hatası: $e");
    }
  }

  // 🚨 WEB KORUMASI SİLİNDİ, DİREKT EMOJİ ÇİZİLECEK
  Future<BitmapDescriptor> _getMarkerIconFromEmoji(String emoji) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      const double size = 110.0;

      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 75),
      );
      painter.layout();

      painter.paint(
        canvas,
        Offset((size - painter.width) / 2, (size - painter.height) / 2),
      );

      final img = await pictureRecorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
      final data = await img.toByteData(format: ui.ImageByteFormat.png);

      if (data == null) return BitmapDescriptor.defaultMarker;
      return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
    } catch (e) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _myPosition = pos;
          _refreshMarkers();
        });
      }
    } catch (e) {
      debugPrint("Konum hatası: $e");
    }
  }

  void _refreshMarkers() {
    Set<Marker> newMarkers = {};

    if (_myPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(_myPosition!.latitude, _myPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          zIndex: 999,
          infoWindow: const InfoWindow(title: "Buradasın 🦉"),
        ),
      );
    }

    BitmapDescriptor placeIcon =
        _categoryIcons[_activeCategory] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    for (var place in _currentCategoryPlaces) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude, place.longitude),
          icon: placeIcon,
          onTap: () {
            _showPlaceBottomSheet(place);
          },
        ),
      );
    }
    _listenAndAddMapReports(newMarkers);
  }

  void _listenAndAddMapReports(Set<Marker> markersToUpdate) {
    _reportSubscription?.cancel();

    _reportSubscription = ReportService.getMapReports().listen((snapshot) {
      try {
        DateTime now = DateTime.now().toUtc();
        Set<Marker> liveMarkers = Set.from(markersToUpdate);

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['expiresAt'] == null) continue;

          DateTime expireTime = DateTime.parse(data['expiresAt']).toUtc();
          int votes = data['votes'] ?? 0;

          if (expireTime.isAfter(now)) {
            bool isPolice = data['type'] == 'Polis';

            // 🚨 EMOJİLER KULLANILIYOR
            BitmapDescriptor safeIcon = isPolice
                ? (_policeIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ))
                : (_radarIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueYellow,
                      ));

            liveMarkers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['latitude'], data['longitude']),
                icon: safeIcon,
                onTap: () {
                  _showReportBottomSheet(doc.id, isPolice, votes);
                },
              ),
            );
          }
        }
        if (mounted)
          setState(() {
            _markers = liveMarkers;
          });
      } catch (e) {
        debugPrint("Dinleyici Hatası: $e");
      }
    });
  }

  void _showPlaceBottomSheet(Place place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: place.isOpenNow
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  place.isOpenNow ? "Şu an Açık" : "Şu an Kapalı",
                  style: TextStyle(
                    color: place.isOpenNow
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              place.address,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showReportBottomSheet(String reportId, bool isPolice, int votes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border(top: BorderSide(color: Colors.orangeAccent, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPolice ? "👮 Polis Çevirmesi" : "📸 Radar Var",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Bu ihbar $votes kişi tarafından doğrulandı.",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  await ReportService.upvoteMapReport(reportId);
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Doğrulaman alındı kanka, sağ ol! 🦉",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                },
                child: const Text(
                  "EVET, BURADA! (DOĞRULA)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text(
                "İptal (Kapat)",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCategoryMarkers(String category) async {
    setState(() {
      _activeCategory = category;
    });
    try {
      final places = await PlacesService.fetchNearbyPlaces(category);
      if (mounted)
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
      builder: (dialogContext) => AlertDialog(
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
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
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
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text(
              "📸 Radar",
              style: TextStyle(color: Colors.yellowAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
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
          onLongPress: (LatLng pos) => _showReportDialog(pos),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
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
                    label: Text(cat['name'] + " " + cat['emoji']),
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
