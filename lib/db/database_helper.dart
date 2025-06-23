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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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
        nomPere TEXT,
        prenomPere TEXT,
        nomMere TEXT,
        prenomMere TEXT,
        statutMarital TEXT,
        parentsMaries INTEGER,
        dateMariageParents TEXT,
        lieuMariageParents TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        name TEXT,
        profilePicture TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await _addColumnIfNotExists(db, 'declarations', 'statutMarital', 'TEXT');
    await _addColumnIfNotExists(db, 'declarations', 'parentsMaries', 'INTEGER');
    await _addColumnIfNotExists(db, 'declarations', 'dateMariageParents', 'TEXT');
    await _addColumnIfNotExists(db, 'declarations', 'lieuMariageParents', 'TEXT');
    await _addColumnIfNotExists(db, 'declarations', 'nomPere', 'TEXT');
    await _addColumnIfNotExists(db, 'declarations', 'prenomPere', 'TEXT');
    await _addColumnIfNotExists(db, 'declarations', 'nomMere', 'TEXT');
    await _addColumnIfNotExists(db, 'declarations', 'prenomMere', 'TEXT');
  }

  Future _addColumnIfNotExists(Database db, String table, String column, String type) async {
    var result = await db.rawQuery("PRAGMA table_info($table)");
    var columnExists = result.any((row) => row['name'] == column);

    if (!columnExists) {
      try {
        await db.execute("ALTER TABLE $table ADD COLUMN $column $type");
      } catch (e) {
        print("Error adding column $column to $table: $e");
      }
    }
  }

  Future<int> insertDeclaration(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('declarations', data);
  }

  Future<int> updateDeclaration(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.update(
      'declarations',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDeclarations() async {
    final db = await instance.database;
    return await db.query('declarations', orderBy: 'id DESC');
  }

  Future<void> deleteDeclaration(int id) async {
    final db = await instance.database;
    await db.delete(
      'declarations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateUserProfilePicture(String email, String profilePicturePath) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'profilePicture': profilePicturePath},
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}
