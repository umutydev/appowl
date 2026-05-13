import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place.dart';
import '../data/history_service.dart';
import '../data/report_service.dart';
import '../data/map_utils.dart';
import '../widgets/modern_place_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _showReportSheet(BuildContext context, String placeId) {
    final List<String> reportOptions = [
      "Bu mekan kapandı",
      "Mekan taşınmış",
      "Burası çok kalabalık",
      "Polis çevirmesi var",
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: reportOptions
              .map(
                (option) => ListTile(
                  leading: const Icon(
                    Icons.campaign,
                    color: Colors.orangeAccent,
                  ),
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    await ReportService.sendReport(placeId, option);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Bildirimin iletildi 🦉"),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Ziyaret Geçmişim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(
              child: Text(
                "Geçmişini görmek için giriş yapmalısın 🦉",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : StreamBuilder<List<Place>>(
              stream: HistoryService.getHistory(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(
                    child: Text(
                      "Hata: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  );
                }

                final places = snapshot.data ?? [];

                if (places.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'Henüz bir yere gitmemişsin 🦉',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    return ModernPlaceCard(
                      place: places[index],
                      onReportTap: () =>
                          _showReportSheet(context, places[index].id),
                      onDirectionsTap: () => MapUtils.openMap(
                        places[index].latitude,
                        places[index].longitude,
                        places[index].name,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
