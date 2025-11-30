// Dosya: lib/screens/homescreen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/screens/settings_screen.dart';
import 'package:odak_list/screens/task_detail_screen.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart';
import 'package:odak_list/widgets/task_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SortOption { newestFirst, dateAsc, dateDesc, priorityDesc, priorityAsc, titleAsc }

class HomeScreen extends StatefulWidget {
  final DatabaseService dbService;
  const HomeScreen({super.key, required this.dbService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedProjectId; 
  String _searchQuery = '';
  
  // Varsayılan sıralama: En Yeni En Üstte
  SortOption _currentSortOption = SortOption.newestFirst;
  
  // "Bana Ait" Filtresi
  bool _showOnlyMyTasks = false; 

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _processTasks(List<Task> allTasks, TaskProvider provider) {
    List<Task> filtered;
    
    // 1. Proje Filtresi
    if (_selectedProjectId != null) {
      filtered = allTasks.where((t) => t.projectId == _selectedProjectId).toList();
    } else {
      filtered = allTasks; 
    }

    // 2. "Bana Ait" Filtresi
    if (_showOnlyMyTasks) {
      final myId = provider.currentMember?.id;
      if (myId != null) {
        filtered = filtered.where((t) => t.assignedMemberId == myId).toList();
      }
    }

    // 3. Arama Filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final query = _searchQuery.toLowerCase();
        final inTitle = t.title.toLowerCase().contains(query);
        final inTags = t.tags.any((tag) => tag.toLowerCase().contains(query));
        return inTitle || inTags;
      }).toList();
    }

    // 4. Sıralama
    filtered.sort((a, b) {
      switch (_currentSortOption) {
        case SortOption.newestFirst:
          // En yeni tarihli (b) en başa (a)
          // createdAt null ise eski kabul edip sona atıyoruz
          return (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000));
          
        case SortOption.dateAsc:
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
          
        case SortOption.dateDesc:
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
          
        case SortOption.priorityDesc:
          return b.priority.compareTo(a.priority);
          
        case SortOption.priorityAsc:
          return a.priority.compareTo(b.priority);
          
        case SortOption.titleAsc:
          return a.title.compareTo(b.title);
      }
    });

    return filtered;
  }

  void _showSortOptions(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Sıralama Ölçütü", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildSortTile("En Yeni Eklenen (Varsayılan)", SortOption.newestFirst, Icons.new_releases, themeProvider),
              _buildSortTile("Tarih (En Yakın Önce)", SortOption.dateAsc, Icons.calendar_today, themeProvider),
              _buildSortTile("Tarih (En Uzak Önce)", SortOption.dateDesc, Icons.event_repeat, themeProvider),
              _buildSortTile("Öncelik (Yüksek)", SortOption.priorityDesc, Icons.flag, themeProvider),
              _buildSortTile("Öncelik (Düşük)", SortOption.priorityAsc, Icons.outlined_flag, themeProvider),
              _buildSortTile("Alfabetik (A-Z)", SortOption.titleAsc, Icons.sort_by_alpha, themeProvider),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String title, SortOption option, IconData icon, ThemeProvider theme) {
    final isSelected = _currentSortOption == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.secondaryColor : Colors.grey),
      title: Text(title, style: TextStyle(color: isSelected ? theme.secondaryColor : null, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check, color: theme.secondaryColor) : null,
      onTap: () {
        setState(() => _currentSortOption = option);
        Navigator.pop(context);
      },
    );
  }

  void _showAddProjectDialog(TaskProvider taskProvider) {
    final controller = TextEditingController();
    final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.indigo];
    Color selectedColor = colors[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : Colors.white,
            title: const Text("Yeni Proje"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controller, decoration: const InputDecoration(hintText: "Proje Adı")),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: colors.map((color) => GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: selectedColor == color ? Border.all(width: 3, color: Colors.black) : null),
                    ),
                  )).toList(),
                )
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    await taskProvider.addProject(Project(title: controller.text, colorValue: selectedColor.value));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Oluştur"),
              )
            ],
          );
        }
      ),
    );
  }

  void _navigateToDetail([Task? task]) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (taskProvider.projects.isEmpty) {
      if (taskProvider.isAdmin) {
         _showAddProjectDialog(taskProvider);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Henüz hiç proje yok. Yöneticinize başvurun.")));
      }
      return;
    }

    String defaultProjectId = _selectedProjectId ?? taskProvider.projects.first.id!;
    
    await Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task ?? Task(title: '', projectId: defaultProjectId), dbService: widget.dbService)));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    final displayName = taskProvider.currentMember?.name ?? "Kullanıcı";
    
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = Theme.of(context).cardColor;

    final allProjects = taskProvider.projects;
    final allTasks = taskProvider.tasks;

    if (_selectedProjectId == null && allProjects.isNotEmpty) {
        _selectedProjectId = allProjects.first.id;
    } else if (_selectedProjectId != null && allProjects.isNotEmpty) {
        if (!allProjects.any((p) => p.id == _selectedProjectId)) {
           _selectedProjectId = allProjects.first.id;
        }
    }

    int totalTasks = 0;
    int completedTasks = 0;
    double progress = 0.0;

    if (_selectedProjectId != null && allProjects.isNotEmpty) {
      try {
        final selectedProject = allProjects.firstWhere((p) => p.id == _selectedProjectId);
        totalTasks = selectedProject.taskCount;
        completedTasks = selectedProject.completedTaskCount;
        progress = selectedProject.progress;
      } catch (e) {}
    }

    final processedTasks = _processTasks(allTasks, taskProvider);
    final activeTasksList = processedTasks.where((t) => !t.isDone).toList();
    final completedTasksList = processedTasks.where((t) => t.isDone).toList();
    
    String dateStr = DateFormat('d MMMM, EEEE', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SizedBox(
            height: 290,
            child: Stack(
              children: [
                Container(
                  height: 230, width: double.infinity,
                  decoration: BoxDecoration(gradient: themeProvider.currentGradient, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.menu, color: Colors.white.withOpacity(0.9)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.settings, color: Colors.white, size: 24)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Merhaba, $displayName! 👋", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 5),
                      Text(dateStr, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0, left: 24, right: 24,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: isDarkMode ? Border.all(color: Colors.white10, width: 1) : null, boxShadow: isDarkMode ? [] : AppStyles.softShadow),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Stack(alignment: Alignment.center, children: [SizedBox(width: 60, height: 60, child: CircularProgressIndicator(value: progress, strokeWidth: 8, backgroundColor: isDarkMode ? Colors.white10 : AppColors.backgroundLight, valueColor: AlwaysStoppedAnimation<Color>(themeProvider.secondaryColor))), Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor))]),
                        const SizedBox(width: 20),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(_selectedProjectId != null && allProjects.isNotEmpty ? allProjects.firstWhere((p) => p.id == _selectedProjectId, orElse: () => Project(title: 'Yükleniyor', colorValue: 0)).title : "Proje Seçin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), const SizedBox(height: 4), Text("$completedTasks / $totalTasks Görev Tamamlandı", style: TextStyle(color: subTextColor, fontSize: 13))]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                if (taskProvider.isAdmin)
                  GestureDetector(
                    onTap: () => _showAddProjectDialog(taskProvider), 
                    child: Container(
                      width: 50, 
                      margin: const EdgeInsets.only(right: 12), 
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white10 : Colors.grey.shade200, 
                        borderRadius: BorderRadius.circular(15)
                      ), 
                      child: Icon(Icons.add, color: themeProvider.secondaryColor)
                    )
                  ),
                  
                ...allProjects.map((project) { 
                  bool isSelected = _selectedProjectId == project.id; 
                  return GestureDetector(
                    onTap: () { setState(() => _selectedProjectId = project.id); HapticFeedback.selectionClick(); }, 
                    onLongPress: () { 
                      if (taskProvider.isAdmin) {
                        showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Projeyi Sil"), content: const Text("Bu proje ve içindeki görevler silinsin mi?"), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("İptal")), TextButton(onPressed: () async { await taskProvider.deleteProject(project.id!); Navigator.pop(ctx); setState(() => _selectedProjectId = null); }, child: const Text("Sil", style: TextStyle(color: Colors.red)))])); 
                      }
                    }, 
                    child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: isSelected ? Color(project.colorValue) : cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? Colors.transparent : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300)), boxShadow: isSelected ? [BoxShadow(color: Color(project.colorValue).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : []), alignment: Alignment.center, child: Text(project.title, style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight), fontWeight: FontWeight.bold)))
                  ); 
                })
              ]
            )
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Container(height: 45, decoration: BoxDecoration(color: isDarkMode ? Colors.grey.shade900 : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDarkMode ? Colors.transparent : Colors.grey.shade300)), child: TextField(controller: _searchController, onChanged: (val) => setState(() => _searchQuery = val), style: TextStyle(color: textColor), decoration: InputDecoration(hintText: "Görev Ara...", hintStyle: TextStyle(color: subTextColor), prefixIcon: Icon(Icons.search, color: subTextColor), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 10))))),
                    const SizedBox(width: 10),
                    GestureDetector(onTap: () => _showSortOptions(themeProvider), child: Container(height: 45, width: 45, decoration: BoxDecoration(color: themeProvider.secondaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.sort, color: themeProvider.secondaryColor))),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab("Tümü", !_showOnlyMyTasks, themeProvider),
                      _buildFilterTab("Bana Ait", _showOnlyMyTasks, themeProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : activeTasksList.isEmpty && completedTasksList.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.rocket_launch, size: 80, color: themeProvider.secondaryColor.withOpacity(0.5)), 
                        const SizedBox(height: 20), 
                        Text(_showOnlyMyTasks ? "Sana atanmış görev yok." : "Hiç görev yok!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)), 
                        const SizedBox(height: 8), 
                        Text(_showOnlyMyTasks ? "Rahatına bakabilirsin 😎" : "Yeni bir başlangıç yap.", style: TextStyle(color: subTextColor)), 
                      ]))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        children: [
                          if (activeTasksList.isNotEmpty) ...[
                            Text("YAPILACAKLAR (${activeTasksList.length})", style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor, fontSize: 14, letterSpacing: 1.2)),
                            const SizedBox(height: 10),
                            ...activeTasksList.map((task) => _buildDismissibleTask(task, themeProvider, taskProvider)),
                          ],
                          if (activeTasksList.isNotEmpty && completedTasksList.isNotEmpty) const SizedBox(height: 24),
                          if (completedTasksList.isNotEmpty) ...[
                             Text("TAMAMLANANLAR (${completedTasksList.length})", style: TextStyle(fontWeight: FontWeight.bold, color: subTextColor, fontSize: 14, letterSpacing: 1.2)),
                            const SizedBox(height: 10),
                            ...completedTasksList.map((task) => Opacity(opacity: 0.6, child: _buildDismissibleTask(task, themeProvider, taskProvider))),
                          ],
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToDetail(),
        backgroundColor: themeProvider.secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isActive, ThemeProvider theme) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showOnlyMyTasks = (title == "Bana Ait");
          });
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? theme.secondaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleTask(Task task, ThemeProvider themeProvider, TaskProvider taskProvider) {
    
    // KONTROLLÜ TAMAMLAMA
    void handleToggle() {
      if (taskProvider.canCompleteTask(task)) {
        taskProvider.toggleTaskStatus(task);
      } else {
        String ownerName = taskProvider.getMemberName(task.assignedMemberId) ?? "Başkası";
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bu görev $ownerName kişisine atanmış! Müdahale edemezsin."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          )
        );
      }
    }

    if (!taskProvider.isAdmin) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: TaskCard(
          task: task,
          categories: const {},
          onTap: () => _navigateToDetail(task),
          onToggleDone: handleToggle, 
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key('task_${task.id}'), 
        background: Container(decoration: BoxDecoration(color: themeProvider.primaryColor, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.check, color: Colors.white, size: 32)),
        secondaryBackground: Container(decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete_outline, color: Colors.white, size: 32)),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) { 
             handleToggle();
             return false; 
          } else { 
             return true; 
          }
        },
        onDismissed: (direction) async {
          if (direction == DismissDirection.endToStart) {
            HapticFeedback.mediumImpact();
            await taskProvider.deleteTask(task.id!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${task.title}' silindi"), action: SnackBarAction(label: 'GERİ AL', textColor: themeProvider.secondaryColor, onPressed: () async { task.id = null; await taskProvider.addTask(task); })));
            }
          }
        },
        child: TaskCard(
          task: task, 
          categories: const {}, 
          onTap: () => _navigateToDetail(task), 
          onToggleDone: handleToggle
        ),
      ),
    );
  }
}