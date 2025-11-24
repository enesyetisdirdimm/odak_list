// lib/main.dart

import 'package:flutter/material.dart';
import 'package:odak_list/screens/navigation_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Uygulama başlamadan önce yerel saat dilimini (Timezone) ayarlayan fonksiyon
Future<void> _configureLocalTimeZone() async {
  // 1. Timezone veritabanını başlat
  tz.initializeTimeZones();
  
  String timeZoneName;
  
  try {
    // 2. Cihazın yerel saat dilimini almayı dene
    timeZoneName = await FlutterTimezone.getLocalTimezone();
  } catch (e) {
    // HATA OLURSA: Eğer native plugin bulunamazsa (MissingPluginException)
    // uygulama çökmesin diye varsayılan olarak UTC ata.
    print("Timezone alınamadı, varsayılan UTC kullanılıyor. Hata: $e");
    timeZoneName = 'UTC';
  }

  // 3. Timezone paketine bu saat dilimini kullanmasını söyle
  try {
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    print("Zaman dilimi ayarlanırken hata: $e");
    tz.setLocalLocation(tz.getLocation('UTC'));
  }
}

void main() async {
  // Flutter motorunun hazır olduğundan emin ol
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbService = DatabaseService();

  // HATA ÖNLEYİCİ: Burayı try-catch içine alıyoruz ki
  // bildirim sistemi bozuk olsa bile uygulama açılsın.
  try {
    await _configureLocalTimeZone();
    await NotificationService().init();
  } catch (e) {
    print("Bildirim servisi başlatılamadı: $e");
  }

  // Uygulamayı başlat
  runApp(MyApp(dbService: dbService));
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;

  const MyApp({super.key, required this.dbService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OdakList',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Poppins', 
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGradientEnd,
          background: AppColors.background,
        ),
        useMaterial3: true,
      ),
      home: NavigationScreen(dbService: dbService),
    );
  }
}