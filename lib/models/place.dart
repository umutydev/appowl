class Place {
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final bool isOpenNow;
  final String address; // Google'dan mekanın açık adresini de alacağız

  Place({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.isOpenNow,
    required this.address,
  });

  // Gelen karmaşık Google JSON verisini bizim modele çeviren fabrika
  factory Place.fromJson(Map<String, dynamic> json, String categoryName) {
    return Place(
      name: json['name'] ?? 'Bilinmeyen Mekan',
      category: categoryName,
      latitude: json['geometry']['location']['lat'],
      longitude: json['geometry']['location']['lng'],
      // Eğer Google saat bilgisi vermediyse varsayılan olarak açık gösterelim
      isOpenNow: json['opening_hours'] != null
          ? json['opening_hours']['open_now']
          : true,
      address: json['vicinity'] ?? 'Adres bulunamadı',
    );
  }
}
