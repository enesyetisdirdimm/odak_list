import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Renk Paletleri
  final List<Map<String, dynamic>> colorPalettes = const [
    {'start': Color(0xFFFE806F), 'end': Color(0xFFF07294), 'name': 'Şeftali'},
    {'start': Color(0xFF4facfe), 'end': Color(0xFF00f2fe), 'name': 'Okyanus'},
    {'start': Color(0xFF43e97b), 'end': Color(0xFF38f9d7), 'name': 'Doğa'},
    {'start': Color(0xFFfa709a), 'end': Color(0xFFfee140), 'name': 'Gün Batımı'},
    {'start': Color(0xFF667eea), 'end': Color(0xFF764ba2), 'name': 'Gece Moru'},
    {'start': Color(0xFFff9a9e), 'end': Color(0xFFfecfef), 'name': 'Şeker Pembe'},
  ];

  // --- YEDEKLEME İŞLEMİ ---
  Future<void> _backupData(BuildContext context) async {
    try {
      final dbPath = await DatabaseService().getDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        // Dosyayı paylaş (Drive'a, WhatsApp'a vb. atabilir)
        // XFile kullanarak paylaşım yapıyoruz (Share Plus 10.0+ standardı)
        await Share.shareXFiles([XFile(dbPath)], text: 'OdakList Yedek Dosyası');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veritabanı bulunamadı!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yedekleme hatası: $e")));
    }
  }

  // --- GERİ YÜKLEME İŞLEMİ ---
  Future<void> _restoreData(BuildContext context) async {
    try {
      // Dosya Seçiciyi Aç
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File sourceFile = File(result.files.single.path!);
        
        // Güvenlik: Veritabanını kapat
        await DatabaseService().close();

        // Yeni dosyayı eski yerin üzerine yaz
        final dbPath = await DatabaseService().getDatabasePath();
        await sourceFile.copy(dbPath);

        // Uygulamayı yenile
        if (context.mounted) {
          // Provider'a verileri yeniden yüklemesini söyle
          await Provider.of<TaskProvider>(context, listen: false).loadData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Veriler başarıyla geri yüklendi! ✅"), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Geri yükleme hatası: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Ayarlar", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // --- GÖRÜNÜM AYARLARI ---
          Text("Görünüm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              title: Text("Karanlık Mod", style: TextStyle(color: textColor)),
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: themeProvider.secondaryColor),
              value: isDark,
              activeColor: themeProvider.secondaryColor,
              onChanged: (val) {
                themeProvider.toggleTheme(val);
              },
            ),
          ),

          const SizedBox(height: 30),

          // --- RENK PALETİ ---
          Text("Tema Rengi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.5,
            ),
            itemCount: colorPalettes.length,
            itemBuilder: (context, index) {
              final palette = colorPalettes[index];
              final Color startColor = palette['start'];
              final Color endColor = palette['end'];
              final String name = palette['name'];
              
              bool isSelected = themeProvider.primaryColor.value == startColor.value;

              return GestureDetector(
                onTap: () => themeProvider.updateColor(startColor, endColor),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [startColor, endColor]),
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: textColor, width: 2) : null,
                  ),
                  alignment: Alignment.center,
                  child: isSelected 
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // --- YEDEKLEME ALANI ---
          Text("Veri Yönetimi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                  title: Text("Verileri Yedekle", style: TextStyle(color: textColor)),
                  subtitle: const Text("Tüm verilerini bir dosya olarak kaydet."),
                  onTap: () => _backupData(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.green),
                  title: Text("Geri Yükle", style: TextStyle(color: textColor)),
                  subtitle: const Text("Yedek dosyasından verilerini geri getir."),
                  onTap: () => _restoreData(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Center(
            child: Text("Versiyon 1.0.0", style: TextStyle(color: Colors.grey.shade500)),
          )
        ],
      ),
    );
  }
}