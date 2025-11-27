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
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase başlatma hatası: $e");
  }
  
  final dbService = DatabaseService();
  
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

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
            ? const ProfileSelectScreen() 
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
      title: 'OdakList',
      
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
      
      // YENİ GİRİŞ VE PROFİL KONTROLÜ
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          // 1. Kullanıcı henüz giriş yapmamışsa -> LOGIN
          if (!snapshot.hasData) {
            // Eğer onboarding gösterilmemişse önce onu göster, sonra login
            if (startScreen is OnboardingScreen) return startScreen;
            return const LoginScreen();
          }

          // 2. Kullanıcı giriş yapmışsa -> PROFİL DURUMUNA BAK (Consumer)
          return Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              
              // Veriler yükleniyorsa bekle
              if (taskProvider.isLoading) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Profil otomatik seçilmişse (Hafızadan geldi) -> ANA EKRAN
              if (taskProvider.currentMember != null) {
                return NavigationScreen(dbService: dbService);
              }

              // Seçili profil yoksa -> PROFİL SEÇİMİ
              return const ProfileSelectScreen();
            },
          );
        },
      ),
    );
  }
}