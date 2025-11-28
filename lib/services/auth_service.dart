// Dosya: lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- GİRİŞ YAP ---
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      throw Exception("Giriş başarısız: Şifre veya mail hatalı.");
    }
  }

  // --- KAYIT OL ---
  Future<User?> signUp(String email, String password, String name) async {
    try {
      // 1. Kullanıcıyı oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // 2. İsmi Auth profiline işle
      if (result.user != null) {
        await result.user!.updateDisplayName(name);
        await result.user!.reload(); 
      }
      
      return _auth.currentUser;
    } catch (e) {
      throw Exception("Kayıt oluşturulamadı: ${e.toString()}");
    }
  }

  // --- DOĞRULAMA MAİLİ GÖNDER (YENİ) ---
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // --- DOĞRULAMA DURUMUNU KONTROL ET (YENİ) ---
  // Firebase verisi anlık güncellenmez, elle reload yapıp kontrol etmeliyiz.
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Sunucudan son durumu çek
      return _auth.currentUser!.emailVerified;
    }
    return false;
  }

  // --- ÇIKIŞ YAP ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- ŞİFRE DEĞİŞTİRME ---
  Future<void> changePassword(String currentPassword, String newPassword) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("Kullanıcı bulunamadı");

    String email = user.email!;
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: currentPassword);

    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception("Şifre değiştirilemedi. Eski şifrenizi kontrol edin.");
    }
  }
  
  // --- İSİM GÜNCELLEME ---
  Future<void> updateName(String newName) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(newName);
      await user.reload();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Sıfırlama maili gönderilemedi. Mail adresini kontrol edin.");
    }
  }
}