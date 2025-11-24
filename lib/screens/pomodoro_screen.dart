import 'dart:async';
import 'package:flutter/material.dart';
import 'package:odak_list/utils/app_colors.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int focusDuration = 25 * 60; // 25 dakika
  static const int breakDuration = 5 * 60;  // 5 dakika

  int secondsRemaining = focusDuration;
  bool isRunning = false;
  bool isFocusMode = true; // Odaklanma mı Mola mı?
  Timer? timer;

  void startTimer() {
    if (timer != null) timer!.cancel();
    setState(() {
      isRunning = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
        } else {
          // Süre bitti
          stopTimer();
          // Modu değiştir (Mola <-> Odak)
          isFocusMode = !isFocusMode;
          secondsRemaining = isFocusMode ? focusDuration : breakDuration;
          // İsterseniz burada bildirim gönderebilirsiniz
        }
      });
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    stopTimer();
    setState(() {
      isFocusMode = true;
      secondsRemaining = focusDuration;
    });
  }

  String get timerText {
    final minutes = (secondsRemaining / 60).floor();
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = 1 - (secondsRemaining / (isFocusMode ? focusDuration : breakDuration));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFocusMode ? "ODAKLANMA ZAMANI" : "MOLA ZAMANI",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isFocusMode ? AppColors.primaryGradientStart : AppColors.categoryHome,
              ),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 15,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFocusMode ? AppColors.primaryGradientEnd : AppColors.categoryHome,
                    ),
                  ),
                ),
                Text(
                  timerText,
                  style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Başlat / Durdur Butonu
                ElevatedButton(
                  onPressed: isRunning ? stopTimer : startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning ? Colors.redAccent : AppColors.categoryWork,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    isRunning ? "DURDUR" : "BAŞLAT",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                // Sıfırla Butonu
                IconButton(
                  onPressed: resetTimer,
                  icon: const Icon(Icons.refresh, size: 32, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}