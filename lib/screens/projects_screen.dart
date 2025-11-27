import 'package:flutter/material.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart'; // Provider'ı ekledik
import 'package:odak_list/utils/app_colors.dart';
import 'package:provider/provider.dart';

class ProjectsScreen extends StatefulWidget {
  final DatabaseService dbService;
  const ProjectsScreen({super.key, required this.dbService});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  
  // Proje Ekleme Diyaloğu
  void _showAddProjectDialog(TaskProvider taskProvider) {
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
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    // Provider üzerinden ekliyoruz
                    taskProvider.addProject(Project(title: controller.text, colorValue: selectedColor.value));
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    // CANLI VERİ DİNLEME (Consumer)
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final projects = taskProvider.projects;
        final isLoading = taskProvider.isLoading;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text("Projeler", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : projects.isEmpty
                  ? Center(child: Text("Henüz proje yok.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: BoxDecoration(color: Color(project.colorValue), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
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
                                        "${project.taskCount} Görev (${project.completedTaskCount} Tamamlandı)",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 8),
                                      // İlerleme Çubuğu
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
                                ),
                                if (taskProvider.isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                     // Silme işlemi Provider üzerinden
                                     taskProvider.deleteProject(project.id!);
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          floatingActionButton: taskProvider.isAdmin 
            ? FloatingActionButton(
                onPressed: () => _showAddProjectDialog(taskProvider),
                backgroundColor: themeProvider.secondaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        );
      },
    );
  }
}