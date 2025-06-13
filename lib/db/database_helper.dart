import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('declaration_naissance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE declarations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT,
        dateNaissance TEXT,
        lieu TEXT,
        sexe TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
  }

  // Déclaration CRUD
  Future<int> insertDeclaration(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('declarations', data);
  }

  Future<List<Map<String, dynamic>>> getDeclarations() async {
    final db = await instance.database;
    return await db.query('declarations', orderBy: 'id DESC');
  }

  Future<void> deleteDeclaration(int id) async {
    final db = await instance.database;
    await db.delete(
      'declarations', // Remplace par le nom exact de ta table si besoin
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User CRUD (pour l'inscription)
  Future<int> insertUser(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('users', data);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty ? res.first : null;
  }

  // Pour la synchro, tu peux ajouter d'autres méthodes plus tard
}