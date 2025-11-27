// lib/screens/task_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:odak_list/models/activity_log.dart';
import 'package:odak_list/models/comment.dart'; // Yorum modeli
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

class _TaskDetailScreenState extends State<TaskDetailScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _subTaskController;
  late TextEditingController _tagController;
  late TextEditingController _commentController; // Yorum yazma alanı
  late TabController _tabController;
  
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
    // 3 SEKME: Detaylar, Yorumlar, Geçmiş
    _tabController = TabController(length: 3, vsync: this); 

    _tempTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      isDone: widget.task.isDone,
      dueDate: widget.task.dueDate,
      category: widget.task.category,
      priority: widget.task.priority,
      notes: widget.task.notes,
      projectId: widget.task.projectId,
      assignedMemberId: widget.task.assignedMemberId,
      creatorId: widget.task.creatorId,
      subTasks: List.from(widget.task.subTasks),
      recurrence: widget.task.recurrence,
      tags: List.from(widget.task.tags),
    );

    _titleController = TextEditingController(text: _tempTask.title);
    _notesController = TextEditingController(text: _tempTask.notes);
    _subTaskController = TextEditingController();
    _tagController = TextEditingController();
    _commentController = TextEditingController();

    _loadProjects();

    // Detay ekranına girildiğinde "Okundu" olarak işaretle
    if (widget.task.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<TaskProvider>(context, listen: false).markTaskAsRead(widget.task.id!);
      });
    }
  }

  void _loadProjects() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    setState(() {
      _projects = taskProvider.projects;
      if ((_tempTask.projectId == null || !_projects.any((p) => p.id == _tempTask.projectId)) && _projects.isNotEmpty) {
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
    _commentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool canEdit) async {
    if (!canEdit) return;

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

    if (_tempTask.dueDate == null && _tempTask.id == null) {
      _tempTask.dueDate = DateTime.now();
    }
    
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    if (_tempTask.id == null) {
      await taskProvider.addTask(_tempTask);
    } else {
      await taskProvider.updateTask(_tempTask);
      
      // Detay güncelleme logu
      if (taskProvider.currentMember != null) {
        await widget.dbService.addActivityLog(
          _tempTask.id!, 
          taskProvider.currentMember!.name, 
          "Detayları güncelledi."
        );
      }
    }
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _deleteTask() async {
    if (_tempTask.id != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      if (!taskProvider.isAdmin) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sadece yöneticiler görev silebilir.")));
         return;
      }
      
      await taskProvider.deleteTask(_tempTask.id!);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  // Yorum Gönderme Fonksiyonu
  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (_tempTask.id == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Önce görevi kaydetmelisiniz.")));
       return;
    }

    final provider = Provider.of<TaskProvider>(context, listen: false);
    final member = provider.currentMember;
    if (member == null) return;

    final newComment = Comment(
      id: '', // Firestore ID oluşturacak
      text: _commentController.text.trim(),
      authorName: member.name,
      authorId: member.id,
      timestamp: DateTime.now(),
    );

    await widget.dbService.addComment(_tempTask.id!, newComment);
    
    // Yorum gönderince hemen "Okundu" olarak işaretle (Kendi yorumumuzu görmüş oluyoruz)
    if (mounted) {
       provider.markTaskAsRead(_tempTask.id!);
    }

    _commentController.clear();
    // FocusScope.of(context).unfocus(); // Klavyeyi kapatmak istersen bunu aç
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context); 
    
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final iconColor = isDarkMode ? AppColors.textSecondaryDark : Colors.black;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // --- YETKİ KONTROLÜ ---
    final bool isAdmin = taskProvider.isAdmin;
    final bool isNewTask = _tempTask.id == null;
    final bool isCreator = _tempTask.creatorId == taskProvider.currentMember?.id;

    // Düzenleyebilir mi? (Admin VEYA Yeni Görev VEYA Oluşturan Kişi)
    final bool canEdit = isAdmin || isNewTask || isCreator;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Görev Detayı", style: TextStyle(color: textColor, fontSize: 16)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: themeProvider.secondaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: themeProvider.secondaryColor,
          tabs: const [
            Tab(text: "Detaylar"),
            Tab(text: "Yorumlar"),
            Tab(text: "Geçmiş"),
          ],
        ),
        actions: [
          if (_tempTask.id != null && isAdmin)
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
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // --- 1. SEKME: DETAYLAR FORMU ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BAŞLIK
                  TextField(
                    controller: _titleController,
                    readOnly: !canEdit,
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
                    leading: Icon(Icons.calendar_today, color: canEdit ? themeProvider.primaryColor : Colors.grey),
                    title: Text(
                      _tempTask.dueDate == null
                          ? 'Bugün (Varsayılan)'
                          : DateFormat('dd MMMM yyyy, HH:mm').format(_tempTask.dueDate!),
                      style: TextStyle(
                        color: _tempTask.dueDate == null ? Colors.grey : textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => _pickDateTime(canEdit),
                    trailing: (_tempTask.dueDate != null && canEdit) 
                        ? IconButton(icon: Icon(Icons.clear, color: iconColor), onPressed: () => setState(() => _tempTask.dueDate = null)) 
                        : null,
                  ),
                  Divider(color: Colors.grey.withOpacity(0.3)),
                  
                  // TEKRAR
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.repeat, color: canEdit ? themeProvider.primaryColor : Colors.grey),
                    title: DropdownButtonFormField<String>(
                      dropdownColor: isDarkMode ? AppColors.cardDark : Colors.white,
                      value: _tempTask.recurrence,
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: _recurrenceOptions.entries.map((e) => DropdownMenuItem(
                        value: e.key, 
                        child: Text(e.value, style: TextStyle(color: textColor)),
                      )).toList(),
                      onChanged: canEdit ? (val) => setState(() => _tempTask.recurrence = val ?? 'none') : null,
                      icon: canEdit ? null : const SizedBox.shrink(),
                    ),
                  ),
                  Divider(color: Colors.grey.withOpacity(0.3)),

                  // PROJE VE ÖNCELİK
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
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
                          onChanged: canEdit ? (val) => setState(() => _tempTask.projectId = val) : null,
                          icon: canEdit ? null : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          dropdownColor: isDarkMode ? AppColors.cardDark : Colors.white,
                          value: _tempTask.priority,
                          decoration: const InputDecoration(labelText: "Öncelik", border: InputBorder.none),
                          items: _priorities.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: textColor)))).toList(),
                          onChanged: canEdit ? (val) => setState(() => _tempTask.priority = val ?? 1) : null,
                          icon: canEdit ? null : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.withOpacity(0.3)),

                  // GÖREV SORUMLUSU (ATAMA)
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: "Görev Sorumlusu",
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                      // Alt çizgi rengini tema ile uyumlu yapıyoruz
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                    dropdownColor: isDarkMode ? AppColors.cardDark : Colors.white,
                    value: _tempTask.assignedMemberId,
                    isExpanded: true,
                    hint: const Text("Kime atansın?"),
                    
                    // Yetki Kontrolü
                    onChanged: canEdit ? (String? newValue) {
                      setState(() {
                        _tempTask.assignedMemberId = newValue;
                      });
                    } : null,
                    
                    // Admin değilse ok işaretini gizle
                    icon: canEdit ? null : const SizedBox.shrink(),
                    
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text("Atanmadı (Ortak Havuz)"),
                      ),
                      ...taskProvider.teamMembers.map((member) {
                        return DropdownMenuItem<String?>(
                          value: member.id,
                          child: Row(
                            children: [
                              // Küçük Avatar
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: member.role == 'admin' ? Colors.blue : Colors.orange,
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(member.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                    
                  
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.withOpacity(0.3)),

                  // ETİKETLER
                  const Text("Etiketler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          enabled: canEdit,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: canEdit ? "Etiket ekle (örn: acil)" : "Etiketler (Kilitli)", 
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.tag, size: 20, color: Colors.grey),
                          ),
                          onSubmitted: (val) {
                            if (canEdit && val.trim().isNotEmpty) {
                              setState(() {
                                _tempTask.tags.add(val.trim());
                                _tagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      if (canEdit)
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
                  if (_tempTask.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _tempTask.tags.map((tag) => Chip(
                          label: Text("#$tag", style: const TextStyle(fontSize: 12, color: Colors.white)),
                          backgroundColor: themeProvider.primaryColor.withOpacity(0.8),
                          deleteIcon: canEdit ? const Icon(Icons.close, size: 16, color: Colors.white) : null,
                          onDeleted: canEdit ? () {
                            setState(() => _tempTask.tags.remove(tag));
                          } : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                        )).toList(),
                      ),
                    ),

                  Divider(color: Colors.grey.withOpacity(0.3)),
                  
                  // ALT GÖREVLER
                  const Text("Alt Görevler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  if (canEdit)
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
                    // Herkes alt görevi işaretleyebilir
                    onChanged: (val) {
                      setState(() => sub.isDone = val ?? false);
                    },
                    secondary: canEdit ? IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: iconColor),
                      onPressed: () => setState(() => _tempTask.subTasks.remove(sub)),
                    ) : null,
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

            // --- 2. YORUMLAR (GÜNCELLENDİ: AVATAR VE İSİM GÖRÜNÜMÜ) ---
            _tempTask.id == null
                ? const Center(child: Text("Yorum yapmak için önce görevi kaydedin.", style: TextStyle(color: Colors.grey)))
                : Column(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<Comment>>(
                          stream: widget.dbService.getTaskComments(_tempTask.id!),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            final comments = snapshot.data!;
                            if (comments.isEmpty) return const Center(child: Text("Henüz yorum yok. İlk yorumu sen yaz!", style: TextStyle(color: Colors.grey)));

                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(16),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                final isMe = comment.authorId == taskProvider.currentMember?.id;
                                final timeStr = DateFormat('HH:mm').format(comment.timestamp);
                                
                                final nameInitial = comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : "?";

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // BAŞKASININ AVATARI (SOLDA)
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.orangeAccent,
                                          child: Text(nameInitial, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                      ],

                                      // MESAJ BALONU
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isMe ? themeProvider.secondaryColor.withOpacity(0.15) : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(16),
                                              topRight: const Radius.circular(16),
                                              bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                              bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              // İSİM BAŞLIĞI (Herkes için görünür)
                                              Text(
                                                isMe ? "Ben" : comment.authorName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isMe ? themeProvider.primaryColor : Colors.orangeAccent,
                                                  fontSize: 12
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              
                                              // MESAJ
                                              Text(comment.text, style: TextStyle(color: textColor)),
                                              const SizedBox(height: 4),
                                              
                                              // SAAT
                                              Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // BENİM AVATARIM (SAĞDA)
                                      if (isMe) ...[
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: themeProvider.secondaryColor,
                                          child: Text(nameInitial, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Yorum Yazma Alanı
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                maxLength: 500,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(hintText: "Bir yorum yaz...", hintStyle: TextStyle(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none), filled: true, fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100, contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: themeProvider.secondaryColor,
                              child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendComment),
                            )
                          ],
                        ),
                      )
                    ],
                  ),

            // --- 3. SEKME: GEÇMİŞ (AKTİVİTE LOGLARI) ---
            _tempTask.id == null
                ? const Center(child: Text("Görev oluşturulduktan sonra geçmiş tutulur.", style: TextStyle(color: Colors.grey)))
                : StreamBuilder<List<ActivityLog>>(
                    stream: widget.dbService.getTaskLogs(_tempTask.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final logs = snapshot.data ?? [];
                      if (logs.isEmpty) return const Center(child: Text("Henüz işlem geçmişi yok.", style: TextStyle(color: Colors.grey)));

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final timeStr = DateFormat('dd MMM, HH:mm').format(log.timestamp);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Zaman Çizgisi Noktası
                                Column(
                                  children: [
                                    Container(
                                      width: 12, height: 12, 
                                      decoration: BoxDecoration(color: themeProvider.secondaryColor.withOpacity(0.5), shape: BoxShape.circle)
                                    ),
                                    if (index != logs.length - 1)
                                      Container(width: 2, height: 40, color: Colors.grey.withOpacity(0.2)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                
                                // İçerik
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(log.action, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(log.userName, style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 10),
                                          Icon(Icons.access_time, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(timeStr, style: TextStyle(fontSize: 12, color: subTextColor)),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}