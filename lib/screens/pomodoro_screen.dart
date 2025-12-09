import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';

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

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingSound; 
  bool _isSoundLoading = false; 

  final List<Map<String, dynamic>> _sounds = [
    {'id': 'rain', 'name': 'Yağmur', 'icon': Icons.water_drop, 'file': 'sounds/rain.mp3'},
    {'id': 'forest', 'name': 'Orman', 'icon': Icons.forest, 'file': 'sounds/forest.mp3'},
    {'id': 'cafe', 'name': 'Kafe', 'icon': Icons.coffee, 'file': 'sounds/cafe.mp3'},
  ];

 @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    WakelockPlus.disable(); 
    super.dispose();
  }

  Future<void> _toggleSound(String id, String fileName) async {
    if (_playingSound == id) {
      await _audioPlayer.stop();
      setState(() => _playingSound = null);
    } else {
      setState(() => _isSoundLoading = true);
      try {
        await _audioPlayer.stop(); 
        await _audioPlayer.setReleaseMode(ReleaseMode.loop); 
        await _audioPlayer.play(AssetSource(fileName));
        setState(() => _playingSound = id);
      } catch (e) {
        print("Ses hatası: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ses dosyası bulunamadı! assets/sounds klasörünü kontrol et."))
        );
      } finally {
        setState(() => _isSoundLoading = false);
      }
    }
  }

  void toggleTimer() {
    HapticFeedback.selectionClick();
    if (isRunning) {
      _timer?.cancel();
      WakelockPlus.disable(); 
      setState(() => isRunning = false);
    } else {
      setState(() => isRunning = true);
      WakelockPlus.enable(); 
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
    WakelockPlus.disable(); 
    setState(() => isRunning = false);
    NotificationService().showInstantNotification(); 
    
    _audioPlayer.stop();
    setState(() => _playingSound = null);

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
    HapticFeedback.selectionClick();
    _timer?.cancel();
    _audioPlayer.stop(); 
    setState(() {
      isRunning = false;
      remainingSeconds = initialSeconds;
      _playingSound = null;
    });
  }

  void changeMode(String mode, int seconds) {
    _timer?.cancel();
    _audioPlayer.stop(); 
    setState(() {
      currentMode = mode;
      initialSeconds = seconds;
      remainingSeconds = seconds;
      isRunning = false;
      _playingSound = null;
    });
  }

  String get timerText {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;

    double progress = remainingSeconds / initialSeconds;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        // WEB İÇİN DÜZELTME: Maksimum genişlik 600px
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mod Seçimi
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

                  // Sayaç
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            currentMode == 'Odaklan' 
                                ? themeProvider.secondaryColor 
                                : AppColors.categoryHome,
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

                  const SizedBox(height: 30),

                  // --- ODAK SESLERİ MENÜSÜ ---
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDarkMode ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Odak Sesleri",
                          style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _sounds.map((sound) {
                            bool isPlaying = _playingSound == sound['id'];
                            return GestureDetector(
                              onTap: () => _toggleSound(sound['id'], sound['file']),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isPlaying 
                                          ? themeProvider.secondaryColor 
                                          : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                                      shape: BoxShape.circle,
                                      boxShadow: isPlaying ? [
                                        BoxShadow(color: themeProvider.secondaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))
                                      ] : [],
                                    ),
                                    child: Icon(
                                      sound['icon'], 
                                      color: isPlaying ? Colors.white : subTextColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(sound['name'], style: TextStyle(fontSize: 12, color: isPlaying ? themeProvider.secondaryColor : subTextColor, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Kontrol Butonları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: toggleTimer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
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
            color: isSelected ? themeProvider.primaryColor : Colors.transparent,
            width: 2
          ),
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: isSelected ? themeProvider.primaryColor : textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}