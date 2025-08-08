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
      join(dbPath, 'declaration_naissance.db'),
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE declarations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            prenom TEXT,
            dateNaissance TEXT,
            lieuNaissance TEXT,
            heureNaissance TEXT,
            sexe TEXT,
            nomPere TEXT,
            prenomPere TEXT,
            dateNaissancePere TEXT,
            lieuNaissancePere TEXT,
            professionPere TEXT,
            nationalitePere TEXT,
            adressePere TEXT,
            pieceIdPere TEXT,
            statutPere TEXT,
            nomMere TEXT,
            prenomMere TEXT,
            nomJeuneFilleMere TEXT,
            dateNaissanceMere TEXT,
            lieuNaissanceMere TEXT,
            professionMere TEXT,
            nationaliteMere TEXT,
            adresseMere TEXT,
            pieceIdMere TEXT,
            statutMere TEXT,
            statutMarital TEXT,
            parentsMaries INTEGER,
            dateMariageParents TEXT,
            lieuMariageParents TEXT,
            nomDeclarant TEXT,
            prenomDeclarant TEXT,
            adresseDeclarant TEXT,
            lienDeclarant TEXT,
            pieceIdDeclarant TEXT,
            certificatAccouchement TEXT,
            livretFamille TEXT,
            acteNaissPere TEXT,
            acteNaissMere TEXT,
            acteReconnaissance TEXT,
            certificatNationalite TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            firstName TEXT,
            lastName TEXT,
            profilePicture TEXT,
            faceImagePath TEXT,
            biometricId TEXT,
            otpCode TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE declarations ADD COLUMN heureNaissance TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN lieuNaissance TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN dateNaissancePere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN lieuNaissancePere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN professionPere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN nationalitePere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN adressePere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN pieceIdPere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN dateNaissanceMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN lieuNaissanceMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN professionMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN nationaliteMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN adresseMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN pieceIdMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN nomJeuneFilleMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN nomDeclarant TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN prenomDeclarant TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN adresseDeclarant TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN lienDeclarant TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN pieceIdDeclarant TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN certificatAccouchement TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN livretFamille TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN acteNaissPere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN acteNaissMere TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN acteReconnaissance TEXT');
          await db.execute('ALTER TABLE declarations ADD COLUMN certificatNationalite TEXT');
        }
        
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE users ADD COLUMN biometricId TEXT');
        }
        
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE users ADD COLUMN faceImagePath TEXT');
        }
        
        if (oldVersion < 7) {
          await db.execute('ALTER TABLE users ADD COLUMN otpCode TEXT');
        }
      },
    );
  }

  Future<int> insertDeclaration(Map<String, dynamic> declaration) async {
    final db = await database;
    return await db.insert('declarations', {
      ...declaration,
      'synced': 0,
    });
  }

  Future<int> updateDeclaration(int id, Map<String, dynamic> declaration) async {
    final db = await database;
    return await db.update(
      'declarations',
      {
        ...declaration,
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedDeclarations() async {
    final db = await database;
    return await db.query('declarations', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markDeclarationAsSynced(int id) async {
    final db = await database;
    await db.update('declarations', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllDeclarations() async {
    final db = await database;
    return await db.query('declarations', orderBy: 'id DESC');
  }

  Future<int> deleteDeclaration(int id) async {
    final db = await database;
    return await db.delete('declarations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
