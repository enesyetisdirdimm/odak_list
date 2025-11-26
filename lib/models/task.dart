import 'dart:convert';
import 'package:odak_list/models/sub_task.dart';

class Task {
  int? id;
  String title;
  bool isDone;
  DateTime? dueDate;
  String? category;
  int priority;
  String? notes;
  int? projectId;
  List<SubTask> subTasks;
  String recurrence;
  
  // YENİ: Etiketler Listesi
  List<String> tags; 

  Task({
    this.id,
    required this.title,
    this.isDone = false,
    this.dueDate,
    this.category,
    this.priority = 1,
    this.notes,
    this.projectId,
    List<SubTask>? subTasks,
    this.recurrence = 'none',
    List<String>? tags, // YENİ
  }) : subTasks = subTasks ?? [],
       tags = tags ?? []; // YENİ

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'priority': priority,
      'notes': notes,
      'projectId': projectId,
      'subTasksJson': jsonEncode(subTasks.map((e) => e.toMap()).toList()),
      'recurrence': recurrence,
      // Listeyi virgüllü string olarak kaydediyoruz (örn: "acil,iş")
      'tags': tags.join(','), // YENİ
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    List<SubTask> loadedSubTasks = [];
    if (map['subTasksJson'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['subTasksJson']);
        loadedSubTasks = decoded.map((e) => SubTask.fromMap(e)).toList();
      } catch (e) {
        print("Hata: $e");
      }
    }

    // String'i tekrar listeye çevir
    List<String> loadedTags = [];
    if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
      loadedTags = map['tags'].toString().split(',');
    }

    return Task(
      id: map['id'],
      title: map['title'] ?? '',
      isDone: map['isDone'] == 1,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      category: map['category'],
      priority: map['priority'] ?? 1,
      notes: map['notes'],
      projectId: map['projectId'],
      subTasks: loadedSubTasks,
      recurrence: map['recurrence'] ?? 'none',
      tags: loadedTags, // YENİ
    );
  }
}