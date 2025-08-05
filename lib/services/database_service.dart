import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  static Database? _db;

  DatabaseService._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'naissance.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE naissances (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT,
            prenom TEXT,
            dateNaissance TEXT,
            lieu TEXT,
            sexe TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE agents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            passwordHash TEXT,
            otpCode TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE agents ADD COLUMN otpCode TEXT');
        }
      },
    );
  }

  Future<int> insertNaissance(Map<String, dynamic> naissance) async {
    final db = await database;
    return await db.insert('naissances', {
      ...naissance,
      'synced': 0,
    });
  }

  Future<int> updateNaissance(int id, Map<String, dynamic> naissance) async {
    final db = await database;
    return await db.update(
      'naissances',
      {
        ...naissance,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedNaissances() async {
    final db = await database;
    return await db.query('naissances', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markNaissanceAsSynced(int id) async {
    final db = await database;
    await db.update('naissances', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllNaissances() async {
    final db = await database;
    return await db.query('naissances', orderBy: 'id DESC');
  }

  Future<int> deleteNaissance(int id) async {
    final db = await database;
    return await db.delete('naissances', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertAgent(Map<String, dynamic> agent) async {
    final db = await database;
    return await db.insert('agents', agent, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getAgentByEmail(String email) async {
    final db = await database;
    final result = await db.query('agents', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> updateAgent(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('agents', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAgent(int id) async {
    final db = await database;
    return await db.delete('agents', where: 'id = ?', whereArgs: [id]);
  }
}
