import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // Tıklandığında telefonun arama ekranını açan gizli motor
  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    // Boşlukları temizle ki telefon rehberi hata vermesin
    final String cleanNumber = phoneNumber.replaceAll(' ', '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arama başlatılamadı! 🦉'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Arama Hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Yardım & Destek',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "İletişim Kanalları",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Owl uygulamasıyla ilgili her türlü teknik sorun, öneri veya mekan işbirlikleri için bize 7/24 ulaşabilirsin.",
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 30),

            // 1. NUMARA KARTI: KULLANICI / TEKNİK DESTEK
            _buildContactCard(
              context: context,
              title: "Kullanıcı Destek Hattı",
              subtitle: "Uygulama içi hatalar ve genel sorunlar",
              phoneNumber: "0555 555 55 55", // 🦉 1. NUMARAYI BURAYA YAZACAKSIN
              icon: Icons.support_agent,
              color: Colors.orangeAccent,
            ),

            const SizedBox(height: 16),

            // 2. NUMARA KARTI: İŞBİRLİĞİ VE YÖNETİM
            _buildContactCard(
              context: context,
              title: "İşbirlikleri ve Yönetim",
              subtitle: "Yeni mekan ekleme veya partnerlik",
              phoneNumber: "0532 323 32 32", // 🦉 2. NUMARAYI BURAYA YAZACAKSIN
              icon: Icons.handshake,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  // Jilet Gibi İletişim Kartı Tasarımı
  Widget _buildContactCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String phoneNumber,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _makePhoneCall(phoneNumber, context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Sol Taraftaki Yuvarlak İkon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),

                // Orta Kısım: Yazılar ve Numara
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Numaranın Yazdığı Kısım
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sağ Taraftaki Arama İkonu
                Icon(
                  Icons.phone_forwarded,
                  color: color.withOpacity(0.8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
