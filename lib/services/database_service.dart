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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE naissances (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT,
            prenom TEXT,
            dateNaissance TEXT,
            lieu TEXT,
            sexe TEXT,
            synced INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE agents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            passwordHash TEXT
          )
        ''');
      },
    );
  }
}