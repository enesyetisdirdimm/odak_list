import 'dart:async';
import 'package:flutter/material.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/utils/app_colors.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // Süre Tanımları (Saniye cinsinden)
  static const int focusTime = 25 * 60;
  static const int shortBreakTime = 5 * 60;
  static const int longBreakTime = 15 * 60;

  int remainingSeconds = focusTime;
  int initialSeconds = focusTime; 
  
  Timer? _timer;
  bool isRunning = false;
  String currentMode = 'Odaklan';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void toggleTimer() {
    if (isRunning) {
      _timer?.cancel();
      setState(() => isRunning = false);
    } else {
      setState(() => isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds > 0) {
          setState(() => remainingSeconds--);
        } else {
          _finishTimer();
        }
      });
    }
  }

  void _finishTimer() {
    _timer?.cancel();
    setState(() => isRunning = false);

    NotificationService().showInstantNotification(); 
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Süre Doldu!"),
        content: Text("$currentMode süresi tamamlandı."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tamam"),
          )
        ],
      ),
    );
  }

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
      remainingSeconds = initialSeconds;
    });
  }

  void changeMode(String mode, int seconds) {
    _timer?.cancel();
    setState(() {
      currentMode = mode;
      initialSeconds = seconds;
      remainingSeconds = seconds;
      isRunning = false;
    });
  }

  String get timerText {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double progress = remainingSeconds / initialSeconds;

    return Scaffold(
      backgroundColor: AppColors.background,
      // DÜZELTME: SafeArea widget'ı eklendi.
      // Bu widget, içeriği çentik ve sistem barlarından korur.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Üst Kısım: Mod Seçimi
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton('Odaklan', focusTime),
                    const SizedBox(width: 10),
                    _buildModeButton('Kısa Mola', shortBreakTime),
                    const SizedBox(width: 10),
                    _buildModeButton('Uzun Mola', longBreakTime),
                  ],
                ),
              ),
              
              const Spacer(),

              // Orta Kısım: Sayaç
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentMode == 'Odaklan' 
                            ? AppColors.primaryGradientStart 
                            : AppColors.categoryHome,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timerText,
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        currentMode,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Alt Kısım: Butonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: toggleTimer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      backgroundColor: isRunning ? AppColors.priorityHigh : AppColors.primaryGradientEnd,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      isRunning ? "DURAKLAT" : "BAŞLAT",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: resetTimer,
                    icon: const Icon(Icons.refresh, size: 32, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Alt boşluk
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, int time) {
    bool isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => changeMode(mode, time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGradientStart : Colors.transparent,
            width: 2
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)
            )
          ] : [],
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: isSelected ? AppColors.primaryGradientStart : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}