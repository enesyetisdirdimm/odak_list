import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // DİKKAT: Android ikonunu açıkça belirtiyoruz
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print("Bildirime tıklandı: ${details.payload}");
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Tüm izinleri sırasıyla iste
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  // --- YENİ: ANLIK TEST FONKSİYONU ---
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'odak_channel_v3', // KANAL ID DEĞİŞTİ (Eskisi takılı kalmasın diye)
      'Odak Test Kanalı',
      channelDescription: 'Test bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      999, // Test ID
      'Test Bildirimi',
      'Bu bildirim geldiyse sistem çalışıyor demektir!',
      details,
    );
  }

  // ZAMANLI BİLDİRİM
 Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // 1. Şimdiki zamanı ve planlanan zamanı konsola yazdır
    final now = DateTime.now();
    print("--------------------------------------------------");
    print("BİLDİRİM TESTİ BAŞLIYOR");
    print("Şu anki saat (Cihaz): $now");
    print("Planlanan saat (Gelen): $scheduledTime");
    
    // 2. Geçmiş zaman kontrolü
    if (scheduledTime.isBefore(now)) {
      print("HATA: Seçilen saat geçmişte kalmış! Bildirim kurulmayacak.");
      return;
    }

    try {
      // 3. Timezone dönüşümü
      final tzLocation = tz.local;
      final tzScheduledDate = tz.TZDateTime.from(scheduledTime, tzLocation);
      print("Timezone ile ayarlanmış saat: $tzScheduledDate");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'odak_channel_v3', 
            'Odak Test Kanalı',
            channelDescription: 'Görev hatırlatıcıları',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // Bu satır, telefon kilitliyken bile bildirimi zorla gösterir
            fullScreenIntent: true, 
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("BAŞARILI: Bildirim sisteme teslim edildi.");
      print("--------------------------------------------------");
    } catch (e) {
      print("KRİTİK HATA: Bildirim kurulamadı. Sebebi: $e");
    }
  }
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}