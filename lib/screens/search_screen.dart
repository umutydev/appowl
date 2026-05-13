import 'package:flutter/material.dart';
import '../models/place.dart';
import '../data/places_service.dart';
import '../data/map_utils.dart';
import '../data/report_service.dart';
import '../widgets/modern_place_card.dart'; // YAKIŞIKLI KARTIMIZI ÇAĞIRDIK

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Place> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false; // Kullanıcı arama yaptı mı yapmadı mı kontrolü

  // API'ye arama isteği atan ana fonksiyon
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      // Klavyeyi ekrandan gizle
      FocusScope.of(context).unfocus();
    });

    try {
      final results = await PlacesService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arama sırasında bir hata oluştu 🦉'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Bildirim paneli (Ana sayfadaki ile aynı, kartın ihtiyacı var)
  void _showReportSheet(BuildContext context, String placeId) {
    final List<String> reportOptions = [
      "Bu mekan kapandı",
      "Mekan taşınmış",
      "Taksi bulunmuyor",
      "Burası çok kalabalık",
      "Polis çevirmesi var",
      "ATM bozuk",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Canlı Durum Bildir 📢",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              ...reportOptions.map(
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
                      SnackBar(
                        content: Text("Bildirimin iletildi: $option 🦉"),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Keşfet & Ara',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 MODERN ARAMA ÇUBUĞU
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted:
                  _performSearch, // Klavyedeki 'Ara' tuşuna basılınca çalışır
              decoration: InputDecoration(
                hintText: 'Mekan, eczane, restoran ara...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.orangeAccent,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch(
                            '',
                          ); // Temizleyince sonuçları da sıfırla
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (value) {
                // Çarpı ikonunun anlık çıkması/kaybolması için ekranı tetikliyoruz
                setState(() {});
              },
            ),
          ),

          // 📄 ARAMA SONUÇLARI LİSTESİ
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  )
                : !_hasSearched
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.travel_explore,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Ne aramak istersin? 🦉",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
                ? const Center(
                    child: Text(
                      "Aradığın kriterlere uygun mekan bulunamadı.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      // ESKİ KARTLAR YERİNE, ANA SAYFADAKİ GÜNCEL KARTIMIZI KULLANIYORUZ
                      return ModernPlaceCard(
                        place: place,
                        onReportTap: () => _showReportSheet(context, place.id),
                        onDirectionsTap: () => MapUtils.openMap(
                          place.latitude,
                          place.longitude,
                          place.name,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
