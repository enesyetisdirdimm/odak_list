import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/screens/navigation_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart'; // YENİ EKLENDİ
import 'package:odak_list/utils/app_colors.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

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
  
  final dbService = DatabaseService();

  try {
    await _configureLocalTimeZone();
    await NotificationService().init();
  } catch (e) {
    print("Servis başlatma hatası: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // YENİ: TaskProvider'ı buraya ekliyoruz
        ChangeNotifierProvider(create: (_) => TaskProvider()), 
      ],
      child: MyApp(dbService: dbService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final DatabaseService dbService;

  const MyApp({super.key, required this.dbService});

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
      home: NavigationScreen(dbService: dbService),
    );
  }
}