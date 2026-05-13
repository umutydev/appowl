import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/place.dart';

class HistoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference? _userHistoryRef() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid).collection('history');
  }

  static Stream<bool> hasVisited(String placeId) {
    final ref = _userHistoryRef();
    if (ref == null) return Stream.value(false);
    return ref.doc(placeId).snapshots().map((snap) => snap.exists);
  }

  // 🦉 ARTIK TIKLAYINCA EKLİYOR, TEKRAR TIKLAYINCA ÇIKARIYOR (Tıpkı Kalp Gibi)
  static Future<void> toggleHistory(Place place, BuildContext context) async {
    final ref = _userHistoryRef();
    if (ref == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçmişe eklemek için giriş yapmalısın 🦉'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    try {
      final docRef = ref.doc(place.id);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        // Varsa geçmişten sil
        await docRef.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçmişten silindi 🗑️'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Yoksa geçmişe ekle
        await docRef.set({
          'id': place.id,
          'name': place.name,
          'category': place.category,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'isOpenNow': place.isOpenNow,
          'address': place.address,
          'photoReference': place.photoReference,
          'rating': place.rating,
          'userRatingsTotal': place.userRatingsTotal,
          'visitedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ziyaret geçmişine eklendi!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Stream<List<Place>> getHistory() {
    final ref = _userHistoryRef();
    if (ref == null) return Stream.value([]);

    return ref.orderBy('visitedAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return Place(
          id: data['id'] ?? '',
          name: data['name'] ?? 'Bilinmeyen',
          category: data['category'] ?? '',
          latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
          isOpenNow: data['isOpenNow'] ?? false,
          address: data['address'] ?? '',
          photoReference: data['photoReference'],
          rating: data['rating'] != null
              ? (data['rating'] as num).toDouble()
              : null,
          userRatingsTotal: data['userRatingsTotal'],
        );
      }).toList();
    });
  }
}
