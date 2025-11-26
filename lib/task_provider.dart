import 'package:flutter/material.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/sub_task.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:home_widget/home_widget.dart'; // Widget Paketi

class TaskProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Task> _tasks = [];
  List<Project> _projects = [];
  bool _isLoading = true;

  List<Task> get tasks => _tasks;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  TaskProvider() {
    loadData();
  }

  // --- WIDGET GÜNCELLEME (ANA EKRAN İÇİN) ---
  Future<void> _updateHomeWidget() async {
    try {
      DateTime now = DateTime.now();
      // Bugünün tamamlanmamış görevlerini say
      int todayPendingCount = _tasks.where((t) {
        if (t.isDone) return false;
        if (t.dueDate == null) return false;
        
        return t.dueDate!.year == now.year && 
               t.dueDate!.month == now.month && 
               t.dueDate!.day == now.day;
      }).length;

      // Verileri Android tarafına gönder
      await HomeWidget.saveWidgetData<String>('title', 'Bugün Kalan');
      await HomeWidget.saveWidgetData<String>('task_count', todayPendingCount.toString());
      
      // Widget'ı güncelle
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
    // notifyListeners(); // Ekran titremesini önlemek için kapalı tutabilirsin
    
    final fetchedProjects = await _dbService.getProjectsWithStats();
    final fetchedTasks = await _dbService.getTasks();

    _projects = fetchedProjects;
    _tasks = fetchedTasks;
    _isLoading = false;
    
    // Veri her yüklendiğinde Widget'ı da güncelle
    _updateHomeWidget();
    
    notifyListeners();
  }

  // --- GÖREV EKLEME ---
  Future<void> addTask(Task task) async {
    Task createdTask = await _dbService.createTask(task);
    _scheduleTaskNotification(createdTask);
    await loadData();
  }

  // --- GÖREV GÜNCELLEME ---
  Future<void> updateTask(Task task) async {
    await _dbService.updateTask(task);
    _scheduleTaskNotification(task);
    await loadData();
  }

  // --- GÖREV SİLME ---
  Future<void> deleteTask(int id) async {
    await _dbService.deleteTask(id);
    await _notificationService.cancelNotification(id);
    await loadData();
  }

  // --- GÖREV DURUMUNU DEĞİŞTİR (TEKRAR MANTIĞI BURADA) ---
  Future<void> toggleTaskStatus(Task task) async {
    // Eğer görev henüz tamamlanmadıysa, tekrarlıysa ve tarihi varsa:
    if (!task.isDone && task.recurrence != 'none' && task.dueDate != null) {
      
      // 1. Mevcut görevi "Tamamlandı" yap
      task.isDone = true;
      await _dbService.updateTask(task); 
      await _notificationService.cancelNotification(task.id!);

      // 2. Yeni tarihi hesapla (Bir sonraki döngü)
      DateTime nextDate = task.dueDate!;
      switch (task.recurrence) {
        case 'daily':
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day, nextDate.hour, nextDate.minute);
          break;
      }

      // 3. Yeni bir görev oluştur (Klonla)
      Task newTask = Task(
        title: task.title,
        isDone: false, // Yeni görev henüz yapılmadı
        dueDate: nextDate,
        category: task.category,
        priority: task.priority,
        notes: task.notes,
        projectId: task.projectId,
        recurrence: task.recurrence, // Döngü devam etsin
        tags: List.from(task.tags), // Etiketleri kopyala
        subTasks: task.subTasks.map((s) => SubTask(title: s.title, isDone: false)).toList(),
      );

      // Yeni görevi veritabanına ekle
      await addTask(newTask); 

    } else {
      // Normal görevse sadece durumunu değiştir
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