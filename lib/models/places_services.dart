import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class PlacesService {
  // BURAYA KENDİ GOOGLE API ANAHTARINI YAPIŞTIR
  static const String apiKey = "AIzaSyDeJyj39Y57g-0TPLUIIcBJGa70V__NRkI";

  // Kategorilere (Eczane, Restoran) göre arama
  static Future<List<Place>> fetchNearbyPlaces(String category) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String type = '';
      if (category.contains("Eczane"))
        type = "pharmacy";
      else if (category.contains("Restoran"))
        type = "restaurant";
      else if (category.contains("Taksi"))
        type = "taxi_stand";
      else
        type = "store";

      final String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${pos.latitude},${pos.longitude}&radius=2500&type=$type&key=$apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        return results.map((json) => Place.fromJson(json, category)).toList();
      }
      return [];
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }

  // Arama çubuğu için metin araması (Google Text Search)
  static Future<List<Place>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final String url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&location=${pos.latitude},${pos.longitude}&radius=5000&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];
        return results.map((json) => Place.fromJson(json, "Arama")).toList();
      }
      return [];
    } catch (e) {
      print("Arama Hatası: $e");
      return [];
    }
  }
}
