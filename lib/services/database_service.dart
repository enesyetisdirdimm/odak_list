// Dosya: lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:odak_list/models/activity_log.dart';
import 'package:odak_list/models/comment.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/team_member.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- ORTAK PROJE VE GÖREVLER (HERKES GÖRÜR) ---
  CollectionReference get _projectsRef => _db.collection('projects');
  CollectionReference get _tasksRef => _db.collection('tasks');

  // --- CANLI VERİ AKIŞLARI ---
  Stream<List<Project>> getProjectsStream() {
    return _projectsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Project.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Stream<List<Task>> getTasksStream() {
    return _tasksRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // --- YAZMA İŞLEMLERİ ---
  Future<void> createProject(Project project) async {
    await _projectsRef.add(project.toMap());
  }

  Future<void> deleteProject(String id) async {
    await _projectsRef.doc(id).delete();
    var tasks = await _tasksRef.where('projectId', isEqualTo: id).get();
    for (var doc in tasks.docs) {
      await doc.reference.delete();
    }
  }

  Future<Task> createTask(Task task) async {
    var ref = await _tasksRef.add(task.toMap());
    task.id = ref.id;
    return task;
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _tasksRef.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
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
  
  // İlk kurulum
  Future<void> createInitialAdminProfile(String name, String pin) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    var members = await _db.collection('users').doc(uid).collection('members').get();
    if (members.docs.isEmpty) {
      await addTeamMember(name, 'admin', pin); 
    }
  }

  // --- AKTİVİTE GÜNLÜĞÜ ---
  Future<void> addActivityLog(String taskId, String userName, String action) async {
    await _tasksRef.doc(taskId).collection('logs').add({
      'userName': userName,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Bir görevin loglarını getir
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
    
    // 2. Görevin "lastCommentAt" alanını güncelle
    await _tasksRef.doc(taskId).update({
      'lastCommentAt': DateTime.now().toIso8601String(),
    });
  }

  // Yorumları Getir
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

  // --- FCM TOKEN ---
  Future<void> updateMemberToken(String memberId, String token) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    // Üyenin dökümanına 'fcmToken' alanını ekle/güncelle
    await _db.collection('users').doc(uid).collection('members').doc(memberId).update({
      'fcmToken': token,
    });
  }

  // --- PREMIUM İŞLEMLERİ (DÜZELTİLDİ) ---

  // Hesabı Premium Yap
  Future<void> activatePremium() async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // DÜZELTME: .update() yerine .set() kullanıyoruz.
    // SetOptions(merge: true) sayesinde varsa günceller, yoksa oluşturur.
    // Böylece "Document not found" (Hayalet döküman) hatası çözülür.
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
    // Hem döküman var mı hem de isPremium true mu diye bak
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('isPremium')) {
      return doc.data()!['isPremium'] == true;
    }
    return false;
  }
}