import 'package:odak_list/models/project.dart';
import 'package:odak_list/models/task.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    // Yeni yapı için ismini değiştirdim, temiz başlasın.
    final path = join(documentsDirectory.path, 'odak_pro_v1.db'); 

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    // tags SÜTUNU EKLENDİ (TEXT olarak)
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        isDone INTEGER NOT NULL DEFAULT 0,
        dueDate TEXT,
        category TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        subTasksJson TEXT,
        projectId INTEGER,
        recurrence TEXT DEFAULT 'none',
        tags TEXT 
      )
    ''');

    await db.insert('projects', {
      'title': 'Genel', 
      'colorValue': 0xFF42A5F5
    });
  }

  // --- PROJE İŞLEMLERİ ---

  Future<int> createProject(Project project) async {
    final db = await database;
    return await db.insert('projects', project.toMap());
  }

  Future<void> deleteProject(int id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    // Proje silinince görevleri de silinsin mi? Şimdilik "Genel" yapalım veya silelim.
    // Biz görevleri silmeyi tercih edelim:
    await db.delete('tasks', where: 'projectId = ?', whereArgs: [id]);
  }

  // Bu fonksiyon çok önemli: Projeleri ve istatistiklerini getirir
  Future<List<Project>> getProjectsWithStats() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        p.id, 
        p.title, 
        p.colorValue,
        (SELECT COUNT(*) FROM tasks t WHERE t.projectId = p.id) as taskCount,
        (SELECT COUNT(*) FROM tasks t WHERE t.projectId = p.id AND t.isDone = 1) as completedTaskCount
      FROM projects p
    ''');
    return List.generate(result.length, (i) => Project.fromMap(result[i]));
  }

  // --- GÖREV İŞLEMLERİ ---

  Future<Task> createTask(Task task) async {
    final db = await database;
    final id = await db.insert('tasks', task.toMap());
    task.id = id;
    return task;
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'isDone ASC, priority DESC, dueDate ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Sadece belirli projenin görevlerini getir
  Future<List<Task>> getTasksByProject(int projectId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'isDone ASC, priority DESC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'odak_pro_v1.db');
  }

  // 2. Veritabanını Kapat (Geri yükleme yaparken şart)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Instance'ı sıfırla ki tekrar açabilsin
  }
}