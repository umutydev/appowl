import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/places_services.dart';
import '../data/places_service.dart';
import '../models/place.dart';

// Kategori Detay Sayfası (Gerçek Verili Hali)
class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;
  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          categoryName.replaceAll('\n', ' '),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Place>>(
        future: PlacesService.fetchNearbyPlaces(categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Yakınlarda açık yer bulunamadı 🦉",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final places = snapshot.data!;
          return ListView.builder(
            itemCount: places.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final place = places[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: place.isOpenNow ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    place.isOpenNow ? "Şu an Açık" : "Şu an Kapalı",
                    style: TextStyle(
                      color: place.isOpenNow ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
