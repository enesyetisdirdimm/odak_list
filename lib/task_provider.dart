import 'package:flutter/material.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/sub_task.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart'; // <-- İŞTE EKSİK OLAN BU SATIRDI!
import 'package:flutter/services.dart'; // Titreşim için şart
import 'package:audioplayers/audioplayers.dart'; // Ses için şart
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final AudioPlayer _sfxPlayer = AudioPlayer(); // Efekt sesleri için


  List<Task> _tasks = [];
  List<Project> _projects = [];
  bool _isLoading = true;

  List<Task> get tasks => _tasks;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;

  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;

  TaskProvider() {
    _loadSettings();
    loadData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true; // Varsayılan: Açık
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true; // Varsayılan: Açık
    notifyListeners();
  }

  Future<void> toggleSound(bool value) async {
    _isSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    notifyListeners();
  }

  Future<void> toggleVibration(bool value) async {
    _isVibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }

  // --- WIDGET GÜNCELLEME ---
  Future<void> _updateHomeWidget() async {
    try {
      DateTime now = DateTime.now();
      
      // Bugünün tüm görevlerini bul (Tamamlanan + Bekleyen)
      var todayTasks = _tasks.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.year == now.year && 
               t.dueDate!.month == now.month && 
               t.dueDate!.day == now.day;
      }).toList();

      int total = todayTasks.length;
      int done = todayTasks.where((t) => t.isDone).length;
      
      // Tarih formatı (örn: 27 Kasım, Çarşamba)
      // initializeDateFormatting'i main'de çağırdığımız için burada çalışır
      String dateStr = DateFormat('d MMMM, EEEE', 'tr_TR').format(now);

      // Verileri Gönder
      await HomeWidget.saveWidgetData<String>('date_str', dateStr);
      await HomeWidget.saveWidgetData<int>('done_count', done);
      await HomeWidget.saveWidgetData<int>('total_count', total);
      
      await HomeWidget.updateWidget(
        name: 'OdakWidget',
        androidName: 'OdakWidget',
      );
    } catch (e) {
      debugPrint("Widget güncelleme hatası: $e");
    }
  }

  // --- VERİLERİ YÜKLE ---
  Future<void> loadData() async {
    _isLoading = true;
    final fetchedProjects = await _dbService.getProjectsWithStats();
    final fetchedTasks = await _dbService.getTasks();

    _projects = fetchedProjects;
    _tasks = fetchedTasks;
    _isLoading = false;
    
    // Veri her yüklendiğinde Widget'ı da güncelle
    _updateHomeWidget();
    
    notifyListeners();
  }

  // --- GÖREV İŞLEMLERİ ---

  Future<void> addTask(Task task) async {
    Task createdTask = await _dbService.createTask(task);
    _scheduleTaskNotification(createdTask);
    await loadData();
  }

  Future<void> updateTask(Task task) async {
    await _dbService.updateTask(task);
    _scheduleTaskNotification(task);
    await loadData();
  }

  Future<void> deleteTask(int id) async {
    await _dbService.deleteTask(id);
    await _notificationService.cancelNotification(id);
    await loadData();
  }

  // --- GÖREV DURUMUNU DEĞİŞTİR (TEKRAR MANTIĞI) ---
 Future<void> toggleTaskStatus(Task task) async {
    // 1. TİTREŞİM VE SES EFEKTİ (Kontrollü)
    if (!task.isDone) {
      // Görev tamamlanıyorsa
      
      // TİTREŞİM AÇIKSA TİTRE
      if (_isVibrationEnabled) {
        HapticFeedback.heavyImpact(); 
      }

      // SES AÇIKSA ÇAL
      if (_isSoundEnabled) {
        try {
          await _sfxPlayer.stop();
          await _sfxPlayer.setSource(AssetSource('sounds/success.mp3'));
          await _sfxPlayer.resume();
        } catch (e) {
          // Ses hatası
        }
      }

    } else {
      // Görev geri alınıyorsa (Sadece hafif titreşim, eğer açıksa)
      if (_isVibrationEnabled) {
        HapticFeedback.lightImpact();
      }
    }

    // 2. NORMAL MANTIK (Aynı kalacak)
    if (!task.isDone && task.recurrence != 'none' && task.dueDate != null) {
      task.isDone = true;
      await _dbService.updateTask(task); 
      await _notificationService.cancelNotification(task.id!);

      DateTime nextDate = task.dueDate!;
      switch (task.recurrence) {
        case 'daily': nextDate = nextDate.add(const Duration(days: 1)); break;
        case 'weekly': nextDate = nextDate.add(const Duration(days: 7)); break;
        case 'monthly': nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day, nextDate.hour, nextDate.minute); break;
      }

      Task newTask = Task(
        title: task.title,
        isDone: false,
        dueDate: nextDate,
        category: task.category,
        priority: task.priority,
        notes: task.notes,
        projectId: task.projectId,
        recurrence: task.recurrence,
        tags: List.from(task.tags),
        subTasks: task.subTasks.map((s) => SubTask(title: s.title, isDone: false)).toList(),
      );
      await addTask(newTask); 
    } else {
      task.isDone = !task.isDone;
      await updateTask(task);
    }
  }

  // --- BİLDİRİM AYARLA ---
  Future<void> _scheduleTaskNotification(Task task) async {
    await _notificationService.cancelNotification(task.id!);
    
    if (!task.isDone && task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: task.id!,
        title: task.recurrence != 'none' ? "Tekrarlayan: ${task.title}" : "Hatırlatıcı: ${task.title}",
        body: "Görevinizin zamanı geldi!",
        scheduledTime: task.dueDate!,
      );
    }
  }

  // --- PROJE İŞLEMLERİ ---
  Future<void> addProject(Project project) async {
    await _dbService.createProject(project);
    await loadData();
  }

  Future<void> deleteProject(int id) async {
    await _dbService.deleteProject(id);
    await loadData();
  }
}