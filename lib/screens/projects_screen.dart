import 'package:flutter/material.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:provider/provider.dart';

class ProjectsScreen extends StatefulWidget {
  final DatabaseService dbService;
  const ProjectsScreen({super.key, required this.dbService});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await widget.dbService.getProjectsWithStats();
    if (mounted) {
      setState(() {
        _projects = projects;
        isLoading = false;
      });
    }
  }

  // Proje Ekleme (Ana ekrandakiyle aynı mantık)
  void _showAddProjectDialog() {
    final controller = TextEditingController();
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.indigo
    ];
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
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: "Proje Adı"),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) => GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color ? Border.all(width: 3, color: Colors.black) : null
                      ),
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
                    await widget.dbService.createProject(Project(
                      title: controller.text,
                      colorValue: selectedColor.value
                    ));
                    Navigator.pop(ctx);
                    _loadProjects(); // Listeyi yenile
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Tüm Projeler", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: themeProvider.secondaryColor),
            onPressed: _showAddProjectDialog,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(child: Text("Henüz proje yok", style: TextStyle(color: textColor)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Yan yana 2 kutu
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // Kutuların kareye yakın olması için
                  ),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return GestureDetector(
                      onTap: () {
                        // Seçilen projeyi Ana Ekrana gönder ve geri dön
                        Navigator.pop(context, project.id);
                      },
                      onLongPress: () {
                        // Silme İşlemi
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text("Projeyi Sil"),
                          content: const Text("Silmek istediğine emin misin?"),
                          actions: [
                            TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("İptal")),
                            TextButton(
                              onPressed: () async {
                                await widget.dbService.deleteProject(project.id!);
                                Navigator.pop(ctx);
                                _loadProjects();
                              }, 
                              child: const Text("Sil", style: TextStyle(color: Colors.red))
                            ),
                          ],
                        ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDarkMode ? [] : [
                            BoxShadow(color: Color(project.colorValue).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                          border: Border.all(
                            color: isDarkMode ? Colors.white10 : Colors.transparent,
                          )
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Üst Kısım: İkon ve Menü
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(project.colorValue).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.folder, color: Color(project.colorValue)),
                                ),
                                Text("${(project.progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                              ],
                            ),
                            
                            // Alt Kısım: İsim ve Görev Sayısı
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.title,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${project.taskCount} Görev",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                // Minik Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: project.progress,
                                    backgroundColor: Color(project.colorValue).withOpacity(0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(project.colorValue)),
                                    minHeight: 4,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}