import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer' as developer;

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
      version: 7,
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
        profilePicture TEXT,
        faceImagePath TEXT,
        biometricId TEXT,
        otpCode TEXT
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

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN biometricId TEXT');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE users ADD COLUMN faceImagePath TEXT');
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE users ADD COLUMN otpCode TEXT');
    }
  }

  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<int> insertDeclaration(Map<String, dynamic> data) async {
    final db = await instance.database;
    int id = await db.insert('declarations', {...data, 'synced': 0});
    await _trySyncDeclaration(id);
    return id;
  }

  Future<int> updateDeclaration(int id, Map<String, dynamic> data) async {
    final db = await instance.database;
    int res = await db.update('declarations', {...data, 'synced': 0}, where: 'id = ?', whereArgs: [id]);
    await _trySyncDeclaration(id);
    return res;
  }

  Future<void> _trySyncDeclaration(int localId) async {
    if (await isOnline) {
      final db = await instance.database;
      final List<Map<String, dynamic>> list = await db.query('declarations', where: 'id = ?', whereArgs: [localId]);
      if (list.isNotEmpty) {
        Map<String, dynamic> decl = list.first;
        try {
          Map<String, dynamic> dataToSync = Map.of(decl);
          dataToSync.remove('id');
          dataToSync.remove('synced');
          await FirebaseFirestore.instance.collection('declarations').add(dataToSync);
          await db.update('declarations', {'synced': 1}, where: 'id = ?', whereArgs: [localId]);
        } catch (e) {
          developer.log("Erreur lors de la synchronisation de la déclaration: $e", name: 'DatabaseHelper');
        }
      }
    }
  }

  Future<void> syncAllLocalDeclarationsToFirestore() async {
    if (await isOnline) {
      final db = await instance.database;
      final List<Map<String, dynamic>> unsynceds = await db.query('declarations', where: 'synced = ?', whereArgs: [0]);
      for (var declaration in unsynceds) {
        try {
          Map<String, dynamic> dataToSync = Map.of(declaration);
          dataToSync.remove('id');
          dataToSync.remove('synced');
          await FirebaseFirestore.instance.collection('declarations').add(dataToSync);
          await db.update('declarations', {'synced': 1}, where: 'id = ?', whereArgs: [declaration['id']]);
        } catch (e) {
          developer.log("Erreur lors de la synchronisation des déclarations: $e", name: 'DatabaseHelper');
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getDeclarations() async {
    final db = await instance.database;
    return await db.query('declarations', orderBy: 'id DESC');
  }

  Future<int> deleteDeclaration(int id) async {
    final db = await instance.database;
    return await db.delete('declarations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    try {
      return await db.insert('users', user);
    } catch (e) {
      developer.log("Erreur lors de l'insertion de l'utilisateur: $e", name: 'DatabaseHelper');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'LOWER(email) = ?',
        whereArgs: [email.toLowerCase().trim()],
      );
      if (maps.isNotEmpty) return maps.first;
      return null;
    } catch (e) {
      developer.log("Erreur lors de la récupération de l'utilisateur par email: $e", name: 'DatabaseHelper');
      return null;
    }
  }

  Future<int> updateUserProfilePicture(String email, String profilePicturePath) async {
    try {
      final db = await instance.database;
      return await db.update(
        'users',
        {'profilePicture': profilePicturePath},
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );
    } catch (e) {
      developer.log("Erreur lors de la mise à jour de la photo de profil: $e", name: 'DatabaseHelper');
      rethrow;
    }
  }

  Future<int> updateUserFaceImagePath(String email, String faceImagePath) async {
    try {
      final db = await instance.database;
      return await db.update(
        'users',
        {'faceImagePath': faceImagePath},
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );
    } catch (e) {
      developer.log("Erreur lors de la mise à jour du chemin de l'image faciale: $e", name: 'DatabaseHelper');
      rethrow;
    }
  }

  Future<int> updateUser(String oldEmail, Map<String, dynamic> newData) async {
    try {
      final db = await instance.database;
      return await db.update(
        'users',
        newData,
        where: 'email = ?',
        whereArgs: [oldEmail.toLowerCase().trim()],
      );
    } catch (e) {
      developer.log("Erreur lors de la mise à jour de l'utilisateur: $e", name: 'DatabaseHelper');
      rethrow;
    }
  }

  Future<int> updateUserBiometricId(String email, String biometricId) async {
    try {
      final db = await instance.database;
      return await db.update(
        'users',
        {'biometricId': biometricId},
        where: 'email = ?',
        whereArgs: [email.toLowerCase().trim()],
      );
    } catch (e) {
      developer.log("Erreur lors de la mise à jour de l'ID biométrique: $e", name: 'DatabaseHelper');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByBiometricId(String biometricId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'biometricId = ?',
        whereArgs: [biometricId],
      );
      if (maps.isNotEmpty) return maps.first;
      return null;
    } catch (e) {
      developer.log("Erreur lors de la récupération de l'utilisateur par ID biométrique: $e", name: 'DatabaseHelper');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByFaceImagePath(String faceImagePath) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'faceImagePath = ?',
        whereArgs: [faceImagePath],
      );
      if (maps.isNotEmpty) return maps.first;
      return null;
    } catch (e) {
      developer.log("Erreur lors de la récupération de l'utilisateur par chemin de l'image faciale: $e", name: 'DatabaseHelper');
      return null;
    }
  }
}
