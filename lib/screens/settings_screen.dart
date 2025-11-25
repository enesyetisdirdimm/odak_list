import 'package:flutter/material.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Görünüm Ayarları", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TEMA MODU ---
            const Text("Genel Tema", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SwitchListTile(
                title: const Text("Karanlık Mod"),
                subtitle: const Text("Gözlerini yormayan koyu tema"),
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                value: isDark,
                activeColor: themeProvider.primaryColor,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                },
              ),
            ),

            const SizedBox(height: 30),

            // --- RENK TEMASI ---
            const Text("Uygulama Rengi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Sana enerji veren rengi seç:", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.5,
                ),
                itemCount: colorPalettes.length,
                itemBuilder: (context, index) {
                  final palette = colorPalettes[index];
                  final Color startColor = palette['start'];
                  final Color endColor = palette['end'];
                  final String name = palette['name'];
                  
                  // Seçili olanı bul
                  bool isSelected = themeProvider.primaryColor.value == startColor.value;

                  return GestureDetector(
                    onTap: () {
                      themeProvider.updateColor(startColor, endColor);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [startColor, endColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
                        boxShadow: [
                          BoxShadow(
                            color: startColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: isSelected 
                          ? const Icon(Icons.check_circle, color: Colors.white, size: 32)
                          : Text(
                              name, 
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [Shadow(color: Colors.black26, blurRadius: 2)]
                              ),
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}