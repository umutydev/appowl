import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🦉 1. Mekan Bildirimi Gönder (Market kapalı, Eczane taşınmış vs.)
  static Future<void> sendReport(String placeId, String status) async {
    await _db.collection('reports').doc(placeId).set({
      'status': status,
      'votes': 0, // İlk başta 0 oy ile başlar
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 🦉 2. Mekan Bildirimine OY VER (Upvote)
  static Future<void> upvotePlaceReport(String placeId) async {
    await _db.collection('reports').doc(placeId).update({
      'votes': FieldValue.increment(1),
    });
  }

  static Stream<DocumentSnapshot> getLiveStatus(String placeId) {
    return _db.collection('reports').doc(placeId).snapshots();
  }

  // 🦉 3. Haritaya Polis/Radar Ekle (1 Saat Ömürlü & UTC Ayarlı)
  static Future<void> addMapReport(double lat, double lng, String type) async {
    // 💡 .toUtc() kullanarak evrensel saatle kaydediyoruz.
    // Bu sayede uygulama kapansa da zaman hesabı şaşmaz.
    DateTime expireTime = DateTime.now().add(const Duration(hours: 1)).toUtc();

    await _db.collection('map_reports').add({
      'type': type,
      'latitude': lat,
      'longitude': lng,
      'votes': 0,
      'expiresAt': expireTime
          .toIso8601String(), // 1 saat sonraki UTC vaktini yazar
      'timestamp':
          FieldValue.serverTimestamp(), // Kayıt anındaki sunucu vaktini tutar
    });
  }

  // 🦉 4. Harita Raporuna OY VER (Polis/Radar Doğrulama)
  static Future<void> upvoteMapReport(String reportId) async {
    await _db.collection('map_reports').doc(reportId).update({
      'votes': FieldValue.increment(1),
    });
  }

  // Haritadaki tüm canlı raporları dinleyen Stream
  static Stream<QuerySnapshot> getMapReports() {
    return _db.collection('map_reports').snapshots();
  }
}
