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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
        profilePicture TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
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

  Future<int> deleteDeclaration(int id) async {
    final db = await instance.database;
    return await db.delete(
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

  Future<int> updateUser(String oldEmail, Map<String, dynamic> newData) async {
    final db = await instance.database;
    return await db.update(
      'users',
      newData,
      where: 'email = ?',
      whereArgs: [oldEmail],
    );
  }
}
