class TeamMember {
  String id;
  String name;
  String role; // 'admin' veya 'editor' (veya 'viewer')
  String? profilePin; // Şifre alanı (Örn: "1234")
  String? fcmToken;   // Bildirimler için Token
  String? email;

  // --- YENİ EKLENEN YETKİ ALANLARI ---
  bool canSeeAllProjects;          // Tüm projeleri görme yetkisi
  List<String> allowedProjectIds;  // Sadece bu ID'li projeleri görme yetkisi
  // -----------------------------------

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.profilePin,
    this.fcmToken,
    this.email,
    this.canSeeAllProjects = false,    // Varsayılan: Kapalı
    this.allowedProjectIds = const [], // Varsayılan: Boş liste
  });

  // Firestore'a veri yazarken
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'profilePin': profilePin,
      'email': email,
      'fcmToken': fcmToken, // Token'ı da kaydedelim
      // Yeni alanları veritabanına yazıyoruz
      'canSeeAllProjects': canSeeAllProjects,
      'allowedProjectIds': allowedProjectIds,
    };
  }

  // Firestore'dan veri okurken
  factory TeamMember.fromMap(Map<String, dynamic> map, String id) {
    return TeamMember(
      id: id,
      name: map['name'] ?? '',
      role: map['role'] ?? 'editor',
      profilePin: map['profilePin'],
      email: map['email'],
      fcmToken: map['fcmToken'],
      // Yeni alanları okuyoruz (null gelirse varsayılan değerleri ata)
      canSeeAllProjects: map['canSeeAllProjects'] ?? false,
      allowedProjectIds: List<String>.from(map['allowedProjectIds'] ?? []),
    );
  }
}