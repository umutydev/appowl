import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../data/places_service.dart';
import '../models/place.dart'; // Mekan verilerini tanımak için ekledik

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  String _activeCategory = "";
  Position? _myPosition; // Senin anlık konumunu burada tutacağız

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
    _initLocation(); // Harita yüklenirken konumumuzu bul
  }

  // İlk açılışta kendi konumumuzu bulup mavi işaretçiyi diken fonksiyon
  Future<void> _initLocation() async {
    try {
      var pos = await _getCurrentLocation();
      setState(() {
        _myPosition = pos;
        _updateMarkers(
          [],
        ); // İçeriği boş gönderip sadece kendimizi çizdiriyoruz
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
      if (permission == LocationPermission.denied) {
        return Future.error('İzin reddedildi.');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  // HEM BİZİ MAVİ, HEM MEKANLARI KIRMIZI YAPAN ANA MERKEZ
  void _updateMarkers(List<Place> places) {
    Set<Marker> newMarkers = {};

    // 1. Bizim Konumumuz (Sadece MAVİ İşaretçi)
    if (_myPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(_myPosition!.latitude, _myPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Buradasın 🦉',
            snippet: 'Owl Merkez',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ), // MAVİ RENK
          zIndex: 999, // Kalabalıkta bile bizim noktamız hep en üstte dursun
        ),
      );
    }

    // 2. Çevredeki Mekanlar (Hepsi KIRMIZI)
    for (var place in places) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(place.id ?? place.name),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.isOpenNow == true
                ? "Şu an açık"
                : "Saat bilgisi yok",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ), // KIRMIZI RENK
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  // Sekmelere tıklandığında çalışan fonksiyon
  Future<void> _fetchCategoryMarkers(String category) async {
    setState(() {
      _activeCategory = category;
    });

    // İnternetten yüklenirken ekrandaki eski kırmızıları sil, sadece bizim mavi nokta kalsın
    _updateMarkers([]);

    try {
      final places = await PlacesService.fetchNearbyPlaces(category);
      _updateMarkers(places); // Yeni kırmızı mekanları haritaya bas
    } catch (e) {
      debugPrint("İşaretçiler yüklenirken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(40.8248, 29.3735), // Varsayılan konum
            zoom: 14.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;

            // Eğer init işleminde konumu bulduysak kamerayı oraya kaydır
            if (_myPosition != null) {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(_myPosition!.latitude, _myPosition!.longitude),
                  15.0,
                ),
              );
            } else {
              // Bulamadıysak tekrar dene
              try {
                var pos = await _getCurrentLocation();
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(pos.latitude, pos.longitude),
                    15.0,
                  ),
                );
              } catch (e) {}
            }
          },
        ),
        // SOL ÜST SEKMELER
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
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    selected: isSelected,
                    onSelected: (bool value) {
                      _fetchCategoryMarkers(cat['name']);
                    },
                    backgroundColor: const Color(0xFF1E1E1E),
                    selectedColor: cat['color'],
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // SAĞ ALT KONUMUM BUTONU
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF1E1E1E),
            child: const Icon(Icons.my_location, color: Colors.orangeAccent),
            onPressed: () async {
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
