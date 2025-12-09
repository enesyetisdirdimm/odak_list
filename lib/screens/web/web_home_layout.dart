import 'package:flutter/material.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/screens/settings_screen.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/services/database_service.dart';

class WebHomeLayout extends StatefulWidget {
  final DatabaseService dbService;
  const WebHomeLayout({super.key, required this.dbService});

  @override
  State<WebHomeLayout> createState() => _WebHomeLayoutState();
}

class _WebHomeLayoutState extends State<WebHomeLayout> with SingleTickerProviderStateMixin {
  Task? _selectedTask;
  String? _selectedProjectId; 
  bool _showOnlyMyTasks = false; 
  bool _isSidebarOpen = true; 

  late TabController _tabController;
  final ScrollController _taskScrollController = ScrollController();
  final ScrollController _projectScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskScrollController.dispose();
    _projectScrollController.dispose();
    super.dispose();
  }

  // --- DİYALOGLAR (Aynı) ---
  void _showSettingsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: SizedBox(width: 500, height: 750, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: const SettingsScreen()))));
  }

  void _showTransferDialog(Project project, List<Project> otherProjects, TaskProvider provider) {
    String selectedTargetId = otherProjects.first.id!;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) => AlertDialog(title: const Text("Görevleri Aktar"), content: Column(mainAxisSize: MainAxisSize.min, children: [Text("'${project.title}' görevlerini taşı:", style: const TextStyle(fontSize: 14)), DropdownButtonFormField<String>(value: selectedTargetId, items: otherProjects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))).toList(), onChanged: (val) => setState(() => selectedTargetId = val!)), const Text("Proje silinecektir.", style: TextStyle(fontSize: 12, color: Colors.grey))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await provider.deleteProjectWithTransfer(project.id!, selectedTargetId); if (mounted && _selectedProjectId == project.id) setState(() => _selectedProjectId = selectedTargetId); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Görevler aktarıldı ve proje silindi."))); }, child: const Text("Aktar ve Sil"))])));
  }

  void _confirmProjectDelete(Project project, TaskProvider provider, int taskCount, List<Task> allTasks, ThemeProvider themeProvider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Projeyi Sil"), content: taskCount > 0 ? Text("⚠️ $taskCount görev var. Silinsin mi?") : const Text("Silinsin mi?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { final projectBackup = project; final tasksBackup = allTasks.where((t) => t.projectId == project.id).toList(); await provider.deleteProject(project.id!); if (ctx.mounted) Navigator.pop(ctx); if (mounted && _selectedProjectId == project.id) setState(() => _selectedProjectId = null); if (mounted) { ScaffoldMessenger.of(context).clearSnackBars(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${project.title}' silindi."), behavior: SnackBarBehavior.floating, width: 400, action: SnackBarAction(label: 'GERİ AL', textColor: themeProvider.secondaryColor, onPressed: () async { await provider.restoreProjectData(projectBackup, tasksBackup); }))); } }, child: const Text("Sil"))]));
  }

  void _deleteTaskWithUndo(Task task, TaskProvider provider, ThemeProvider themeProvider) async {
    final backupTask = task; 
    await provider.deleteTask(task.id!);
    if (_selectedTask?.id == task.id) setState(() => _selectedTask = null);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${task.title}' silindi"), behavior: SnackBarBehavior.floating, width: 400, action: SnackBarAction(label: 'GERİ AL', textColor: themeProvider.secondaryColor, onPressed: () async { await widget.dbService.restoreTask(backupTask); })));
    }
  }

  void _showAddProjectDialog(BuildContext context, TaskProvider taskProvider) {
    final controller = TextEditingController(); Color selectedColor = Colors.blue;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) => AlertDialog(title: const Text("Yeni Proje"), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: controller, decoration: const InputDecoration(hintText: "Proje Adı")), const SizedBox(height: 10), Wrap(spacing: 8, children: [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.indigo].map((c) => GestureDetector(onTap: () => setState(() => selectedColor = c), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: selectedColor == c ? Border.all(width: 2) : null)))).toList())]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () async { if (controller.text.isNotEmpty) { await taskProvider.addProject(Project(title: controller.text, colorValue: selectedColor.value)); Navigator.pop(ctx); } }, child: const Text("Ekle"))])));
  }

  void _showAddTaskDialog(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    if (taskProvider.projects.isEmpty) { _showAddProjectDialog(context, taskProvider); return; }
    String defaultProjectId = _selectedProjectId ?? taskProvider.projects.first.id!;
    showDialog(context: context, builder: (context) => Dialog(backgroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: SizedBox(width: 600, height: 800, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: TaskDetailScreen(task: Task(title: '', projectId: defaultProjectId), dbService: widget.dbService, isEmbeddedWeb: false)))));
  }

  // ==========================================
  // ARAYÜZ
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    
    // RENKLER
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5); 
    final Color sidebarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    // SAĞ PANEL RENGİ: TAM BEYAZ
    final Color detailColor = isDark ? const Color(0xFF1E1E1E) : Colors.white; 
    
    List<Task> filteredTasks = taskProvider.tasks;
    if (_selectedProjectId != null) filteredTasks = filteredTasks.where((t) => t.projectId == _selectedProjectId).toList();
    if (_showOnlyMyTasks) {
      final myId = taskProvider.currentMember?.id;
      if (myId != null) filteredTasks = filteredTasks.where((t) => t.assignedMemberId == myId).toList();
    }
    
    final activeTasks = filteredTasks.where((t) => !t.isDone).toList();
    final completedTasks = filteredTasks.where((t) => t.isDone).toList();
    activeTasks.sort((a, b) => (a.dueDate ?? DateTime(2100)).compareTo(b.dueDate ?? DateTime(2100)));
    completedTasks.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------
          // SÜTUN 1: SIDEBAR (Sadece Yazı)
          // -----------------------------------------------------
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 260 : 0, 
            child: Container(
              color: sidebarColor,
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: 260, minWidth: 260, alignment: Alignment.topLeft,
                  child: Column(
                    children: [
                      // --- LOGO YOK, SADECE YAZI ---
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                        child: Row(
                          children: [
                            // Logo icon/image kaldırıldı
                            Text("CoFocus", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildSidebarItem(icon: Icons.dashboard_outlined, title: "Genel Bakış", count: taskProvider.tasks.length, isSelected: _selectedProjectId == null && !_showOnlyMyTasks, onTap: () => setState(() { _selectedProjectId = null; _showOnlyMyTasks = false; }), theme: themeProvider),
                            _buildSidebarItem(icon: Icons.account_circle_outlined, title: "Bana Atananlar", count: taskProvider.tasks.where((t) => t.assignedMemberId == taskProvider.currentMember?.id).length, isSelected: _showOnlyMyTasks, onTap: () => setState(() { _selectedProjectId = null; _showOnlyMyTasks = true; }), theme: themeProvider),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 30, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("PROJELERİM", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                            if (taskProvider.isAdmin) 
                              InkWell(
                                onTap: () => _showAddProjectDialog(context, taskProvider),
                                borderRadius: BorderRadius.circular(5),
                                child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.add, size: 18, color: Colors.grey.shade600))
                              )
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: ListView.builder(
                          controller: _projectScrollController,
                          itemCount: taskProvider.projects.length,
                          itemBuilder: (context, index) {
                            final project = taskProvider.projects[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildSidebarItem(
                                icon: Icons.circle, iconColor: Color(project.colorValue), title: project.title, count: project.taskCount, isSelected: _selectedProjectId == project.id, theme: themeProvider,
                                onTap: () => setState(() { _selectedProjectId = project.id; _showOnlyMyTasks = false; }),
                                trailing: (taskProvider.isAdmin && _selectedProjectId == project.id) ? IconButton(icon: const Icon(Icons.more_horiz, size: 18), onPressed: () {
                                   final otherProjects = taskProvider.projects.where((p) => p.id != project.id).toList();
                                   final projectTasksCount = taskProvider.tasks.where((t) => t.projectId == project.id).length;
                                   if (otherProjects.isNotEmpty && projectTasksCount > 0) { _showTransferDialog(project, otherProjects, taskProvider); } else { _confirmProjectDelete(project, taskProvider, projectTasksCount, taskProvider.tasks, themeProvider); }
                                }) : null
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1), 
                      _buildUserProfileTile(context, taskProvider, themeProvider, isDark)
                    ],
                  ),
                ),
              ),
            ),
          ),

          // -----------------------------------------------------
          // SÜTUN 2: GÖREV LİSTESİ
          // -----------------------------------------------------
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1)))),
              child: Column(
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    color: sidebarColor,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen), 
                          icon: Icon(_isSidebarOpen ? Icons.menu_open : Icons.menu, color: Colors.grey.shade800), 
                          tooltip: "Menü",
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedProjectId != null ? taskProvider.projects.firstWhere((p) => p.id == _selectedProjectId, orElse: () => Project(title: "Proje", colorValue: 0)).title : (_showOnlyMyTasks ? "Bana Atananlar" : "Tüm Görevler"), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                              Text("${activeTasks.length} bekleyen görev", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _showAddTaskDialog(context), 
                          icon: const Icon(Icons.add, size: 18), 
                          label: const Text("Yeni Görev"), 
                          style: FilledButton.styleFrom(
                            backgroundColor: themeProvider.secondaryColor, 
                            foregroundColor: Colors.white, 
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          )
                        )
                      ],
                    ),
                  ),
                  
                  Container(
                    color: sidebarColor,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: themeProvider.secondaryColor,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: themeProvider.secondaryColor,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: [Tab(text: "Yapılacaklar"), Tab(text: "Tamamlananlar")],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTaskList(activeTasks, themeProvider, taskProvider, context, isDark),
                        _buildTaskList(completedTasks, themeProvider, taskProvider, context, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -----------------------------------------------------
          // SÜTUN 3: DETAY (BEMBEYAZ & HİZALI)
          // -----------------------------------------------------
          Expanded(
            flex: 4, 
            child: _selectedTask == null
                ? Container(
                    color: detailColor,
                    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.layers_clear_outlined, size: 80, color: Colors.grey.withOpacity(0.2)),
                      const SizedBox(height: 20),
                      Text("Detayları görmek için bir görev seçin", style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.6), fontWeight: FontWeight.w500)),
                    ])),
                  )
                : Container(
                    color: detailColor, 
                    child: TaskDetailScreen(
                      key: ValueKey(_selectedTask!.id),
                      task: _selectedTask!,
                      dbService: widget.dbService,
                      isEmbeddedWeb: true,
                      onClose: () => setState(() => _selectedTask = null),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- KART TASARIMI (ESKİ STİL - CARD) ---
  Widget _buildTaskList(List<Task> tasks, ThemeProvider themeProvider, TaskProvider taskProvider, BuildContext context, bool isDark) {
    if (tasks.isEmpty) return const Center(child: Text("Görev bulunamadı", style: TextStyle(color: Colors.grey)));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTask?.id == task.id;
        
        final cardColor = isSelected 
            ? themeProvider.secondaryColor.withOpacity(0.1) 
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

        String creatorName = taskProvider.getMemberName(task.creatorId) ?? "Anonim";
        String assigneeName = task.assignedMemberId != null ? (taskProvider.getMemberName(task.assignedMemberId) ?? "?") : "Havuz";
        String? completedBy = task.completedBy;

        return Card(
          elevation: isSelected ? 0 : 2,
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected ? BorderSide(color: themeProvider.secondaryColor, width: 1.5) : BorderSide.none
          ),
          child: InkWell(
            onTap: () => setState(() => _selectedTask = task),
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: SizedBox(
                              width: 24, height: 24,
                              child: Checkbox(
                                value: task.isDone,
                                activeColor: themeProvider.secondaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => taskProvider.toggleTaskStatus(task),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 30.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                                      color: task.isDone ? Colors.grey : (isDark ? Colors.white : Colors.black87)
                                    ),
                                  ),
                                  if (task.dueDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 12, color: task.dueDate!.isBefore(DateTime.now()) && !task.isDone ? Colors.red : Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: task.dueDate!.isBefore(DateTime.now()) && !task.isDone ? Colors.red : Colors.grey),
                                          ),
                                        ],
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 16,
                        children: [
                          _buildMetaRow(Icons.edit, "Oluşturan: $creatorName", Colors.grey),
                          _buildMetaRow(Icons.person, "Atanan: $assigneeName", task.assignedMemberId == null ? Colors.orange : themeProvider.secondaryColor),
                          if (task.isDone && completedBy != null)
                             _buildMetaRow(Icons.check_circle, "Bitiren: $completedBy", Colors.green),
                        ],
                      )
                    ],
                  ),
                ),

                if (taskProvider.isAdmin)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.grey.withOpacity(0.4), size: 20),
                      onPressed: () => _deleteTaskWithUndo(task, taskProvider, themeProvider),
                      tooltip: "Sil",
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaRow(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String title, required int count, required bool isSelected, required VoidCallback onTap, required ThemeProvider theme, Color? iconColor, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? theme.secondaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? (isSelected ? theme.secondaryColor : Colors.grey.shade600), size: 20),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 13, color: isSelected ? theme.secondaryColor : Colors.grey.shade700)),
        trailing: trailing ?? (count > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isSelected ? theme.secondaryColor : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text("$count", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade600))) : null),
        onTap: onTap, dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  Widget _buildUserProfileTile(BuildContext context, TaskProvider provider, ThemeProvider theme, bool isDark) {
    final member = provider.currentMember; final name = member?.name ?? "Misafir"; final initial = name.isNotEmpty ? name[0].toUpperCase() : "M";
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: InkWell(
        onTap: () => _showSettingsDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            border: Border.all(color: Colors.grey.withOpacity(0.2)), 
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: theme.secondaryColor, child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis), const Text("Hesap Ayarları", style: TextStyle(fontSize: 10, color: Colors.grey))])),
              const Icon(Icons.settings, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}