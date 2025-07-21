import 'package:flutter/material.dart';
import '../models/naissance.dart';
import '../services/database_service.dart';


class DeclarationProvider with ChangeNotifier {
  List<Naissance> _naissances = [];

  List<Naissance> get naissances => _naissances;

  Future<void> loadNaissances() async {
    final db = await DatabaseService.instance.database;
    final data = await db.query('naissances');
    _naissances = data.map((e) => Naissance.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addNaissance(Naissance naissance) async {
    final db = await DatabaseService.instance.database;
    await db.insert('naissances', naissance.toMap());
    await loadNaissances();
  }
}