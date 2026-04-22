import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class PlacesService {
  // YENİ ALDIĞIN API ANAHTARINI BURAYA YAPIŞTIR
  static const String apiKey = "AIzaSyD3P98B7U8QlZx0xo9R5M6arOlrekWfsxQ";

  static Future<List<Place>> fetchNearbyPlaces(String category) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String keyword = '';
      String lowerCat = category.toLowerCase();

      if (lowerCat.contains("eczane"))
        keyword = "Eczane";
      else if (lowerCat.contains("restoran"))
        keyword = "Restoran";
      else if (lowerCat.contains("tekel"))
        keyword = "Tekel";
      else if (lowerCat.contains("taksi"))
        keyword = "Taksi";
      else if (lowerCat.contains("market"))
        keyword = "Market";
      else if (lowerCat.contains("hastane"))
        keyword = "Hastane";
      else
        keyword = category.replaceAll('\n', ' ');

      final String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${pos.latitude},${pos.longitude}&radius=5000&keyword=$keyword&key=$apiKey';

      print("🌐 Google'a Giden İstek: $keyword");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
          print("🚨 GOOGLE API HATASI: ${data['status']}");
        }

        final List results = data['results'] ?? [];
        return results.map((json) => Place.fromJson(json, category)).toList();
      }
      return [];
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return [];
    }
  }

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
        final List results = data['results'] ?? [];
        return results.map((json) => Place.fromJson(json, "Arama")).toList();
      }
      return [];
    } catch (e) {
      print("Arama Hatası: $e");
      return [];
    }
  }
}
