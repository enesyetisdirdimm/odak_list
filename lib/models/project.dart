class Project {
  String? id; // ARTIK STRING
  String title;
  int colorValue;

  // Bu alanlar veritabanında tutulmaz, hesaplanır
  int taskCount;
  int completedTaskCount;

  Project({
    this.id,
    required this.title,
    required this.colorValue,
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
    };
  }

  // Firestore'dan gelen veriyi (Map + ID) modele çevirir
  factory Project.fromMap(Map<String, dynamic> map, String documentId) {
    return Project(
      id: documentId,
      title: map['title'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF42A5F5,
    );
  }
}