import 'package:flutter/material.dart';
import 'package:odak_list/models/sub_task.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/services/notification_service.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:intl/intl.dart';

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
  
  late Task _tempTask;
  final NotificationService _notificationService = NotificationService();

  // Öncelikler
  final Map<int, String> _priorities = {2: 'Yüksek', 1: 'Normal', 0: 'Düşük'};
  // Kategoriler
  final List<String> _categoryList = ['İş', 'Ev', 'Okul', 'Kişisel'];

  @override
  void initState() {
    super.initState();
    // Task'ın kopyasını oluşturma (Referans hatasını önlemek için)
    _tempTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      isDone: widget.task.isDone,
      dueDate: widget.task.dueDate,
      category: widget.task.category,
      priority: widget.task.priority,
      notes: widget.task.notes,
      subTasks: List.from(widget.task.subTasks),
    );

    _titleController = TextEditingController(text: _tempTask.title);
    _notesController = TextEditingController(text: _tempTask.notes);
    _subTaskController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subTaskController.dispose();
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
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen görev başlığı giriniz')),
      );
      return;
    }

    _tempTask.title = _titleController.text.trim();
    _tempTask.notes = _notesController.text.trim();

    if (_tempTask.id == null) {
      // Yeni Kayıt
      Task createdTask = await widget.dbService.createTask(_tempTask);
      // Bildirim kur
      if (createdTask.dueDate != null && createdTask.dueDate!.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: createdTask.id!,
          title: "Hatırlatıcı: ${createdTask.title}",
          body: "Görevinizin zamanı geldi!",
          scheduledTime: createdTask.dueDate!,
        );
      }
    } else {
      // Güncelleme
      await widget.dbService.updateTask(_tempTask);
      // Eski bildirimi iptal et, yenisini kur (basitlik için)
      await _notificationService.cancelNotification(_tempTask.id!);
      if (_tempTask.dueDate != null && _tempTask.dueDate!.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: _tempTask.id!,
          title: "Hatırlatıcı: ${_tempTask.title}",
          body: "Görevinizin zamanı geldi!",
          scheduledTime: _tempTask.dueDate!,
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context); // Geri dön
  }

  void _deleteTask() async {
    if (_tempTask.id != null) {
      await widget.dbService.deleteTask(_tempTask.id!);
      await _notificationService.cancelNotification(_tempTask.id!);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
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
            child: const Text("KAYDET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Ne yapılması gerekiyor?',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),

            // Tarih ve Saat Seçimi
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primaryGradientStart),
              title: Text(
                _tempTask.dueDate == null
                    ? 'Tarih ve Saat Ekle'
                    : DateFormat('dd MMMM yyyy, HH:mm').format(_tempTask.dueDate!),
                style: TextStyle(
                  color: _tempTask.dueDate == null ? Colors.grey : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: _pickDateTime,
              trailing: _tempTask.dueDate != null 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _tempTask.dueDate = null)) 
                  : null,
            ),
            const Divider(),

            // Kategori ve Öncelik Yan Yana
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categoryList.contains(_tempTask.category) ? _tempTask.category : null,
                    decoration: const InputDecoration(labelText: "Kategori", border: InputBorder.none),
                    items: _categoryList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _tempTask.category = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _tempTask.priority,
                    decoration: const InputDecoration(labelText: "Öncelik", border: InputBorder.none),
                    items: _priorities.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (val) => setState(() => _tempTask.priority = val ?? 1),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Alt Görevler
            const Text("Alt Görevler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: const InputDecoration(hintText: "Alt görev ekle...", border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primaryGradientEnd),
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
              title: Text(sub.title, style: TextStyle(decoration: sub.isDone ? TextDecoration.lineThrough : null)),
              value: sub.isDone,
              onChanged: (val) {
                setState(() => sub.isDone = val ?? false);
              },
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => setState(() => _tempTask.subTasks.remove(sub)),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            )),
            
            const Divider(),
            // Notlar
            const Text("Notlar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Detaylı açıklama ekle...',
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}