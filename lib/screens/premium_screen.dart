// lib/screens/premium_screen.dart

import 'package:flutter/material.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/purchase_api.dart'; // API
import 'package:odak_list/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart'; // Paket

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  Package? _monthlyPackage; // Store'dan gelen gerçek paket
  
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  // Fiyatları Store'dan Çek
  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    
    final offerings = await PurchaseApi.fetchOffers();
    
    if (offerings.isNotEmpty && offerings.first.availablePackages.isNotEmpty) {
      // Genelde ilk paket aylıktır (RevenueCat ayarına göre değişir)
      setState(() {
        _monthlyPackage = offerings.first.availablePackages.first;
      });
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  // SATIN ALMA İŞLEMİ (GERÇEK)
  Future<void> _buyPremium() async {
    if (_monthlyPackage == null) return;

    setState(() => _isLoading = true);

    // 1. Google/Apple Ödeme Ekranını Aç
    bool isSuccess = await PurchaseApi.purchasePackage(_monthlyPackage!);

    if (isSuccess) {
      // 2. Ödeme Başarılıysa Veritabanını Güncelle
      await _dbService.activatePremium();
      
      if (!mounted) return;
      
      // 3. Kutlama Mesajı
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Hoşgeldin Şampiyon! 👑"),
          content: const Text("Premium üyelik başarıyla aktifleştirildi. Ekibin artık durdurulamaz!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("Tamam"),
            )
          ],
        ),
      );
    } else {
      // İptal edildi veya hata oluştu
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem iptal edildi veya hata oluştu.")));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }
  
  // SATIN ALMAYI GERİ YÜKLE (Mecburi Buton)
  Future<void> _restore() async {
    setState(() => _isLoading = true);
    bool isSuccess = await PurchaseApi.restorePurchases();
    
    if (isSuccess) {
      await _dbService.activatePremium();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Premium üyeliğiniz geri yüklendi!")));
         Navigator.pop(context);
      }
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aktif bir üyelik bulunamadı.")));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    // Eğer paket henüz yüklenmediyse "Yükleniyor..." göster
    final priceText = _monthlyPackage != null 
        ? _monthlyPackage!.storeProduct.priceString 
        : "...";

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: themeProvider.primaryColor.withOpacity(0.2)))),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(icon: const Icon(Icons.close, size: 30), onPressed: () => Navigator.pop(context)),
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.workspace_premium, size: 80, color: Colors.orangeAccent),
                  const SizedBox(height: 16),
                  const Text("OdakList Premium", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text("Ekibini bir üst seviyeye taşı!", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 30),
                  
                  // Özellikler
                  _buildFeatureItem(Icons.notifications_active, "Anlık Bildirimler", "Uygulama kapalıyken bile görev atamalarından haberdar ol."),
                  _buildFeatureItem(Icons.attach_file, "Dosya & Resim Yükleme", "Görevlere görsel, PDF ve dosya ekleyerek işleri netleştir."),
                  _buildFeatureItem(Icons.people_alt, "Sınırsız Ekip", "3 Kişilik sınırı kaldır, dilediğin kadar üye ekle."),
                  _buildFeatureItem(Icons.history, "Sınırsız Geçmiş", "Tüm aktivite loglarına eriş."),
                  const Spacer(),
                  
                  // YÜKLENİYORSA BEKLE
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    Text(
                      _monthlyPackage != null ? "$priceText / Ay" : "Fiyatlar yükleniyor...",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    
                    // SATIN AL BUTONU
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _monthlyPackage == null ? null : _buyPremium,
                        style: ElevatedButton.styleFrom(backgroundColor: themeProvider.secondaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
                        child: const Text("PREMIUM'A GEÇ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // RESTORE BUTONU
                    TextButton(
                      onPressed: _restore,
                      child: const Text("Satın Alımları Geri Yükle", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
                    )
                  ]
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
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.orangeAccent, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13))]))
        ],
      ),
    );
  }
}