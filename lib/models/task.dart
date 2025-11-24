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
  List<SubTask> subTasks;

  Task({
    this.id,
    required this.title,
    this.isDone = false,
    this.dueDate,
    this.category,
    this.priority = 1,
    this.notes,
    List<SubTask>? subTasks,
  }) : subTasks = subTasks ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'priority': priority,
      'notes': notes,
      // Listeyi JSON string'e çevirip kaydediyoruz
      'subTasksJson': jsonEncode(subTasks.map((e) => e.toMap()).toList()),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // Alt görevleri güvenli şekilde parse etme
    List<SubTask> loadedSubTasks = [];
    if (map['subTasksJson'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(map['subTasksJson']);
        loadedSubTasks = decoded.map((e) => SubTask.fromMap(e)).toList();
      } catch (e) {
        print("Alt görevler parse edilirken hata: $e");
      }
    }

    return Task(
      id: map['id'],
      title: map['title'] ?? '',
      isDone: map['isDone'] == 1,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      category: map['category'],
      priority: map['priority'] ?? 1,
      notes: map['notes'],
      subTasks: loadedSubTasks,
    );
  }
}