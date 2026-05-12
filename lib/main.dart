import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // FIREBASE EKLENDİ
import 'firebase_options.dart'; // FIREBASE EKLENDİ

// Diğer klasördeki ekranlarımızı buraya çağırıyoruz
import 'screens/home_screen.dart';
import 'screens/map_screen.dart'; // YENİ HARİTA EKRANIMIZ BURADA!
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart'; // LOGİN EKRANI

void main() async {
  // Flutter motorunu ve Firebase'i başlatıyoruz
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const OwlApp());
}

class OwlApp extends StatelessWidget {
  const OwlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Owl - Gece Rehberi',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      // UYGULAMA ARTIK DİREKT GİRİŞ EKRANINDAN BAŞLAYACAK
      home: const LoginScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // BAK KANKA: GoogleMap spagettisi gitti, yerine sadece MapScreen() geldi!
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const MapScreen(), // Bütün harita, sekmeler ve işaretçiler bu dosyanın içinde!
    const SearchScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Keşfet'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Harita'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Ara'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
