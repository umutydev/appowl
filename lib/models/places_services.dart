import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class PlacesService {
  static const String apiKey =
      "AIzaSyDeJyj39Y57g-0TPLUIIcBJGa70V__NRkI"; // Şifreni buraya gir!

  static Future<List<Place>> fetchNearbyPlaces(String category) async {
    try {
      // 1. Önce kullanıcının anlık konumunu alalım (Haritada yaptığımızın aynısı)
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Tıklanan kategoriye göre Google'da ne arayacağımızı seçelim
      String type = '';
      if (category.contains("Eczane"))
        type = "pharmacy";
      else if (category.contains("Restoran"))
        type = "restaurant";
      else if (category.contains("Taksi"))
        type = "taxi_stand";
      else
        type = "store";

      // 3. Google'a atacağımız API isteği (2000 metre çapında arıyoruz)
      final String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${pos.latitude},${pos.longitude}&radius=2000&type=$type&key=$apiKey';

      // 4. İsteği gönder ve cevabı bekle
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'];

        // Gelen listeyi bizim Place modeline çevir
        return results.map((json) => Place.fromJson(json, category)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Hata oluştu: $e");
      return [];
    }
  }
}
