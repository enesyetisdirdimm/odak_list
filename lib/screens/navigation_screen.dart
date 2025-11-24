// lib/screens/navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:odak_list/screens/homescreen.dart';
import 'package:odak_list/screens/pomodoro_screen.dart';
import 'package:odak_list/screens/reports_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/utils/app_colors.dart';

class NavigationScreen extends StatefulWidget {
  final DatabaseService dbService;
  const NavigationScreen({super.key, required this.dbService});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0; // Hangi sekmede olduğumuzu tutar

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Sayfa listemizi oluşturuyoruz
    _pages = [
      // 1. Sayfa: HomeScreen (Database servisini paslıyoruz)
      HomeScreen(dbService: widget.dbService),
      // 2. Sayfa: Pomodoro
      const PomodoroScreen(),
      // 3. Sayfa: Raporlar
      const ReportsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Ana arka plan rengi
      body: IndexedStack(
        // Sayfalar arası geçişte state'i (kaydırma pozisyonu vb.) korur
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        // Gölge eklemek için Container ile sardık
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -5), // Gölge yukarıda
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          )
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Görevler',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Pomodoro',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Raporlar',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          
          // Stil Ayarları
          backgroundColor: Colors.transparent, // Arka planı transparent yap (Container yönetecek)
          elevation: 0, // Kendi gölgesini kaldır
          selectedItemColor: AppColors.primaryGradientEnd, // Seçili ikon rengi
          unselectedItemColor: AppColors.textSecondary, // Seçili olmayan ikon rengi
          showUnselectedLabels: true, // Seçili olmayan etiketleri göster
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}