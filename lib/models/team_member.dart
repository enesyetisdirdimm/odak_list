class TeamMember {
  String id;
  String name;
  String role; // 'admin' veya 'editor'
  String? profilePin; // Şifre alanı (Örn: "1234")
  String? fcmToken;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.profilePin,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'profilePin': profilePin,
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map, String id) {
    return TeamMember(
      id: id,
      name: map['name'] ?? '',
      role: map['role'] ?? 'editor',
      profilePin: map['profilePin'], 
    );
  }
}