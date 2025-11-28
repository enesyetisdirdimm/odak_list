// lib/models/comment.dart

class Comment {
  String id;
  String text;
  String authorName;
  String authorId;
  DateTime timestamp;
  
  // YENİ ALANLAR
  String? attachmentUrl; // Dosyanın indirme linki
  String? fileName;      // Dosyanın adı (örn: plan.jpg)
  String? fileType;      // Türü (image, pdf vs.)

  Comment({
    required this.id,
    required this.text,
    required this.authorName,
    required this.authorId,
    required this.timestamp,
    this.attachmentUrl,
    this.fileName,
    this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'authorName': authorName,
      'authorId': authorId,
      'timestamp': timestamp.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'fileName': fileName,
      'fileType': fileType,
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
      attachmentUrl: map['attachmentUrl'],
      fileName: map['fileName'],
      fileType: map['fileType'],
    );
  }
}