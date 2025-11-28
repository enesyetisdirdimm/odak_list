// lib/models/project.dart

class Project {
  String? id;
  String title;
  int colorValue;
  String? ownerId; // YENİ: Projenin sahibi kim? (Auth UID)

  // Hesaplanan alanlar
  int taskCount;
  int completedTaskCount;

  Project({
    this.id,
    required this.title,
    required this.colorValue,
    this.ownerId, // Constructor'a eklendi
    this.taskCount = 0,
    this.completedTaskCount = 0,
  });

  double get progress {
    if (taskCount == 0) return 0.0;
    return completedTaskCount / taskCount;
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'colorValue': colorValue,
      'ownerId': ownerId, // Map'e eklendi
    };
  }

  factory Project.fromMap(Map<String, dynamic> map, String documentId) {
    return Project(
      id: documentId,
      title: map['title'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF42A5F5,
      ownerId: map['ownerId'], // Map'ten oku
    );
  }
}