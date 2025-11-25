class Project {
  int? id;
  String title;
  int colorValue; // Rengi integer olarak saklayacağız (örn: 0xFF...)

  // Bu alanlar veritabanında fiziksel olarak yok,
  // SQL sorgusuyla anlık hesaplayıp dolduracağız.
  int taskCount;
  int completedTaskCount;

  Project({
    this.id,
    required this.title,
    required this.colorValue,
    this.taskCount = 0,
    this.completedTaskCount = 0,
  });

  // İlerleme oranı (0.0 ile 1.0 arası)
  double get progress {
    if (taskCount == 0) return 0.0;
    return completedTaskCount / taskCount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'colorValue': colorValue,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      colorValue: map['colorValue'],
      taskCount: map['taskCount'] ?? 0,
      completedTaskCount: map['completedTaskCount'] ?? 0,
    );
  }
}