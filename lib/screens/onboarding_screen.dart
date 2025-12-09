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
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;
    
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
                        // --- GÖRSEL ALANI (DÜZELTİLDİ) ---
                        Container(
                          height: 200, width: 200,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C333B), // Arka plan rengi
                            shape: BoxShape.circle,
                            // Hafif gölge ekleyelim ki daha şık dursun
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                            ]
                          ),
                          child: index == 0 
                            ? ClipOval( // <--- İŞTE SİHİR BURADA: Resmi yuvarlak kesiyor
                                child: Padding(
                                  // Eğer logonun kenarlarında boşluk yoksa bu padding'i 0 yapabilirsin
                                  padding: const EdgeInsets.all(0.0), 
                                  child: Image.asset(
                                    "assets/icon.png", 
                                    fit: BoxFit.cover, // Resmi daireye tam sığdır
                                  ),
                                ),
                              )
                            : Icon(
                                index == 1 ? Icons.timer : Icons.widgets, 
                                size: 80, 
                                color: const Color(0xFF00E5FF)
                              ),
                        ),
                        // ---------------------------------

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
            
            // Alt Kısım
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
                          color: _currentPage == index ? const Color(0xFF00E5FF) : Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // İleri Butonu
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