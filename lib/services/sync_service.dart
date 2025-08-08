import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../models/naissance.dart';
import '../db/database_helper.dart';
import 'dart:developer' as developer;

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncDeclarations(List<Naissance> declarations) async {
    final db = await DatabaseHelper.instance.database;
    for (Naissance declaration in declarations) {
      try {
        Map<String, dynamic> data = declaration.toMap();
        data.remove('id');
        await _firestore.collection('declarations').add(data);
        await db.update(
          'declarations',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [declaration.id],
        );
      } catch (e) {
        developer.log("Erreur lors de la synchronisation de la déclaration id=${declaration.id} : $e", name: 'SyncService');
      }
    }
  }

  Future<void> syncUsers(List<Map<String, dynamic>> users) async {
    for (var user in users) {
      try {
        var data = Map<String, dynamic>.from(user);
        data.remove('id');
        await _firestore.collection('users').add(data);
      } catch (e) {
        developer.log("Erreur lors de la synchronisation de l'utilisateur email=${user['email']} : $e", name: 'SyncService');
      }
    }
  }

  Future<void> syncAllUnsynced() async {
    final db = await DatabaseHelper.instance.database;
    final unsyncedRows = await db.query('declarations', where: 'synced = ?', whereArgs: [0]);
    List<Naissance> unsyncedDeclarations = unsyncedRows.map((row) => Naissance.fromMap(row)).toList();
    if (unsyncedDeclarations.isNotEmpty) {
      await syncDeclarations(unsyncedDeclarations);
    }
    
    int dbVersion = 1;
    try {
      final versionResult = await db.rawQuery('PRAGMA user_version');
      if (versionResult.isNotEmpty && versionResult.first.values.first is int) {
        dbVersion = versionResult.first.values.first as int;
      }
    } catch (_) {}
    
    if (dbVersion >= 2) {
      final unsyncedUsers = await db.query('users');
      if (unsyncedUsers.isNotEmpty) {
        await syncUsers(unsyncedUsers);
      }
    }
  }
  
  Future<List<String>> getExistingTables() async {
    final Database db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    return tables.map((t) => t['name'] as String).toList();
  }
}
