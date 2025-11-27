// lib/screens/premium_screen.dart

import 'package:flutter/material.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:provider/provider.dart';
//import 'package:confetti/confetti.dart'; // Efekt için (Opsiyonel, yoksa hata vermez, kaldırabilirsin)

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();

  // SATIN ALMA SİMÜLASYONU
  void _buyPremium() async {
    setState(() => _isLoading = true);

    // Gerçek uygulamada burada Apple/Google ödeme penceresi açılır.
    // Biz şimdilik 2 saniye bekleyip başarılı olmuş gibi yapacağız.
    await Future.delayed(const Duration(seconds: 2));

    await _dbService.activatePremium();

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Başarı Mesajı
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Tebrikler! 🎉"),
        content: const Text("Hesabınız Premium'a yükseltildi. Artık tüm ekip üyeleriniz sınırsız özelliklere sahip!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Dialogu kapat
              Navigator.pop(context); // Premium ekranından çık
            },
            child: const Text("Harika"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      body: Stack(
        children: [
          // Arka Plan Deseni
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeProvider.primaryColor.withOpacity(0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Kapat Butonu
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Taç İkonu ve Başlık
                  Icon(Icons.workspace_premium, size: 80, color: Colors.orangeAccent),
                  const SizedBox(height: 16),
                  const Text(
                    "OdakList Premium",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Ekibini bir üst seviyeye taşı!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Özellikler Listesi
                  _buildFeatureItem(Icons.notifications_active, "Anlık Bildirimler", "Uygulama kapalıyken bile haberdar ol."),
                  _buildFeatureItem(Icons.people_alt, "Sınırsız Ekip Üyesi", "İstediğin kadar kişi ekle."),
                  _buildFeatureItem(Icons.history, "Sınırsız Geçmiş", "Tüm aktivite loglarına eriş."),
                  _buildFeatureItem(Icons.star, "Öncelikli Destek", "Sorunlarına anında çözüm."),

                  const Spacer(),
                  
                  // Fiyat ve Buton
                  const Text(
                    "Aylık sadece ₺49.99",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _buyPremium,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.secondaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "PREMIUM'A GEÇ",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "İstediğin zaman iptal edebilirsin.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orangeAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}