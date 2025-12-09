import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odak_list/screens/profile_select_screen.dart'; 
import 'package:odak_list/screens/verify_email_screen.dart';
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
  final _pinController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  // --- ŞİFRE SIFIRLAMA DİYALOĞU ---
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Şifre Sıfırlama"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Mail adresinizi girin, size sıfırlama bağlantısı gönderelim."),
            const SizedBox(height: 10),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.trim().isEmpty) return;
              try {
                await _authService.sendPasswordResetEmail(resetEmailController.text.trim());
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sıfırlama maili gönderildi! Lütfen kutunuzu kontrol edin."))
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text("Gönder"),
          )
        ],
      ),
    );
  }

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
    
    if (!isLogin) {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen adınızı girin."))
        );
        return;
      }
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
        // AuthService'deki signIn, kullanıcı yoksa hata fırlatacak.
        User? user = await _authService.signIn(email, password);
        
        if (user != null) {
          // Cache sorununu önlemek için sunucudan son durumu çekiyoruz
          await user.reload(); 
          User? refreshedUser = FirebaseAuth.instance.currentUser;

          if (mounted) {
             // 1. Mail Onaylı mı?
             if (refreshedUser != null && refreshedUser.emailVerified) {
               // ONAYLI -> Profil Seçimine Git
               Navigator.pushReplacement(
                 context,
                 MaterialPageRoute(builder: (context) => const ProfileSelectScreen()),
               );
             } else {
               // ONAYSIZ -> Doğrulama Ekranına Git
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Lütfen önce mail adresinizi doğrulayın."))
               );
               Navigator.pushReplacement(
                 context,
                 MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
               );
             }
          }
        }
      } else {
        // --- KAYIT OL ---
        User? user = await _authService.signUp(email, password, name);
        
        if (user != null) {
          // 1. Hemen veritabanı profilini oluştur (Profil ekranı boş gelmesin diye)
          await _dbService.createInitialAdminProfile(name, pin);
          
          // 2. Doğrulama mailini gönder
          await _authService.sendEmailVerification();
          
          // 3. Doğrulama ekranına yönlendir
          if (mounted) {
             Navigator.pushReplacement(
               context,
               MaterialPageRoute(builder: (context) => const VerifyEmailScreen()), 
             );
          }
        }
      }
    } catch (e) {
      // HATA YÖNETİMİ
      if (mounted) {
        String errorMessage = e.toString().replaceAll("Exception:", "").trim();
        
        // Kullanıcı dostu hata mesajı
        if (errorMessage.contains("user-not-found") || errorMessage.contains("Kullanıcı bulunamadı")) {
          errorMessage = "Böyle bir mail adresi kayıtlı değil. Lütfen önce 'Kayıt Ol' butonuna basın.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          )
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
              const Icon(Icons.check_circle, size: 100, color: AppColors.priorityMedium),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Tekrar Hoşgeldin!" : "Hesap Oluştur",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Kayıt Ol Formu (İsim ve Pin sadece kayıt olurken görünür)
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

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              
              // --- ŞİFREMİ UNUTTUM BUTONU (Sadece Giriş Ekranında) ---
              if (isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text("Şifremi Unuttum?", style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
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