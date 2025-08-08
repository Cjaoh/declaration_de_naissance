import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../services/database_service.dart';

class AgentProvider with ChangeNotifier {
  List<Agent> _agents = [];

  List<Agent> get agents => _agents;

  Future<void> loadAgents() async {
    final db = await DatabaseService.instance.database;
    final data = await db.query('users');
    _agents = data.map((e) => Agent.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addAgent(Agent agent) async {
    final db = await DatabaseService.instance.database;
    await db.insert('users', agent.toMap());
    await loadAgents();
  }
}