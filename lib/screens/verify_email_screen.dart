// Dosya: lib/screens/verify_email_screen.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // Eklendi
import 'package:flutter/material.dart';
import 'package:odak_list/screens/profile_select_screen.dart';
import 'package:odak_list/screens/login_screen.dart'; 
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
    
    // Ekran açılır açılmaz sunucudan son durumu kontrol et
    _checkStatusOnLoad();
  }

  // YENİ: Açılışta sunucuyu zorla kontrol et
  Future<void> _checkStatusOnLoad() async {
    // 1. Kullanıcıyı Firebase'den yenile (Reload)
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); 
      // Reload sonrası değişkeni güncelle
      setState(() {
        isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      });
    }

    // 2. Eğer zaten doğrulanmışsa içeri al
    if (isEmailVerified) {
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const ProfileSelectScreen())
        );
      }
    } else {
      // 3. Gerçekten doğrulanmamışsa o zaman mail gönder (veya gönderme butonunu aktif et)
      // Kullanıcıyı spamlamamak için direkt göndermek yerine timer başlatalım
      // ve kullanıcı isterse butona basıp göndersin.
      
      // _sendVerificationEmail(); // Otomatik göndermeyi kapattık, kullanıcı isterse basar.
      
      // Periyodik kontrolü başlat
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
    bool verified = await _authService.checkEmailVerified();
    
    if (verified) {
      timer?.cancel();
      if (mounted) {
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
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) setState(() => canResendEmail = true);
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doğrulama maili tekrar gönderildi."))
        );
      }
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
    // Bu satır güvenlik için kalabilir
    if (isEmailVerified) return const ProfileSelectScreen();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text("Mail Doğrulama"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, 
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
              "${_authService.currentUser?.email} adresinin onaylanmasını bekliyoruz.\n\nEğer onayladıysan sistem seni otomatik içeri alacaktır.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              // İlk başta buton aktif olsun
              onPressed: canResendEmail || timer != null ? _sendVerificationEmail : null,
              icon: const Icon(Icons.email),
              label: const Text("Doğrulama Mailini Tekrar Gönder"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.priorityMedium,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () async {
                await _authService.signOut(); 
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false
                  );
                }
              }, 
              child: const Text("Vazgeç / Giriş Ekranına Dön"),
            ),
          ],
        ),
      ),
    );
  }
}