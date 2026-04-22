import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/places_service.dart';
import '../models/place.dart';
import '../data/places_service.dart';
import '../data/map_utils.dart'; // MapUtils kuryemizi unutma

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu arka plan
      appBar: AppBar(
        title: const Text(
          'Owl 🦉',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hızlı Erişim",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildCategoryCard(
                    context,
                    "Nöbetçi\nEczaneler",
                    Icons.local_pharmacy,
                    Colors.redAccent,
                  ),
                  _buildCategoryCard(
                    context,
                    "7/24 Açık\nMarket",
                    Icons.shopping_basket,
                    Colors.amber,
                  ),
                  _buildCategoryCard(
                    context,
                    "7/24 Açık\nRestoranlar",
                    Icons.restaurant,
                    Colors.orange,
                  ),
                  _buildCategoryCard(
                    context,
                    "7/24 Açık\nTekel",
                    Icons.liquor,
                    Colors.yellow,
                  ),
                  _buildCategoryCard(
                    context,
                    "Hastaneler",
                    Icons.local_hospital,
                    Colors.blue,
                  ),
                  _buildCategoryCard(
                    context,
                    "Taksi",
                    Icons.local_taxi,
                    Colors.orangeAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryDetailScreen(categoryName: title),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Kategori Detay Sayfası (Yol Tarifi Eklenmiş Hali) ---
class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(categoryName.replaceAll('\n', ' ')),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Place>>(
        future: PlacesService.fetchNearbyPlaces(categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Yakınlarda açık mekan bulunamadı. 🦉",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final places = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];

              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: place.isOpenNow
                        ? Colors.green.withOpacity(0.1)
                        : Colors.redAccent.withOpacity(0.1),
                    child: Icon(
                      Icons.location_on,
                      color: place.isOpenNow ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        place.isOpenNow ? "Şu an açık" : "Şu an kapalı",
                        style: TextStyle(
                          color: place.isOpenNow
                              ? Colors.green
                              : Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place.address,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Mavi Navigasyon İkonu
                  trailing: const Icon(
                    Icons.directions,
                    color: Colors.blueAccent,
                  ),
                  onTap: () {
                    // Tıklandığında telefonun haritasını açar
                    MapUtils.openMap(
                      place.latitude,
                      place.longitude,
                      place.name,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
