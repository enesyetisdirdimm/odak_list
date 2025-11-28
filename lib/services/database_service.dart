// Dosya: lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odak_list/models/activity_log.dart';
import 'package:odak_list/models/comment.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/team_member.dart';
import 'package:firebase_storage/firebase_storage.dart' hide Task; // Storage Paketi
import 'dart:io'; // Dosya işlemleri için

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- ORTAK PROJE VE GÖREVLER ---
  CollectionReference get _projectsRef => _db.collection('projects');
  CollectionReference get _tasksRef => _db.collection('tasks');

  // --- CANLI VERİ AKIŞLARI (FİLTRELİ) ---
  
  // Sadece giriş yapan kullanıcının (Owner) projelerini getirir
  Stream<List<Project>> getProjectsStream() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _projectsRef
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Project.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
        });
  }

  // Sadece giriş yapan kullanıcının (Owner) görevlerini getirir
  Stream<List<Task>> getTasksStream() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _tasksRef
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
        });
  }

  // --- YAZMA İŞLEMLERİ (OTOMATİK OWNER ID) ---
  
  Future<void> createProject(Project project) async {
    String? uid = _auth.currentUser?.uid;
    if (uid != null) {
      project.ownerId = uid; // Sahibini mühürle
    }
    await _projectsRef.add(project.toMap());
  }

  Future<Task> createTask(Task task) async {
    String? uid = _auth.currentUser?.uid;
    if (uid != null) {
      task.ownerId = uid; // Sahibini mühürle
    }
    var ref = await _tasksRef.add(task.toMap());
    task.id = ref.id;
    return task;
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    // Güncellerken ownerId'yi değiştirmemeye dikkat ediyoruz (Modelde zaten var)
    await _tasksRef.doc(task.id).update(task.toMap());
  }

  Future<void> deleteProject(String id) async {
    await _projectsRef.doc(id).delete();
    // Projeye bağlı görevleri de sil
    var tasks = await _tasksRef.where('projectId', isEqualTo: id).get();
    for (var doc in tasks.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }

  // --- STORAGE (DOSYA YÜKLEME) ---
  
  Future<String?> uploadFile(String filePath, String fileName) async {
    try {
      File file = File(filePath);
      // Dosyayı "attachments" klasörüne, benzersiz bir isimle kaydet
      String uniqueName = "${DateTime.now().millisecondsSinceEpoch}_$fileName";
      Reference ref = FirebaseStorage.instance.ref().child('attachments/$uniqueName');
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      // Yükleme bitince indirme linkini al
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Dosya yükleme hatası: $e");
      return null;
    }
  }

  // --- EKİP PROFİL YÖNETİMİ ---

  // Profilleri Getir
  Stream<List<TeamMember>> getTeamMembersStream() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db.collection('users').doc(uid).collection('members').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TeamMember.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Yeni Profil Ekle
  Future<void> addTeamMember(String name, String role, String? pin) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).collection('members').add({
      'name': name,
      'role': role,
      'profilePin': pin,
    });
  }

  // Profil Rolünü Güncelle
  Future<void> updateTeamMemberRole(String memberId, String newRole) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('members').doc(memberId).update({'role': newRole});
  }

  // Profil Sil
  Future<void> deleteTeamMember(String memberId) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // 1. Önce kişinin üzerindeki görevleri bul ve havuza at (assignedMemberId = null yap)
    final tasksQuery = await _tasksRef.where('assignedMemberId', isEqualTo: memberId).get();
    
    WriteBatch batch = _db.batch();
    
    for (var doc in tasksQuery.docs) {
      batch.update(doc.reference, {'assignedMemberId': null});
    }
    
    // 2. Kişiyi sil
    DocumentReference memberRef = _db.collection('users').doc(uid).collection('members').doc(memberId);
    batch.delete(memberRef);

    // 3. Tüm işlemleri tek seferde uygula
    await batch.commit();
  }
  
  // İlk kurulum (Admin profilini oluştur)
  Future<void> createInitialAdminProfile(String name, String pin) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    var members = await _db.collection('users').doc(uid).collection('members').get();
    if (members.docs.isEmpty) {
      await addTeamMember(name, 'admin', pin); 
    }
  }

  // Üye Sayısını Kontrol Etmek İçin Koleksiyon Referansı
  CollectionReference getTeamMembersCollection() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return _db.collection('users'); 
    return _db.collection('users').doc(uid).collection('members');
  }

  // --- AKTİVİTE GÜNLÜĞÜ ---
  
  Future<void> addActivityLog(String taskId, String userName, String action) async {
    await _tasksRef.doc(taskId).collection('logs').add({
      'userName': userName,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<ActivityLog>> getTaskLogs(String taskId) {
    return _tasksRef
        .doc(taskId)
        .collection('logs')
        .orderBy('timestamp', descending: true) 
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  // --- YORUMLAR ---

  Future<void> addComment(String taskId, Comment comment) async {
    // 1. Yorumu ekle
    await _tasksRef.doc(taskId).collection('comments').add(comment.toMap());
    
    // 2. Görevin "lastCommentAt" alanını güncelle (Bildirim için)
    await _tasksRef.doc(taskId).update({
      'lastCommentAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Comment>> getTaskComments(String taskId) {
    return _tasksRef
        .doc(taskId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.data(), doc.id))
            .toList());
  }

  // --- FCM TOKEN İŞLEMLERİ ---
  
  // Cihazın FCM Token'ını kaydet
  Future<void> updateMemberToken(String memberId, String token) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    // Üyenin dökümanına 'fcmToken' alanını ekle/güncelle
    await _db.collection('users').doc(uid).collection('members').doc(memberId).update({
      'fcmToken': token,
    });
  }

  // --- PREMIUM İŞLEMLERİ ---

  // Hesabı Premium Yap
  Future<void> activatePremium() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // .update() yerine .set() ve merge:true kullanıyoruz.
    // Böylece döküman yoksa oluşturur, varsa günceller.
    await _db.collection('users').doc(uid).set({
      'isPremium': true,
      'premiumSince': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
  
  // Premium Durumunu Kontrol Et
  Future<bool> checkPremiumStatus() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    var doc = await _db.collection('users').doc(uid).get();
    
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('isPremium')) {
      return doc.data()!['isPremium'] == true;
    }
    return false;
  }

  // --- VERİ KURTARMA (ESKİ VERİLERİ SAHİPLEN) ---
  // Bu fonksiyon, sahipsiz (eski) tüm görev ve projeleri
  // şu an giriş yapmış olan kullanıcıya aktarır.
  Future<int> claimOldData() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    int updatedCount = 0;
    WriteBatch batch = _db.batch();

    // 1. Sahipsiz Projeleri Bul
    var projectsSnapshot = await _projectsRef.get(); // Hepsini çek
    for (var doc in projectsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('ownerId') || data['ownerId'] == null) {
        batch.update(doc.reference, {'ownerId': uid});
        updatedCount++;
      }
    }

    // 2. Sahipsiz Görevleri Bul
    var tasksSnapshot = await _tasksRef.get(); // Hepsini çek
    for (var doc in tasksSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('ownerId') || data['ownerId'] == null) {
        batch.update(doc.reference, {'ownerId': uid});
        updatedCount++;
      }
    }

    // 3. Değişiklikleri Kaydet
    if (updatedCount > 0) {
      await batch.commit();
    }
    
    return updatedCount;
  }
}