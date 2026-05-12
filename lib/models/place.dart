class Place {
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final bool isOpenNow;
  final String address;

  Place({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.isOpenNow,
    required this.address,
  });

  factory Place.fromJson(Map<String, dynamic> json, String categoryName) {
    return Place(
      name: json['name'] ?? 'Bilinmeyen Mekan',
      category: categoryName,
      latitude: json['geometry']['location']['lat'],
      longitude: json['geometry']['location']['lng'],
      // Google opening_hours vermezse varsayılan olarak açık kabul ediyoruz
      isOpenNow: json['opening_hours'] != null
          ? json['opening_hours']['open_now']
          : true,
      address:
          json['vicinity'] ?? 'Adres Verileri Yükleniyor...', //Düzeltilecek
    );
  }

  String? get id => null;
}
