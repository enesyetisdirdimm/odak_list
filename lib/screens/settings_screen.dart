// Dosya: lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odak_list/screens/premium_screen.dart'; 
import 'package:odak_list/screens/team_screen.dart';
import 'package:odak_list/services/auth_service.dart';
import 'package:odak_list/services/database_service.dart'; 
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/screens/profile_select_screen.dart';
import 'package:odak_list/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  void _refreshUser() {
    if (mounted) {
      setState(() {
        _currentUser = FirebaseAuth.instance.currentUser;
      });
    }
  }

  // --- İSİM DEĞİŞTİRME DİYALOĞU ---
  void _showEditNameDialog() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final currentMember = taskProvider.currentMember;
    
    final initialName = currentMember?.name ?? _currentUser?.displayName ?? "";
    final controller = TextEditingController(text: initialName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("İsim Değiştir"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Yeni Ad Soyad", border: OutlineInputBorder()),
          maxLength: 15, 
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              final newName = controller.text.trim();
              Navigator.pop(ctx);

              try {
                // 1. Auth İsmini Güncelle
                await _authService.updateName(newName);

                // 2. Profil İsmini Güncelle
                if (currentMember != null) {
                  await _dbService.updateTeamMemberInfo(
                    currentMember.id, 
                    newName, 
                    currentMember.profilePin,
                    currentMember.email // <--- DÜZELTME BURADA: 4. Parametre (Email) eklendi
                  );
                  currentMember.name = newName; 
                  taskProvider.selectMember(currentMember);
                }

                if (mounted) {
                  _refreshUser();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("İsim başarıyla güncellendi!"))
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Bir hata oluştu."), backgroundColor: Colors.red)
                  );
                }
              }
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  // --- ŞİFRE DEĞİŞTİRME ---
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hesap Şifresini Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bu işlem ana hesabın giriş şifresini değiştirir.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mevcut Şifre", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Yeni Şifre (Min 6)", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("En az 6 karakter olmalı.")));
                return;
              }
              
              Navigator.pop(ctx);

              try {
                await _authService.changePassword(oldPassController.text, newPassController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre başarıyla değiştirildi!")));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata: Şifre değiştirilemedi."), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Değiştir"),
          )
        ],
      ),
    );
  }

  // --- GÜVENLİ ÇIKIŞ ---
  void _signOut() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    
    try {
      await _authService.signOut();
      await provider.logoutMember();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çıkış yapılırken hata oluştu.")));
      }
    }
  }

  final List<Map<String, dynamic>> colorPalettes = const [
    {'start': Color(0xFFFE806F), 'end': Color(0xFFF07294), 'name': 'Şeftali'},
    {'start': Color(0xFF4facfe), 'end': Color(0xFF00f2fe), 'name': 'Okyanus'},
    {'start': Color(0xFF43e97b), 'end': Color(0xFF38f9d7), 'name': 'Doğa'},
    {'start': Color(0xFFfa709a), 'end': Color(0xFFfee140), 'name': 'Gün Batımı'},
    {'start': Color(0xFF667eea), 'end': Color(0xFF764ba2), 'name': 'Gece Moru'},
    {'start': Color(0xFFff9a9e), 'end': Color(0xFFfecfef), 'name': 'Şeker'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
    final currentMember = taskProvider.currentMember;
    final isAdmin = taskProvider.isAdmin; 

    // İsim ve Rol Bilgileri
    final String rawName = currentMember?.name ?? _currentUser?.displayName ?? "Misafir";
    
    // --- İSİM KISALTMA MANTIĞI (15 Karakter Sınırı) ---
    final String displayUserName = rawName.length > 15 
        ? "${rawName.substring(0, 15)}..." 
        : rawName;
    // --------------------------------------------------

    final userRole = isAdmin ? "Yönetici" : "Editör";
    final userEmail = _currentUser?.email ?? "";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Ayarlar", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- PROFİL KARTI ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: themeProvider.currentGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: themeProvider.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade200,
                        child: Text(displayUserName.isNotEmpty ? displayUserName[0].toUpperCase() : "K", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Kısaltılmış ismi burada kullanıyoruz
                              Flexible(child: Text(displayUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                              
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                                onPressed: _showEditNameDialog, 
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("$userRole • $userEmail", style: const TextStyle(color: Colors.white70, fontSize: 12)), 
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // --- İŞLEM BUTONLARI ---
                Row(
                  children: [
                    if (isAdmin) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showChangePasswordDialog, 
                          icon: const Icon(Icons.lock_outline, size: 16),
                          label: const Text("Şifre"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                           await taskProvider.logoutMember(); 
                           if (context.mounted) {
                             Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ProfileSelectScreen()), (route) => false);
                           }
                        },
                        icon: const Icon(Icons.switch_account, size: 16),
                        label: const Text("Profil Değiş"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: themeProvider.primaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, size: 16, color: Colors.white70),
                    label: const Text("Hesaptan Tamamen Çıkış Yap", style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- PREMIUM BANNER ---
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.star, color: Colors.orange, size: 24)), const SizedBox(width: 15), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Premium'a Yükselt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text("Tüm özellikleri aç & Ekibini güçlendir!", style: TextStyle(color: Colors.white70, fontSize: 12))])), const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)]),
            ),
          ),
          
          const SizedBox(height: 30),

          // --- EKİP YÖNETİMİ ---
          if (isAdmin)
            Column(
              children: [
                Text("Yönetim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.people_alt, color: Colors.purple),
                    title: Text("Ekip ve Rol Yönetimi", style: TextStyle(color: textColor)),
                    subtitle: const Text("Kişi ekle, sil veya PIN değiştir", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamScreen())),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),

          // --- GÖRÜNÜM ---
          Text("Görünüm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15)),
            child: SwitchListTile(title: Text("Karanlık Mod", style: TextStyle(color: textColor)), secondary: Icon(Icons.dark_mode, color: themeProvider.secondaryColor), value: isDarkMode, activeColor: themeProvider.secondaryColor, onChanged: (val) => themeProvider.toggleTheme(val)),
          ),
          const SizedBox(height: 30),

          Text("Tema Rengi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          SizedBox(height: 70, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: colorPalettes.length, itemBuilder: (context, index) { final palette = colorPalettes[index]; final isSelected = themeProvider.currentGradient.colors[0] == palette['start']; return GestureDetector(onTap: () { themeProvider.setGradient(LinearGradient(colors: [palette['start'], palette['end']], begin: Alignment.topLeft, end: Alignment.bottomRight)); }, child: Container(margin: const EdgeInsets.only(right: 12), width: 50, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [palette['start'], palette['end']]), border: isSelected ? Border.all(color: textColor, width: 3) : null, boxShadow: [BoxShadow(color: (palette['start'] as Color).withOpacity(0.4), blurRadius: 5, offset: const Offset(0, 3))]), child: isSelected ? const Icon(Icons.check, color: Colors.white) : null)); })),
          const SizedBox(height: 30),

          Text("Geri Bildirim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                SwitchListTile(title: Text("Ses Efektleri", style: TextStyle(color: textColor)), subtitle: const Text("Görev tamamlanınca ses çıkar.", style: TextStyle(fontSize: 12, color: Colors.grey)), secondary: Icon(Icons.volume_up, color: themeProvider.secondaryColor), value: taskProvider.isSoundEnabled, activeColor: themeProvider.secondaryColor, onChanged: (val) => taskProvider.toggleSound(val)),
                Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                SwitchListTile(title: Text("Titreşim", style: TextStyle(color: textColor)), subtitle: const Text("Etkileşimlerde telefonu titret.", style: TextStyle(fontSize: 12, color: Colors.grey)), secondary: Icon(Icons.vibration, color: themeProvider.secondaryColor), value: taskProvider.isVibrationEnabled, activeColor: themeProvider.secondaryColor, onChanged: (val) => taskProvider.toggleVibration(val)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Center(child: Text("Versiyon 1.6.2 (Pro)", style: TextStyle(color: Colors.grey.shade500))),
        ],
      ),
    );
  }
}