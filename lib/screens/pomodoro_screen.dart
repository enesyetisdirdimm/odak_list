import 'dart:async';
import 'package:flutter/material.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:provider/provider.dart'; // Provider
import 'package:odak_list/theme_provider.dart'; // Tema

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
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
    // --- DÜZELTME: Tema Rengi ---
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    double progress = remainingSeconds / initialSeconds;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton('Odaklan', focusTime, isDarkMode, themeProvider),
                    const SizedBox(width: 10),
                    _buildModeButton('Kısa Mola', shortBreakTime, isDarkMode, themeProvider),
                    const SizedBox(width: 10),
                    _buildModeButton('Uzun Mola', longBreakTime, isDarkMode, themeProvider),
                  ],
                ),
              ),
              
              const Spacer(),

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                      // --- DÜZELTME: Sayaç rengi ---
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentMode == 'Odaklan' 
                            ? themeProvider.secondaryColor // SEÇİLEN RENK
                            : AppColors.categoryHome, // Mola yeşil kalsın veya değişsin
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timerText,
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        currentMode,
                        style: TextStyle(
                          fontSize: 18,
                          color: subTextColor,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: toggleTimer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      // --- DÜZELTME: Buton Rengi ---
                      backgroundColor: isRunning ? AppColors.priorityHigh : themeProvider.secondaryColor,
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
                    icon: Icon(Icons.refresh, size: 32, color: subTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, int time, bool isDarkMode, ThemeProvider themeProvider) {
    bool isSelected = currentMode == mode;
    Color textColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    
    return GestureDetector(
      onTap: () => changeMode(mode, time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (isDarkMode ? Colors.grey.shade800 : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // --- DÜZELTME: Kenarlık Rengi ---
            color: isSelected ? themeProvider.primaryColor : Colors.transparent,
            width: 2
          ),
        ),
        child: Text(
          mode,
          style: TextStyle(
            // --- DÜZELTME: Metin Rengi ---
            color: isSelected ? themeProvider.primaryColor : textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}