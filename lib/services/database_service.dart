// Dosya: lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odak_list/models/activity_log.dart';
import 'package:odak_list/models/comment.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/team_member.dart';
import 'package:firebase_storage/firebase_storage.dart' hide Task;
import 'dart:io'; 
import 'dart:typed_data';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- ORTAK PROJE VE GÖREVLER ---
  CollectionReference get _projectsRef => _db.collection('projects');
  CollectionReference get _tasksRef => _db.collection('tasks');

  // --- CANLI VERİ AKIŞLARI (FİLTRELİ) ---
  
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
      project.ownerId = uid; 
    }
    await _projectsRef.add(project.toMap());
  }

  Future<Task> createTask(Task task) async {
    String? uid = _auth.currentUser?.uid;
    
    if (uid != null) {
      task.ownerId = uid; // Mevcut kod (Filtreleme için)

      // --- EKLENEN KRİTİK KISIM ---
      // Eğer arayüzden creatorId gönderilmediyse, arka planda zorla ekle
      if (task.creatorId == null || task.creatorId!.isEmpty) {
        task.creatorId = uid;
      }
      // -----------------------------
    }
    
    var ref = await _tasksRef.add(task.toMap());
    task.id = ref.id;
    return task;
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _tasksRef.doc(task.id).update(task.toMap());
  }

 Future<void> deleteProject(String projectId) async {
    WriteBatch batch = _db.batch();
    batch.delete(_projectsRef.doc(projectId));

    var tasksSnapshot = await _tasksRef.where('projectId', isEqualTo: projectId).get();
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }

  // --- STORAGE (DOSYA YÜKLEME) ---
  
  Future<String?> uploadFile(String filePath, String fileName) async {
    try {
      File file = File(filePath);
      String uniqueName = "${DateTime.now().millisecondsSinceEpoch}_$fileName";
      Reference ref = FirebaseStorage.instance.ref().child('attachments/$uniqueName');
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Dosya yükleme hatası: $e");
      return null;
    }
  }

  // --- EKİP PROFİL YÖNETİMİ ---

  Stream<List<TeamMember>> getTeamMembersStream() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _db.collection('users').doc(uid).collection('members').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TeamMember.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Yeni Profil Ekle (Email Eklendi)
  Future<void> addTeamMember(String name, String role, String? pin, String? email) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).collection('members').add({
      'name': name,
      'role': role,
      'profilePin': pin,
      'email': email, // E-posta kaydediliyor
    });
  }

  // Profil Rolünü Güncelle
  Future<void> updateTeamMemberRole(String memberId, String newRole) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).collection('members').doc(memberId).update({'role': newRole});
  }

  // Profil Bilgilerini Güncelle (Email Eklendi)
  Future<void> updateTeamMemberInfo(String memberId, String name, String? pin, String? email) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _db.collection('users').doc(uid).collection('members').doc(memberId).update({
      'name': name,
      'profilePin': pin,
      'email': email, // E-posta güncelleniyor
    });
  }

  // Profil Sil
  Future<void> deleteTeamMember(String memberId) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final tasksQuery = await _tasksRef.where('assignedMemberId', isEqualTo: memberId).get();
    
    WriteBatch batch = _db.batch();
    
    for (var doc in tasksQuery.docs) {
      batch.update(doc.reference, {'assignedMemberId': null});
    }
    
    DocumentReference memberRef = _db.collection('users').doc(uid).collection('members').doc(memberId);
    batch.delete(memberRef);

    await batch.commit();
  }
  
  // İlk kurulum (Admin profilini oluştur) - DÜZELTİLDİ
  Future<void> createInitialAdminProfile(String name, String pin) async {
    String? uid = _auth.currentUser?.uid;
    String? email = _auth.currentUser?.email; // Giriş yapan kullanıcının mailini al
    
    if (uid == null) return;
    
    var members = await _db.collection('users').doc(uid).collection('members').get();
    if (members.docs.isEmpty) {
      // 4. Parametre olarak email eklendi
      await addTeamMember(name, 'admin', pin, email); 
    }
  }

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
    await _tasksRef.doc(taskId).collection('comments').add(comment.toMap());
    
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
  
  Future<void> updateMemberToken(String memberId, String token) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _db.collection('users').doc(uid).collection('members').doc(memberId).update({
      'fcmToken': token,
    });
  }

  // --- PREMIUM İŞLEMLERİ ---

  Future<void> activatePremium() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'isPremium': true,
      'premiumSince': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
  
  Future<bool> checkPremiumStatus() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    var doc = await _db.collection('users').doc(uid).get();
    
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('isPremium')) {
      return doc.data()!['isPremium'] == true;
    }
    return false;
  }

  // --- VERİ KURTARMA ---
  Future<int> claimOldData() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    int updatedCount = 0;
    WriteBatch batch = _db.batch();

    var projectsSnapshot = await _projectsRef.get(); 
    for (var doc in projectsSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('ownerId') || data['ownerId'] == null) {
        batch.update(doc.reference, {'ownerId': uid});
        updatedCount++;
      }
    }

    var tasksSnapshot = await _tasksRef.get(); 
    for (var doc in tasksSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('ownerId') || data['ownerId'] == null) {
        batch.update(doc.reference, {'ownerId': uid});
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      await batch.commit();
    }
    
    return updatedCount;
  }

  Future<void> restoreProject(Project project) async {
    if (project.id == null) return;
    await _projectsRef.doc(project.id).set(project.toMap());
  }

  Future<void> restoreTask(Task task) async {
    if (task.id == null) return;
    await _tasksRef.doc(task.id).set(task.toMap());
  }

  Future<void> moveTasksToProject(String oldProjectId, String newProjectId) async {
    var tasksSnapshot = await _tasksRef.where('projectId', isEqualTo: oldProjectId).get();
    
    WriteBatch batch = _db.batch();

    for (var doc in tasksSnapshot.docs) {
      batch.update(doc.reference, {'projectId': newProjectId});
    }
    
    await batch.commit();
  }

 Future<String?> uploadFileWeb(Uint8List bytes, String fileName) async {
    try {
      String uniqueName = "${DateTime.now().millisecondsSinceEpoch}_$fileName";
      var ref = _storage.ref().child('uploads/$uniqueName');
      
      var uploadTask = await ref.putData(bytes); 
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Web Upload Hatası: $e");
      return null;
    }
  }

  Future<void> updateTeamMemberPermissions(String memberId, bool canSeeAll, List<String> projectIds) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).collection('members').doc(memberId).update({
      'canSeeAllProjects': canSeeAll,
      'allowedProjectIds': projectIds,
    });
  }

  Future<void> updateTaskOrders(List<Task> tasks) async {
    WriteBatch batch = _db.batch();

    for (var task in tasks) {
      if (task.id != null) {
        DocumentReference docRef = _tasksRef.doc(task.id);
        batch.update(docRef, {'order': task.order});
      }
    }

    await batch.commit();
  }
}