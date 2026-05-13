import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';
import '../data/places_service.dart';
import '../data/report_service.dart';
import '../data/favorite_service.dart';
import '../data/history_service.dart';

class ModernPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onReportTap;
  final VoidCallback onDirectionsTap;

  const ModernPlaceCard({
    super.key,
    required this.place,
    required this.onReportTap,
    required this.onDirectionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = place.photoReference != null
        ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place.photoReference}&key=${PlacesService.apiKey}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📸 SOL KISIM: FOTOĞRAF VE KALP BUTONU
            SizedBox(
              width: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackIcon(),
                          )
                        : _buildFallbackIcon(),
                  ),

                  Positioned(
                    top: 8,
                    left: 8,
                    child: StreamBuilder<bool>(
                      stream: FavoriteService.isFavorite(place.id),
                      builder: (context, snapshot) {
                        bool isFavorite = snapshot.data ?? false;

                        return Material(
                          type: MaterialType.circle,
                          color: Colors.black.withOpacity(0.6),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              FavoriteService.toggleFavorite(place, context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite
                                    ? Colors.redAccent
                                    : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 📝 SAĞ KISIM: BİLGİLER VE BUTONLAR
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    if (place.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${place.rating} (${place.userRatingsTotal ?? 0})',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    Text(
                      place.address,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // 🦉 CANLI BİLDİRİM VE UPVOTE ALANI
                    StreamBuilder<DocumentSnapshot>(
                      stream: ReportService.getLiveStatus(place.id),
                      builder: (context, reportSnapshot) {
                        if (reportSnapshot.hasData &&
                            reportSnapshot.data!.exists) {
                          var reportData =
                              reportSnapshot.data!.data()
                                  as Map<String, dynamic>;
                          int votes = reportData['votes'] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withOpacity(
                                        0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "📢 ${reportData['status']} ($votes)",
                                      style: const TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () =>
                                      ReportService.upvotePlaceReport(place.id),
                                  child: const Icon(
                                    Icons.thumb_up_alt_outlined,
                                    color: Colors.orangeAccent,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const Spacer(),

                    // ALT SATIR: ROZET VE İKONLAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: place.isOpenNow
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: place.isOpenNow
                                  ? Colors.green
                                  : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            place.isOpenNow ? 'Şu an açık' : 'Şu an kapalı',
                            style: TextStyle(
                              color: place.isOpenNow
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // 🛠️ BUTONLAR GRUBU
                        Row(
                          children: [
                            // 1. ZİYARET EDİLDİ (TİK) BUTONU (🔥 YENİ)
                            StreamBuilder<bool>(
                              stream: HistoryService.hasVisited(place.id),
                              builder: (context, snapshot) {
                                bool hasVisited = snapshot.data ?? false;
                                return InkWell(
                                  onTap: () {
                                    HistoryService.toggleHistory(
                                      place,
                                      context,
                                    );
                                  },
                                  child: Icon(
                                    hasVisited
                                        ? Icons.check_circle
                                        : Icons.check_circle_outline,
                                    color: hasVisited
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                    size: 22,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),

                            // 2. SAATLER BUTONU
                            InkWell(
                              onTap: () async {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                );

                                List<String> hours =
                                    await PlacesService.fetchPlaceHours(
                                      place.id,
                                    );

                                if (!context.mounted) return;
                                Navigator.pop(context);

                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    title: const Text(
                                      "Çalışma Saatleri ⏰",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: hours
                                          .map(
                                            (h) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                  ),
                                              child: Text(
                                                h,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          "Kapat",
                                          style: TextStyle(
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.access_time_filled,
                                color: Colors.greenAccent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 3. BİLDİRİM BUTONU
                            InkWell(
                              onTap: onReportTap,
                              child: const Icon(
                                Icons.add_alert,
                                color: Colors.orangeAccent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 4. YOL TARİFİ BUTONU (Eski haline döndü)
                            InkWell(
                              onTap: onDirectionsTap,
                              child: const Icon(
                                Icons.directions,
                                color: Colors.blueAccent,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.storefront, color: Colors.grey, size: 40),
      ),
    );
  }
}
