import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class MapUtils {
  MapUtils._();

  static Future<void> openMap(
    double latitude,
    double longitude,
    String destinationName,
  ) async {
    // Google Maps Yönlendirme URL'si (En garantisi budur)
    final String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=$destinationName";

    // Apple Haritalar (Sadece iOS için)
    final String appleMapsUrl =
        "https://maps.apple.com/?daddr=$latitude,$longitude&q=$destinationName";

    try {
      if (kIsWeb) {
        // Web'de (Chrome) direkt yeni sekmede Google Maps açar
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Mobilde cihazın işletim sistemine göre davranır
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await launchUrl(Uri.parse(appleMapsUrl));
        } else {
          await launchUrl(Uri.parse(googleMapsUrl));
        }
      }
    } catch (e) {
      print("Harita başlatılamadı: $e");
    }
  }
}
