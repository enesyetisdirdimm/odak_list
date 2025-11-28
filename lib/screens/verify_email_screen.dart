// Dosya: lib/screens/verify_email_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:odak_list/screens/profile_select_screen.dart';
import 'package:odak_list/services/auth_service.dart';
import 'package:odak_list/utils/app_colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // 1. Durumu kontrol et
    isEmailVerified = _authService.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      // 2. Mail gönder (Eğer daha önce gönderilmediyse)
      _sendVerificationEmail();

      // 3. Her 3 saniyede bir kontrol et (Kullanıcı linke tıkladı mı?)
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    // Firebase kullanıcısını yenile
    bool verified = await _authService.checkEmailVerified();
    
    if (verified) {
      timer?.cancel();
      if (mounted) {
        // Doğrulandıysa içeri al
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const ProfileSelectScreen())
        );
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      setState(() => canResendEmail = false);
      // 30 saniye sonra tekrar gönderme hakkı ver
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) setState(() => canResendEmail = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer zaten doğrulanmışsa bu ekranı gösterme (Güvenlik)
    if (isEmailVerified) return const ProfileSelectScreen();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Mail Doğrulama"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 100, color: AppColors.priorityMedium),
            const SizedBox(height: 20),
            const Text(
              "Mail Adresini Doğrula",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "${_authService.currentUser?.email} adresine bir doğrulama bağlantısı gönderdik.\n\nLütfen linke tıkla ve hesabını onayla.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Tekrar Gönder Butonu
            ElevatedButton.icon(
              onPressed: canResendEmail ? _sendVerificationEmail : null,
              icon: const Icon(Icons.email),
              label: const Text("Tekrar Mail Gönder"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.priorityMedium,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            
            // Vazgeç Butonu
            TextButton(
              onPressed: () => _authService.signOut(), // Çıkış yapıp başa dönsün
              child: const Text("Vazgeç / Giriş Ekranına Dön"),
            ),
          ],
        ),
      ),
    );
  }
}