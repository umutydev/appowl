import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/places_services.dart';
import '../data/places_service.dart';
import '../models/place.dart';
import '../data/map_utils.dart'; // Yeni ekledik

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Place> _results = [];
  bool _loading = false;

  void _onSearch(String val) async {
    if (val.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final res = await PlacesService.searchPlaces(val);
    setState(() {
      _results = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                onChanged: _onSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Ne arıyorsun? (Eczane, Restoran...)",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.orangeAccent,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orangeAccent,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final place = _results[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            title: Text(
                              place.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              place.address,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.directions,
                              color: Colors.blueAccent,
                            ), // Yol tarifi ikonu
                            onTap: () => MapUtils.openMap(
                              place.latitude,
                              place.longitude,
                            ), // Tıklayınca haritaya uçar
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
