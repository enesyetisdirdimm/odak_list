// Dosya: lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final DatabaseService dbService;
  const OnboardingScreen({super.key, required this.dbService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "CoFocus'a Hoşgeldin!",
      "desc": "Ekibinle senkronize ol, görevleri yönet ve birlikte başar.",
      "image": "assets/icon.png" 
    },
    {
      "title": "Odaklan & Başar",
      "desc": "Pomodoro tekniği ve özel odak sesleri ile verimliliğini artır.",
      "icon": "timer"
    },
    {
      "title": "Asla Unutma",
      "desc": "Ana ekran widget'ı ve akıllı hatırlatıcılar ile her zaman kontrol sende.",
      "icon": "widget"
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true); // "Gördüm" diye işaretle

    if (!mounted) return;
    
    // Direkt Login ekranına yönlendir
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const LoginScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F), // Koyu Lacivert Tema
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- GÖRSEL ALANI ---
                        Container(
                          height: 200, width: 200,
                          decoration: const BoxDecoration(
                            // İstenilen arka plan rengi (#2c333b)
                            color: Color(0xFF2C333B),
                            shape: BoxShape.circle,
                          ),
                          child: index == 0 
                            ? Padding(
                                // Resim kenarlara yapışmasın diye boşluk
                                padding: const EdgeInsets.all(30.0),
                                child: Image.asset(
                                  "assets/icon.png", 
                                  fit: BoxFit.contain
                                ),
                              )
                            : Icon(
                                index == 1 ? Icons.timer : Icons.widgets, 
                                size: 80, // İkon boyutu daha dengeli
                                color: const Color(0xFF00E5FF) // Cam Göbeği Mavi
                              ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        Text(
                          _pages[index]["title"]!,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pages[index]["desc"]!,
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Alt Kısım: Noktalar ve Buton
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sayfa Noktaları
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? const Color(0xFF00E5FF) : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // İleri / Başla Butonu
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _finishOnboarding();
                      } else {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: const Color(0xFF0A192F),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? "BAŞLA" : "İLERİ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}