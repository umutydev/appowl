class Place {
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String openTime; // Örn: "08:00"
  final String closeTime; // Örn: "23:00"
  final bool isPharmacyOnDuty; // Sadece eczaneler için nöbet durumu

  Place({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    this.isPharmacyOnDuty = false,
  });

  // Zaman Mantığı: Mekan şu an açık mı?
  bool get isOpenNow {
    if (isPharmacyOnDuty) return true; // Nöbetçi eczane her zaman açık

    final now = DateTime.now();
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Basit bir string karşılaştırması: "08:00" < "14:30" < "23:00"
    return currentTime.compareTo(openTime) >= 0 &&
        currentTime.compareTo(closeTime) <= 0;
  }
}
