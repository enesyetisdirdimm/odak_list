// Dosya: lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:odak_list/screens/navigation_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:odak_list/screens/onboarding_screen.dart';
import 'package:odak_list/screens/login_screen.dart';
import 'package:odak_list/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odak_list/screens/profile_select_screen.dart';
import 'package:odak_list/services/purchase_api.dart'; // Satın Alma Servisi
import 'package:odak_list/screens/verify_email_screen.dart'; // Mail Doğrulama

// Yerel Zaman Dilimi Ayarı
Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  String timeZoneName;
  try {
    timeZoneName = await FlutterTimezone.getLocalTimezone();
  } catch (e) {
    timeZoneName = 'UTC';
  }
  try {
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Firebase Başlat
  try {
    await Firebase.initializeApp();
    // 2. Satın Alma Servisini Başlat
    await PurchaseApi.init();
  } catch (e) {
    print("Başlatma hatası: $e");
  }
  
  final dbService = DatabaseService();
  
  // 3. Onboarding Kontrolü
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // 4. Bildirim ve Zaman Dilimi Ayarları
  try {
    await _configureLocalTimeZone();
    await NotificationService().init();
  } catch (e) {
    print("Servis hatası: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()), 
      ],
      child: MyApp(
        dbService: dbService, 
        startScreen: seenOnboarding 
            ? const AuthWrapper() // Akıllı Giriş Kontrolü
            : OnboardingScreen(dbService: dbService),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;
  final Widget startScreen;

  const MyApp({super.key, required this.dbService, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoFocus', // Uygulama Adı
      
      // --- AÇIK TEMA ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: AppColors.cardLight,
        primaryColor: themeProvider.primaryColor,
        colorScheme: ColorScheme.light(
          primary: themeProvider.primaryColor,
          secondary: themeProvider.secondaryColor,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimaryLight),
          bodyMedium: TextStyle(color: AppColors.textSecondaryLight),
        ),
      ),

      // --- KOYU TEMA ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.cardDark,
        primaryColor: themeProvider.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: themeProvider.primaryColor,
          secondary: themeProvider.secondaryColor,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
          bodyMedium: TextStyle(color: AppColors.textSecondaryDark),
        ),
        dialogBackgroundColor: AppColors.cardDark,
      ),

      themeMode: themeProvider.themeMode,
      
      // Başlangıç Ekranı (Onboarding veya AuthWrapper)
      home: startScreen, 
    );
  }
}

// --- AKILLI GİRİŞ VE YÖNLENDİRME KONTROLCÜSÜ ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // 1. Kullanıcı Girişi Yoksa -> Login Ekranı
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 2. Kullanıcı Girişi Varsa -> Mail Onayını ve Profili Kontrol Et
        // FutureBuilder kullanarak 'reload()' işleminin bitmesini bekliyoruz.
        return FutureBuilder<void>(
          future: snapshot.data!.reload(), // Kullanıcı bilgisini tazele
          builder: (context, asyncSnapshot) {
            // Not: reload() void döner, veriyi FirebaseAuth.instance'dan alırız.
            
            final user = FirebaseAuth.instance.currentUser;
            
            // A. Mail Onaylanmamışsa -> Doğrulama Ekranı
            if (user != null && !user.emailVerified) {
              return const VerifyEmailScreen();
            }

            // B. Mail Onaylıysa -> Profil Kontrolü (Provider)
            return Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                // TaskProvider verileri yüklüyorsa (Profil kontrolü dahil)
                if (taskProvider.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // Hafızada kayıtlı bir profil başarıyla seçildiyse -> Ana Ekran
                if (taskProvider.currentMember != null) {
                  return NavigationScreen(dbService: DatabaseService());
                }

                // Kayıtlı profil yoksa veya silinmişse -> Profil Seçimi
                return const ProfileSelectScreen();
              },
            );
          },
        );
      },
    );
  }
}