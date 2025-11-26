import 'package:flutter/material.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/sub_task.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final DatabaseService dbService;

  const TaskDetailScreen({super.key, required this.task, required this.dbService});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _subTaskController;
  late TextEditingController _tagController; // YENİ
  
  late Task _tempTask;
  final Map<int, String> _priorities = {2: 'Yüksek', 1: 'Normal', 0: 'Düşük'};
  
  final Map<String, String> _recurrenceOptions = {
    'none': 'Tekrar Yok',
    'daily': 'Her Gün',
    'weekly': 'Her Hafta',
    'monthly': 'Her Ay',
  };
  
  List<Project> _projects = []; 

  @override
  void initState() {
    super.initState();
    _loadProjects();

    _tempTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      isDone: widget.task.isDone,
      dueDate: widget.task.dueDate,
      category: widget.task.category,
      priority: widget.task.priority,
      notes: widget.task.notes,
      projectId: widget.task.projectId,
      subTasks: List.from(widget.task.subTasks),
      recurrence: widget.task.recurrence,
      tags: List.from(widget.task.tags), // YENİ
    );

    _titleController = TextEditingController(text: _tempTask.title);
    _notesController = TextEditingController(text: _tempTask.notes);
    _subTaskController = TextEditingController();
    _tagController = TextEditingController(); // YENİ
  }

  Future<void> _loadProjects() async {
    final projects = await widget.dbService.getProjectsWithStats();
    setState(() {
      _projects = projects;
      if (_tempTask.projectId == null && _projects.isNotEmpty) {
        _tempTask.projectId = _projects.first.id;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subTaskController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _tempTask.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    if (!mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_tempTask.dueDate ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _tempTask.dueDate = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  void _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Başlık giriniz')));
      return;
    }

    _tempTask.title = _titleController.text.trim();
    _tempTask.notes = _notesController.text.trim();

    if (_tempTask.dueDate == null) {
      _tempTask.dueDate = DateTime.now();
    }
    
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (_tempTask.id == null) {
      await taskProvider.addTask(_tempTask);
    } else {
      await taskProvider.updateTask(_tempTask);
    }
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _deleteTask() async {
    if (_tempTask.id != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.deleteTask(_tempTask.id!);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final iconColor = isDarkMode ? AppColors.textSecondaryDark : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_tempTask.id != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteTask,
            ),
          TextButton(
            onPressed: _saveTask,
            child: Text("KAYDET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeProvider.secondaryColor)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAŞLIK
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              decoration: InputDecoration(
                hintText: 'Ne yapılması gerekiyor?',
                hintStyle: TextStyle(color: isDarkMode ? Colors.grey : Colors.grey.shade400),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),
            
            // TARİH
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.calendar_today, color: themeProvider.primaryColor),
              title: Text(
                _tempTask.dueDate == null
                    ? 'Tarih ve Saat Ekle'
                    : DateFormat('dd MMMM yyyy, HH:mm').format(_tempTask.dueDate!),
                style: TextStyle(
                  color: _tempTask.dueDate == null ? Colors.grey : textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: _pickDateTime,
              trailing: _tempTask.dueDate != null 
                  ? IconButton(icon: Icon(Icons.clear, color: iconColor), onPressed: () => setState(() => _tempTask.dueDate = null)) 
                  : null,
            ),
            Divider(color: Colors.grey.withOpacity(0.3)),
            
            // TEKRAR
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.repeat, color: themeProvider.primaryColor),
              title: DropdownButtonFormField<String>(
                dropdownColor: isDarkMode ? AppColors.cardDark : Colors.white,
                value: _tempTask.recurrence,
                decoration: const InputDecoration(border: InputBorder.none),
                items: _recurrenceOptions.entries.map((e) => DropdownMenuItem(
                  value: e.key, 
                  child: Text(e.value, style: TextStyle(color: textColor)),
                )).toList(),
                onChanged: (val) => setState(() => _tempTask.recurrence = val ?? 'none'),
              ),
            ),
            Divider(color: Colors.grey.withOpacity(0.3)),

            // PROJE VE ÖNCELİK
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    dropdownColor: isDarkMode ? AppColors.cardDark : Colors.white,
                    value: _tempTask.projectId,
                    decoration: const InputDecoration(labelText: "Proje", border: InputBorder.none),
                    items: _projects.map((p) => DropdownMenuItem(
                      value: p.id, 
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Color(p.colorValue)),
                          const SizedBox(width: 8),
                          SizedBox(width: 80, child: Text(p.title, style: TextStyle(color: textColor), overflow: TextOverflow.ellipsis)),
                        ],
                      )
                    )).toList(),
                    onChanged: (val) => setState(() => _tempTask.projectId = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    dropdownColor: isDarkMode ? AppColors.cardDark : Colors.white,
                    value: _tempTask.priority,
                    decoration: const InputDecoration(labelText: "Öncelik", border: InputBorder.none),
                    items: _priorities.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: textColor)))).toList(),
                    onChanged: (val) => setState(() => _tempTask.priority = val ?? 1),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey.withOpacity(0.3)),

            // YENİ: ETİKETLER (TAGS) ALANI
            const Text("Etiketler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      hintText: "Etiket ekle (örn: acil)", 
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.tag, size: 20, color: Colors.grey),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        setState(() {
                          _tempTask.tags.add(val.trim());
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: themeProvider.secondaryColor),
                  onPressed: () {
                    if (_tagController.text.trim().isNotEmpty) {
                      setState(() {
                        _tempTask.tags.add(_tagController.text.trim());
                        _tagController.clear();
                      });
                    }
                  },
                )
              ],
            ),
            // Eklenen Etiketleri Göster (Wrap)
            if (_tempTask.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _tempTask.tags.map((tag) => Chip(
                    label: Text("#$tag", style: const TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: themeProvider.primaryColor.withOpacity(0.8),
                    deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onDeleted: () {
                      setState(() => _tempTask.tags.remove(tag));
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                  )).toList(),
                ),
              ),

            Divider(color: Colors.grey.withOpacity(0.3)),
            
            // ALT GÖREVLER
            const Text("Alt Görevler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(hintText: "Alt görev ekle...", border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: themeProvider.secondaryColor),
                  onPressed: () {
                    if (_subTaskController.text.trim().isNotEmpty) {
                      setState(() {
                        _tempTask.subTasks.add(SubTask(title: _subTaskController.text.trim()));
                        _subTaskController.clear();
                      });
                    }
                  },
                )
              ],
            ),
            ..._tempTask.subTasks.map((sub) => CheckboxListTile(
              title: Text(sub.title, style: TextStyle(color: textColor, decoration: sub.isDone ? TextDecoration.lineThrough : null)),
              value: sub.isDone,
              activeColor: themeProvider.secondaryColor,
              checkColor: Colors.white,
              onChanged: (val) {
                setState(() => sub.isDone = val ?? false);
              },
              secondary: IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: iconColor),
                onPressed: () => setState(() => _tempTask.subTasks.remove(sub)),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
            
            Divider(color: Colors.grey.withOpacity(0.3)),
            
            // NOTLAR
            const Text("Notlar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(hintText: 'Detaylı açıklama ekle...', border: InputBorder.none),
            ),
          ],
        ),
      ),
    );
  }
}