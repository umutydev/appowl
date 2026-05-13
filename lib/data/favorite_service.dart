import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/place.dart';

class FavoriteService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference? _userFavoritesRef() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid).collection('favorites');
  }

  static Stream<bool> isFavorite(String placeId) {
    final ref = _userFavoritesRef();
    if (ref == null)
      return Stream.value(false); // Kullanıcı yoksa kalp boş dönsün
    return ref.doc(placeId).snapshots().map((snap) => snap.exists);
  }

  static Future<void> toggleFavorite(Place place, BuildContext context) async {
    final user = _auth.currentUser;

    // 1. KONTROL: Kullanıcı giriş yapmış mı?
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favori eklemek için giriş yapmalısın! 🦉'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    try {
      final ref = _db.collection('users').doc(user.uid).collection('favorites');
      final docRef = ref.doc(place.id);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favorilerden çıkarıldı 💔'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
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
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favorilere eklendi ❤️'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // 2. KONTROL: Firebase veritabanı izni (Rules) kapalıysa hatayı ekrana bas!
      debugPrint("Favori Hatası: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: Firebase izinlerini kontrol et! ($e)'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Stream<List<Place>> getFavorites() {
    final ref = _userFavoritesRef();
    // 3. KONTROL: Kullanıcı yoksa sonsuz dönmemesi için boş liste yolla
    if (ref == null) return Stream.value([]);

    return ref.orderBy('addedAt', descending: true).snapshots().map((snap) {
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
