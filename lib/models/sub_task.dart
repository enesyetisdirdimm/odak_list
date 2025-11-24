import 'dart:math';

class SubTask {
  String id;
  String title;
  bool isDone;

  SubTask({required this.title, this.isDone = false, String? id})
      : id = id ?? Random().nextDouble().toString(); // Rastgele ID

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? Random().nextDouble().toString(),
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
    );
  }
}