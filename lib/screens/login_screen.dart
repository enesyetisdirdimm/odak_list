import 'package:flutter/material.dart';
import 'package:odak_list/services/auth_service.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; 
  bool isLoading = false;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // YENİ: PIN Kontrolcüsü
  final _pinController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final pin = _pinController.text.trim();

    // Temel Kontroller
    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir email ve en az 6 haneli şifre girin."))
      );
      return;
    }
    
    // KAYIT ÖZEL KONTROLLERİ
    if (!isLogin) {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen adınızı girin."))
        );
        return;
      }
      // YENİ: PIN Zorunluluğu
      if (pin.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin profili için 4 haneli bir PIN girin."))
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // --- GİRİŞ YAP ---
        await _authService.signIn(email, password);
      } else {
        // --- KAYIT OL ---
        // 1. Hesabı oluştur
        await _authService.signUp(email, password, name);
        
        // 2. Veritabanına ŞİFRELİ Admin profilini ekle
        await _dbService.createInitialAdminProfile(name, pin);
      }
      
      // Başarılı olursa main.dart bizi içeri alacak
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception:", "")))
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 100, color: AppColors.priorityMedium),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Tekrar Hoşgeldin!" : "Hesap Oluştur",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // --- KAYIT FORMU ---
              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Ad Soyad (Admin)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                
                // YENİ: ZORUNLU PIN ALANI
                TextField(
                  controller: _pinController,
                  decoration: InputDecoration(
                    labelText: "Profil Pini (4 Hane)",
                    hintText: "Örn: 1234",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                ),
                const SizedBox(height: 16),
              ],

              // Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Şifre
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              // Buton
              isLoading 
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.priorityMedium,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isLogin ? "GİRİŞ YAP" : "KAYIT OL", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              
              const SizedBox(height: 20),

              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? "Hesabın yok mu? Kayıt Ol" : "Zaten hesabın var mı? Giriş Yap",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}