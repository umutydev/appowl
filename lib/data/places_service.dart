import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class PlacesService {
  // API ANAHTARIN
  static const String apiKey = "AIzaSyD3P98B7U8QlZx0xo9R5M6arOlrekWfsxQ";

  static Future<List<Place>> fetchNearbyPlaces(String category) async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String type = '';
      String keyword = '';
      bool requireOpen =
          true; // Owl Gece Rehberi olduğu için varsayılan olarak açık yerleri isteyelim

      String lowerCat = category.toLowerCase();

      if (lowerCat.contains("eczane")) {
        type = "pharmacy";
        keyword = "eczane";
      } else if (lowerCat.contains("restoran")) {
        type = "restaurant";
        keyword = "";
      } else if (lowerCat.contains("tekel")) {
        type = "liquor_store";
        keyword = "tekel";
      } else if (lowerCat.contains("taksi")) {
        type = "taxi_stand";
        keyword = "taksi";
        requireOpen =
            false; // Taksilerin çalışma saatleri API'de girilmez, açık zorunluluğunu kaldır.
      } else if (lowerCat.contains("market")) {
        type = "convenience_store";
        keyword = "market";
      } else if (lowerCat.contains("hastane")) {
        type = "hospital";
        keyword = "";
        requireOpen =
            false; // Hastaneler için açık olma şartını kaldır, zaten 7/24'tür.
      } else {
        keyword = category.replaceAll('\n', ' ');
        requireOpen = false;
      }

      // Dinamik URL oluşturma
      String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${pos.latitude},${pos.longitude}&radius=5000&key=$apiKey&language=tr';

      if (type.isNotEmpty) url += '&type=$type';
      if (keyword.isNotEmpty) url += '&keyword=$keyword';
      if (requireOpen) url += '&opennow=true';

      print("🌐 Google'a Giden İstek: $url");

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
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&location=${pos.latitude},${pos.longitude}&radius=5000&key=$apiKey&language=tr';

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

  // ⏰ Belirli bir mekanın detaylı çalışma saatlerini çeken yepyeni fonksiyon
  static Future<List<String>> fetchPlaceHours(String placeId) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=opening_hours&key=$apiKey&language=tr';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['opening_hours'] != null) {
          // Gün gün saatleri liste olarak alıyoruz
          return List<String>.from(
            data['result']['opening_hours']['weekday_text'] ?? [],
          );
        }
      }
      return ["Saat bilgisi bulunamadı."];
    } catch (e) {
      print("Saat Hatası: $e");
      return ["Bağlantı hatası."];
    }
  }
}
