import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/screens/homescreen.dart';
import 'package:odak_list/screens/calendar_screen.dart'; 
import 'package:odak_list/screens/pomodoro_screen.dart';
import 'package:odak_list/screens/reports_screen.dart';
import 'package:odak_list/screens/web/web_home_layout.dart'; // Web Layout Import
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/utils/app_colors.dart';

class NavigationScreen extends StatefulWidget {
  final DatabaseService dbService;
  const NavigationScreen({super.key, required this.dbService});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Sayfaları tanımla (Web için WebHomeLayout kullanılıyor)
    // MediaQuery burada çalışmaz, build içinde kontrol edeceğiz.
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    // Ekran Genişliğini Al
    final width = MediaQuery.of(context).size.width;
    final isWebOrDesktop = width > 800; 

    // Sayfa Listesi (Web ve Mobil ayrımı burada yapılıyor)
    final List<Widget> pages = [
      isWebOrDesktop 
          ? WebHomeLayout(dbService: widget.dbService) 
          : HomeScreen(dbService: widget.dbService),
      CalendarScreen(dbService: widget.dbService),
      const PomodoroScreen(),
      const ReportsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      // MOBİL MENÜ (ALTTA)
      bottomNavigationBar: isWebOrDesktop 
          ? null 
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: isDarkMode ? AppColors.cardDark : Colors.white,
              indicatorColor: themeProvider.secondaryColor.withOpacity(0.2),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Görevler'),
                NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Takvim'),
                NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Pomodoro'),
                NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Raporlar'),
              ],
            ),

      body: isWebOrDesktop
          ? Row(
              children: [
                // --- WEB MENÜ (SOLDAKİ İNCE ŞERİT) ---
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  backgroundColor: isDarkMode ? const Color(0xFF151515) : Colors.white, // Biraz daha koyu/açık ayrımı
                  labelType: NavigationRailLabelType.all,
                  
                  // RENK AYARLARI (Sorunu çözen kısım)
                  indicatorColor: themeProvider.secondaryColor, // Seçili arka plan rengi
                  selectedIconTheme: const IconThemeData(color: Colors.white), // Seçili ikon rengi (BEYAZ)
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade500), // Seçili olmayanlar gri
                  selectedLabelTextStyle: TextStyle(color: themeProvider.secondaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  
                  // LOGO (En üstte)
                 /* leading: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
                    child: Image.asset("assets/icon.png", width: 40, height: 40),
                  ),*/
                  
                  leading: const SizedBox(height: 30),

                  groupAlignment: -1.0, // Menüyü yukarı yasla
                  
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.check_circle_outline), 
                      selectedIcon: Icon(Icons.check_circle), 
                      label: Text('Görevler')
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined), 
                      selectedIcon: Icon(Icons.calendar_month), 
                      label: Text('Takvim')
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.timer_outlined), 
                      selectedIcon: Icon(Icons.timer), 
                      label: Text('Odak')
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pie_chart_outline), 
                      selectedIcon: Icon(Icons.pie_chart), 
                      label: Text('Rapor')
                    ),
                  ],
                ),
                
                const VerticalDivider(thickness: 1, width: 1),

                // İÇERİK ALANI
                Expanded(
                  child: pages[_selectedIndex],
                ),
              ],
            )
          : pages[_selectedIndex],
    );
  }
}