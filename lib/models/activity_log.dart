// lib/models/activity_log.dart

class ActivityLog {
  String id;
  String userName; // İşlemi yapan kişi
  String action;   // "Tamamladı", "Oluşturdu", "Tarihi Değiştirdi"
  DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userName,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map, String id) {
    return ActivityLog(
      id: id,
      userName: map['userName'] ?? 'Bilinmeyen',
      action: map['action'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }
}