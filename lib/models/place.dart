class Place {
  final String id; // 🦉 BENZERSİZ KİMLİK (Senin eklediğin)
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final bool isOpenNow;
  final String address; // 🦉 ADRES (Senin güncellediğin)
  final String? liveStatus;

  // 💎 PREMIUM TASARIM İÇİN EKLENENLER (Bunları UI için mecburen koruyoruz)
  final String? photoReference;
  final double? rating;
  final int? userRatingsTotal;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.isOpenNow,
    required this.address,
    this.liveStatus,
    this.photoReference,
    this.rating,
    this.userRatingsTotal,
  });

  factory Place.fromJson(Map<String, dynamic> json, String category) {
    final geometry = json['geometry'] != null
        ? json['geometry']['location']
        : null;

    // Fotoğraf referansını Google'dan yakalıyoruz
    String? photoRef;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoRef = json['photos'][0]['photo_reference'];
    }

    return Place(
      id: json['place_id'] ?? json['name'] ?? '',
      name: json['name'] ?? 'Bilinmeyen Mekan',
      category: category,
      latitude: geometry != null ? geometry['lat'].toDouble() : 0.0,
      longitude: geometry != null ? geometry['lng'].toDouble() : 0.0,
      isOpenNow: json['opening_hours'] != null
          ? (json['opening_hours']['open_now'] ?? false)
          : false,
      address:
          json['vicinity'] ?? json['formatted_address'] ?? 'Adres bulunamadı',
      liveStatus: json['liveStatus'],
      photoReference: photoRef,
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
    );
  }
}
