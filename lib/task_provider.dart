// Dosya: lib/task_provider.dart

import 'dart:async'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/sub_task.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:odak_list/models/team_member.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TaskProvider extends ChangeNotifier {

  // Okunmuş görevlerin takibi
  Map<String, DateTime> _taskLastViewed = {};

  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  List<Task> _tasks = [];
  List<Project> _projects = [];
  List<TeamMember> _teamMembers = []; 
  
  // Uygulama açılışında profil kontrolü bitene kadar true kalır
  bool _isLoading = true;
  
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;
  
  // Premium Durumu
  bool _isPremium = false; 

  // CANLI TAKİP İÇİN ABONELİKLER
  StreamSubscription? _authSubscription;
  StreamSubscription? _projectsSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _membersSubscription; 

  // PROFİL YÖNETİMİ
  TeamMember? _currentMember; 
  
  // GETTER'LAR
  TeamMember? get currentMember => _currentMember;
  List<TeamMember> get teamMembers => _teamMembers;
  List<Task> get tasks => _tasks;
  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  bool get isPremium => _isPremium; 

  // YETKİ KONTROLÜ
  bool get isAdmin => _currentMember?.role == 'admin';

  TaskProvider() {
    _loadSettings();
    _loadReadStatus();
    _initAuthListener(); 
  }

  // --- PROFİL İŞLEMLERİ ---
  
  Future<void> selectMember(TeamMember member) async {
    _currentMember = member;
    
    // 1. Premium Durumunu Kontrol Et
    _isPremium = await _dbService.checkPremiumStatus();

    // 2. FCM TOKEN İŞLEMLERİ (Push Bildirim İçin)
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        if (token != null) {
          // Veritabanına kaydet
          await _dbService.updateMemberToken(member.id, token);
        }
      }
    } catch (e) {
      print("Token hatası: $e");
    }

    // 3. Profili hafızaya kaydet (Oto Giriş İçin)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_member_id', member.id);
    
    // 4. Otomatik Veri Kurtarma (Eski verileri sahiplen)
    _dbService.claimOldData().then((count) {
      if (count > 0) print("Otomatik Kurtarma: $count veri eklendi.");
    });

    _refreshNotifications();
    notifyListeners(); 
  }

  Future<void> logoutMember() async {
    _currentMember = null;
    _isPremium = false;
    
    // Hafızadan sil
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_member_id');
    
    notifyListeners();
  }
  
  String? getMemberName(String? memberId) {
    if (memberId == null) return null;
    try {
      return _teamMembers.firstWhere((m) => m.id == memberId).name;
    } catch (e) {
      return null;
    }
  }

  // --- 1. KULLANICIYI DİNLE ---
  void _initAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _clearData();
      } else {
        _startListeningToData();
      }
    });
  }

  // --- 2. VERİLERİ CANLI DİNLE ---
  void _startListeningToData() {
    // Yükleme başladı, profil bulunana kadar bekle
    _isLoading = true;
    notifyListeners();

    _projectsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _membersSubscription?.cancel();

    // Otomatik Veri Kurtarma
    _dbService.claimOldData();

    // 1. Ekip Üyelerini Dinle ve OTO GİRİŞ YAP
    _membersSubscription = _dbService.getTeamMembersStream().listen((membersData) async {
      _teamMembers = membersData;
      
      // Eğer seçili üye yoksa ama hafızada kayıtlıysa, otomatik seç
      if (_currentMember == null) {
        final prefs = await SharedPreferences.getInstance();
        final savedId = prefs.getString('saved_member_id');
        
        if (savedId != null && membersData.isNotEmpty) {
          try {
            // Kayıtlı kişiyi bul ve seç
            _currentMember = membersData.firstWhere((m) => m.id == savedId);
            
            // Oto girişte de Premium kontrolü yap
            _isPremium = await _dbService.checkPremiumStatus();
            
            // Profil yüklendiği için bildirimleri de tazele
            _refreshNotifications();
          } catch (e) {
            // Kişi silinmiş olabilir, hafızayı temizle
            await prefs.remove('saved_member_id');
          }
        }
      }
      
      // Profil kontrolü bitti, ekranı açabiliriz
      _isLoading = false;
      notifyListeners();
    });

    // 2. Projeleri Dinle
    _projectsSubscription = _dbService.getProjectsStream().listen((projectsData) {
      _projects = projectsData;
      _calculateStats();
      notifyListeners();
    });

    // 3. Görevleri Dinle ve BİLDİRİMLERİ KUR
    _tasksSubscription = _dbService.getTasksStream().listen((tasksData) {
      _tasks = tasksData;
      _calculateStats();
      _updateHomeWidget();
      
      // Veritabanından her veri geldiğinde bildirimleri tara
      if (_currentMember != null) {
        _refreshNotifications();
      }

      notifyListeners();
    });
  }

  // Tüm görevler için bildirimleri tazele
  void _refreshNotifications() {
    for (var task in _tasks) {
      _scheduleTaskNotification(task);
    }
  }

  void _clearData() {
    _projects = [];
    _tasks = [];
    _teamMembers = [];
    _currentMember = null;
    _isPremium = false;
    
    _projectsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _membersSubscription?.cancel();
    
    _isLoading = false;
    notifyListeners();
  }

  void _calculateStats() {
    if (_projects.isEmpty || _tasks.isEmpty) return;

    for (var project in _projects) {
      var projectTasks = _tasks.where((t) => t.projectId == project.id).toList();
      project.taskCount = projectTasks.length;
      project.completedTaskCount = projectTasks.where((t) => t.isDone).length;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _projectsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _membersSubscription?.cancel();
    super.dispose();
  }

  // --- AYARLAR VE OKUNDU BİLGİSİ ---
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    notifyListeners();
  }

  // Görevi "Okundu" işaretle (Saat farkı düzeltmesiyle)
  Future<void> markTaskAsRead(String taskId) async {
    DateTime now = DateTime.now();
    
    // 1. Görevi listeden bul
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      
      // 2. Eğer görevin son yorum tarihi varsa ve bizim saatimizden ilerideyse
      // (veya eşitse), okundu sayılmak için tarihi yorum tarihinden biraz sonraya al.
      if (task.lastCommentAt != null) {
        if (task.lastCommentAt!.isAfter(now) || task.lastCommentAt!.isAtSameMomentAs(now)) {
          now = task.lastCommentAt!.add(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      // Görev bulunamazsa normal devam et
    }

    _taskLastViewed[taskId] = now; 
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('viewed_$taskId', now.toIso8601String()); 
    
    notifyListeners();
  }

  bool hasUnreadComments(Task task) {
    if (task.id == null || task.lastCommentAt == null) return false;
    
    DateTime? lastViewed = _taskLastViewed[task.id!];
    
    // Eğer hiç görmediyse (null) ve yorum varsa -> UNREAD
    if (lastViewed == null) return true; 
    
    // Son yorum tarihi > Son görme tarihi ise -> UNREAD
    return task.lastCommentAt!.isAfter(lastViewed);
  }

  Future<void> _loadReadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('viewed_')) {
        String taskId = key.replaceFirst('viewed_', '');
        String? dateStr = prefs.getString(key);
        if (dateStr != null) {
          _taskLastViewed[taskId] = DateTime.parse(dateStr);
        }
      }
    }
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
      int total = _tasks.length;
      int done = _tasks.where((t) => t.isDone).length;
      String dateStr = DateFormat('d MMMM, EEEE', 'tr_TR').format(now);

      await HomeWidget.saveWidgetData<String>('title', 'OdakList');
      await HomeWidget.saveWidgetData<String>('date_str', dateStr);
      await HomeWidget.saveWidgetData<int>('done_count', done);
      await HomeWidget.saveWidgetData<int>('total_count', total);
      await HomeWidget.updateWidget(name: 'OdakWidget', androidName: 'OdakWidget');
    } catch (e) {}
  }

  // --- GÖREV İŞLEMLERİ (CRUD) ---
  
  Future<void> addTask(Task task) async {
    // DÜZELTME: creatorId, Auth UID olmalı ki Cloud Function doğru klasöre baksın.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      task.creatorId = user.uid;
    }
    
    // Oluşturulma zamanını ekle
    task.createdAt = DateTime.now();
    
    Task createdTask = await _dbService.createTask(task);
    
    // Log kaydında isim görünmesi için member ismini kullanabiliriz
    if (_currentMember != null) {
      await _dbService.addActivityLog(
        createdTask.id!, 
        _currentMember!.name, 
        "Görevi oluşturdu."
      );
    }
  }

  Future<void> updateTask(Task task) async {
    await _dbService.updateTask(task);
  }

  Future<void> deleteTask(String id) async {
    await _dbService.deleteTask(id);
    await _notificationService.cancelNotification(id.hashCode);
  }

  bool canCompleteTask(Task task) {
    if (isAdmin) return true;
    if (task.assignedMemberId == null) return true;
    return task.assignedMemberId == _currentMember?.id;
  }

  Future<void> toggleTaskStatus(Task task) async {
    // Otomatik Sahiplenme
    if (!task.isDone && task.assignedMemberId == null && _currentMember != null) {
      task.assignedMemberId = _currentMember!.id;
    }

    if (!task.isDone) {
      if (_isVibrationEnabled) HapticFeedback.heavyImpact();
      if (_isSoundEnabled) {
        try {
          await _sfxPlayer.stop();
          await _sfxPlayer.setSource(AssetSource('sounds/success.mp3'));
          await _sfxPlayer.resume();
        } catch (e) {}
      }
    } else {
      if (_isVibrationEnabled) HapticFeedback.lightImpact();
    }

    // Tekrarlayan Görevler
    if (!task.isDone && task.recurrence != 'none' && task.dueDate != null) {
      task.isDone = true;
      await _dbService.updateTask(task); 
      await _notificationService.cancelNotification(task.id!.hashCode);
      
      if (task.id != null && _currentMember != null) {
         await _dbService.addActivityLog(task.id!, _currentMember!.name, "Görevi tamamladı (Tekrarlandı).");
      }

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
        assignedMemberId: task.assignedMemberId,
        creatorId: task.creatorId,
        recurrence: task.recurrence,
        tags: List.from(task.tags),
        subTasks: task.subTasks.map((s) => SubTask(title: s.title, isDone: false)).toList(),
      );
      await addTask(newTask); 
    } else {
      // Normal Görev
      bool isNowDone = !task.isDone;
      task.isDone = !task.isDone;
      await updateTask(task);

      if (task.id != null && _currentMember != null) {
         await _dbService.addActivityLog(
           task.id!, 
           _currentMember!.name, 
           isNowDone ? "Görevi tamamladı. ✅" : "Görevi tekrar açtı."
         );
      }
    }
  }

  // --- BİLDİRİM MANTIĞI ---
  Future<void> _scheduleTaskNotification(Task task) async {
    if (task.id == null) return;
    
    // Önce mevcutsa iptal et
    await _notificationService.cancelNotification(task.id!.hashCode);
    
    // Geçmiş veya tamamlanmışlara kurma
    if (task.isDone || task.dueDate == null || task.dueDate!.isBefore(DateTime.now())) {
      return;
    }

    // FİLTRE: Sadece bana aitse veya havuzdaysa
    bool isAssignedToMe = task.assignedMemberId == _currentMember?.id;
    bool isUnassigned = task.assignedMemberId == null;

    if (isAssignedToMe || isUnassigned) {
      await _notificationService.scheduleNotification(
        id: task.id!.hashCode,
        title: task.recurrence != 'none' ? "Tekrarlayan: ${task.title}" : "Hatırlatıcı: ${task.title}",
        body: isAssignedToMe 
            ? "Bu görev senin sorumluluğunda, zamanı geldi!" 
            : "Havuzdaki bir görevin zamanı geldi!",
        scheduledTime: task.dueDate!,
      );
    }
  }

  // --- PROJE İŞLEMLERİ ---
  Future<void> addProject(Project project) async {
    await _dbService.createProject(project);
  }

  Future<bool> deleteProject(String projectId) async {
    // 1. Son Proje Kontrolü
   /* if (_projects.length <= 1) {
      return false; // Silme başarısız (Son proje silinemez)
    }*/

    // 2. Veritabanından Sil
    await _dbService.deleteProject(projectId);

    // 3. Eğer sildiğimiz proje şu an ekranda açıksa, başkasına geç (Hata vermesin)
    // Not: UI tarafında _selectedProjectId'yi kontrol edeceğiz ama burada da listeyi tazeleyelim.
    return true; // Başarılı
  }
  Future<void> restoreProjectData(Project project, List<Task> projectTasks) async {
    // 1. Projeyi geri getir
    await _dbService.restoreProject(project);
    
    // 2. İçindeki görevleri tek tek geri getir
    for (var task in projectTasks) {
      await _dbService.restoreTask(task);
    }
    
    // Not: Stream dinlediği için listeler otomatik güncellenir
  }
  
  Future<void> deleteProjectWithTransfer(String projectId, String targetProjectId) async {
    // 1. Görevleri yeni projeye taşı
    await _dbService.moveTasksToProject(projectId, targetProjectId);
    
    // 2. Eski projeyi sil (Artık içi boş olduğu için güvenli)
    await _dbService.deleteProject(projectId);
  }
}