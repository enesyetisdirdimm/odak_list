import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odak_list/screens/team_screen.dart';
import 'package:odak_list/services/auth_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/screens/profile_select_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  void _refreshUser() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
    });
  }

  // --- İSİM DEĞİŞTİRME DİYALOĞU ---
  void _showEditNameDialog() {
    final controller = TextEditingController(text: _currentUser?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İsim Değiştir"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Yeni Ad Soyad", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _authService.updateName(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _refreshUser();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İsim güncellendi!")));
                }
              }
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  // --- ŞİFRE DEĞİŞTİRME DİYALOĞU (Sadece Admin İçin - Email Şifresi) ---
  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hesap Şifresini Değiştir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bu işlem ana hesabın giriş şifresini değiştirir (En az 6 karakter).", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni şifre en az 6 karakter olmalı.")));
                return;
              }
              try {
                await _authService.changePassword(oldPassController.text, newPassController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre başarıyla değiştirildi!")));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception:", ""))));
                }
              }
            },
            child: const Text("Değiştir"),
          )
        ],
      ),
    );
  }

  // --- HESAPTAN TAMAMEN ÇIKIŞ ---
  void _signOut() async {
    await _authService.signOut();
    if (mounted) Navigator.pop(context);
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
    final taskProvider = Provider.of<TaskProvider>(context); // Yetki kontrolü için

    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
    final currentMember = taskProvider.currentMember;
    final isAdmin = taskProvider.isAdmin; // Admin mi?

    final userName = currentMember?.name ?? "Misafir";
    final userRole = isAdmin ? "Yönetici" : "Editör";
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? "";

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
                        child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "K", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                              // İsim Düzenleme Butonu (İsteğe bağlı: Herkes ismini düzeltebilir mi? Şimdilik evet)
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
                    // BUTON 1: ŞİFRE DEĞİŞTİR (SADECE ADMİN)
                    if (isAdmin) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showChangePasswordDialog, 
                          icon: const Icon(Icons.lock_outline, size: 16),
                          label: const Text("Şifre"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    
                    // BUTON 2: PROFİL DEĞİŞTİR (HERKES)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                           taskProvider.logoutMember(); 
                           Navigator.pushAndRemoveUntil(
                             context, 
                             MaterialPageRoute(builder: (context) => const ProfileSelectScreen()),
                             (route) => false
                           );
                        },
                        icon: const Icon(Icons.switch_account, size: 16),
                        label: const Text("Profil Değiş"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: themeProvider.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // BUTON 3: TAMAMEN ÇIKIŞ YAP (HERKES)
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
          
          const SizedBox(height: 30),

          // --- EKİP YÖNETİMİ BUTONU (Sadece Admin Görür) ---
          if (isAdmin)
            Column(
              children: [
                Text("Yönetim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.people_alt, color: Colors.purple),
                    title: Text("Ekip ve Rol Yönetimi", style: TextStyle(color: textColor)),
                    subtitle: const Text("Kişi ekle, sil veya PIN değiştir", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),

          // --- DİĞER AYARLAR (Standart) ---
          Text("Görünüm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15)),
            child: SwitchListTile(
              title: Text("Karanlık Mod", style: TextStyle(color: textColor)),
              secondary: Icon(Icons.dark_mode, color: themeProvider.secondaryColor),
              value: isDarkMode,
              activeColor: themeProvider.secondaryColor,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
          ),
          const SizedBox(height: 30),

          Text("Tema Rengi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colorPalettes.length,
              itemBuilder: (context, index) {
                final palette = colorPalettes[index];
                final isSelected = themeProvider.currentGradient.colors[0] == palette['start'];
                return GestureDetector(
                  onTap: () {
                    themeProvider.setGradient(LinearGradient(colors: [palette['start'], palette['end']], begin: Alignment.topLeft, end: Alignment.bottomRight));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [palette['start'], palette['end']]),
                      border: isSelected ? Border.all(color: textColor, width: 3) : null,
                      boxShadow: [BoxShadow(color: (palette['start'] as Color).withOpacity(0.4), blurRadius: 5, offset: const Offset(0, 3))]
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              },
            ),
          ),
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
          Center(child: Text("Versiyon 1.4.1 (Pro)", style: TextStyle(color: Colors.grey.shade500))),
        ],
      ),
    );
  }
}