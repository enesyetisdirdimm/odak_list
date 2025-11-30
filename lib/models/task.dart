// lib/models/task.dart

import 'package:odak_list/models/sub_task.dart';

class Task {
  String? id;
  String title;
  bool isDone;
  DateTime? dueDate;
  String? category;
  int priority;
  String? notes;
  String? projectId;
  String? assignedMemberId;
  String? creatorId;
  String? ownerId;
  List<SubTask> subTasks;
  String recurrence;
  List<String> tags;
  DateTime? lastCommentAt;
  DateTime? createdAt; // YENİ: Oluşturulma Zamanı

  Task({
    this.id,
    required this.title,
    this.isDone = false,
    this.dueDate,
    this.category,
    this.priority = 1,
    this.notes,
    this.projectId,
    this.assignedMemberId,
    this.creatorId,
    this.ownerId,
    List<SubTask>? subTasks,
    this.recurrence = 'none',
    List<String>? tags,
    this.lastCommentAt,
    this.createdAt, // Constructor
  }) : subTasks = subTasks ?? [],
       tags = tags ?? [];

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'priority': priority,
      'notes': notes,
      'projectId': projectId,
      'assignedMemberId': assignedMemberId,
      'creatorId': creatorId,
      'ownerId': ownerId,
      'subTasks': subTasks.map((e) => e.toMap()).toList(),
      'recurrence': recurrence,
      'tags': tags,
      'lastCommentAt': lastCommentAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(), // Map'e ekle
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    List<SubTask> loadedSubTasks = [];
    if (map['subTasks'] != null) {
      var list = map['subTasks'] as List;
      loadedSubTasks = list.map((e) => SubTask.fromMap(e)).toList();
    }

    List<String> loadedTags = [];
    if (map['tags'] != null) {
      loadedTags = List<String>.from(map['tags']);
    }

    return Task(
      id: documentId,
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      category: map['category'],
      priority: map['priority'] ?? 1,
      notes: map['notes'],
      projectId: map['projectId'],
      assignedMemberId: map['assignedMemberId'],
      creatorId: map['creatorId'],
      ownerId: map['ownerId'],
      subTasks: loadedSubTasks,
      recurrence: map['recurrence'] ?? 'none',
      tags: loadedTags,
      lastCommentAt: map['lastCommentAt'] != null ? DateTime.parse(map['lastCommentAt']) : null,
      // Eğer eski görevlerde tarih yoksa, listenin en altına atmak için eski bir tarih (2000 yılı) veriyoruz
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime(2000), 
    );
  }
}