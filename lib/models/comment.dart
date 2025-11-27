class Comment {
  String id;
  String text;
  String authorName;
  String authorId;
  DateTime timestamp;

  Comment({
    required this.id,
    required this.text,
    required this.authorName,
    required this.authorId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'authorName': authorName,
      'authorId': authorId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      text: map['text'] ?? '',
      authorName: map['authorName'] ?? 'Bilinmeyen',
      authorId: map['authorId'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }
}