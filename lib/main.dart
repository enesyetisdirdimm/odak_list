// Dosya: lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Web kontrolü (kIsWeb) için şart
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:odak_list/screens/navigation_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart' as notify;
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
import 'package:odak_list/services/purchase_api.dart'; 
import 'package:odak_list/screens/verify_email_screen.dart'; 
import 'package:intl/date_symbol_data_local.dart';

// Yerel Zaman Dilimi Ayarı (Web Uyumlu)
Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  
  // Web'de yerel zaman dilimi eklentisi çalışmaz, direkt UTC ayarla
  if (kIsWeb) {
    try {
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      print("Web Timezone Ayarı Hatası: $e");
    }
    return;
  }

  // Mobil için normal ayar
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
  
  // 1. Firebase ve Servisleri Başlat (WEB İÇİN ÖZEL AYAR)
  try {
    if (kIsWeb) {
      // WEB İÇİN MANUEL CONFIG (Hatasız Başlatma)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBpNso9JhJkYAgplazcdQATfcx5t-IVxAM",
          authDomain: "odaklist.firebaseapp.com",
          projectId: "odaklist",
          storageBucket: "odaklist.firebasestorage.app",
          messagingSenderId: "873035973416",
          appId: "1:873035973416:web:d84a25f431318813cc061d",
        ),
      );
    } else {
      // MOBİL İÇİN OTOMATİK BAŞLATMA
      await Firebase.initializeApp();
    }
    

    // DÜZELTME: Satın alma servisini WEB'de çalıştırma (Hata verdirir)
    if (!kIsWeb) {
      await PurchaseApi.init();
    }
  } catch (e) {
    print("Başlatma hatası (Firebase/Purchase): $e");
  }
  await initializeDateFormatting('tr_TR', null);
  final dbService = DatabaseService();
  
  // 2. Onboarding Kontrolü
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // 3. Bildirim ve Zaman Dilimi Ayarları
  try {
    await _configureLocalTimeZone();
    // Bildirim servisini başlat (İçinde Web kontrolü var)
    await notify.NotificationService().init();
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
            ? const AuthWrapper() 
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
      title: 'CoFocus', 
      
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
        return FutureBuilder<void>(
          future: snapshot.data!.reload(), 
          builder: (context, asyncSnapshot) {
            
            final user = FirebaseAuth.instance.currentUser;
            
            // A. Mail Onaylanmamışsa -> Doğrulama Ekranı
            if (user != null && !user.emailVerified) {
              return const VerifyEmailScreen();
            }

            // B. Mail Onaylıysa -> Profil Kontrolü
            return Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // Hafızada kayıtlı bir profil varsa -> Ana Ekran
                if (taskProvider.currentMember != null) {
                  return NavigationScreen(dbService: DatabaseService());
                }

                // Kayıtlı profil yoksa -> Profil Seçimi
                return const ProfileSelectScreen();
              },
            );
          },
        );
      },
    );
  }
}