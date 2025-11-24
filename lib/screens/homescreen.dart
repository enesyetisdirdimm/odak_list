import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/widgets/task_card.dart';

class HomeScreen extends StatefulWidget {
  final DatabaseService dbService;
  const HomeScreen({super.key, required this.dbService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  bool isLoading = true;

  final Map<String, Color> _categories = {
    'İş': AppColors.categoryWork,
    'Ev': AppColors.categoryHome,
    'Okul': AppColors.categorySchool,
    'Kişisel': AppColors.categoryPersonal,
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    try {
      final tasks = await widget.dbService.getTasks();
      setState(() {
        _tasks = tasks;
        isLoading = false;
      });
    } catch (e) {
      print("Görevler yüklenirken hata: $e");
      setState(() => isLoading = false);
    }
  }

  // Görev Ekleme/Düzenleme Sayfasına Git
  void _navigateToDetail([Task? task]) async {
    // await kullanıyoruz, böylece o sayfadan geri dönüldüğünde kod buraya devam eder
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task ?? Task(title: ''), // Yeni ise boş task, değilse mevcudu gönder
          dbService: widget.dbService,
        ),
      ),
    );
    // Geri dönüldüğünde listeyi yenile
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final activeTasksList = _tasks.where((t) => !t.isDone).toList();
    final completedTasksList = _tasks.where((t) => t.isDone).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Bugünün Görevleri',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.red),
            onPressed: () async {
               // Servisi çağırıp anlık bildirim at
               await NotificationService().showInstantNotification();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadTasks,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text("Henüz görev yok", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    // Aktif Görevler
                    if (activeTasksList.isNotEmpty)
                       Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("YAPILACAKLAR (${activeTasksList.length})", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ...activeTasksList.map((task) => TaskCard(
                          task: task,
                          categories: _categories,
                          onTap: () => _navigateToDetail(task),
                          onToggleDone: () async {
                            task.isDone = !task.isDone;
                            await widget.dbService.updateTask(task);
                            _loadTasks();
                          },
                        )),

                    // Tamamlanan Görevler
                    if (completedTasksList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("TAMAMLANANLAR (${completedTasksList.length})", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ...completedTasksList.map((task) => TaskCard(
                          task: task,
                          categories: _categories,
                          onTap: () => _navigateToDetail(task),
                          onToggleDone: () async {
                            task.isDone = !task.isDone;
                            await widget.dbService.updateTask(task);
                            _loadTasks();
                          },
                        )),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToDetail(),
        label: const Text("Yeni Görev"),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryGradientEnd,
      ),
    );
  }
}