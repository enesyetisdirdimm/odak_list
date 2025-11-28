// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
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

  // --- ŞİFRE SIFIRLAMA DİYALOĞU (YENİ) ---
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

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir email ve en az 6 haneli şifre girin."))
      );
      return;
    }
    
    if (!isLogin) {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen adınızı girin.")));
        return;
      }
      if (pin.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin profili için 4 haneli bir PIN girin.")));
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await _authService.signIn(email, password);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSelectScreen()),
          );
        }
      } else {
        await _authService.signUp(email, password, name);
        await _dbService.createInitialAdminProfile(name, pin);
        
        if (mounted) {
           await _authService.sendEmailVerification();
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (context) => const VerifyEmailScreen()), 
           );
        }
      }
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
              const Icon(Icons.check_circle, size: 100, color: AppColors.priorityMedium),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Tekrar Hoşgeldin!" : "Hesap Oluştur",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

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