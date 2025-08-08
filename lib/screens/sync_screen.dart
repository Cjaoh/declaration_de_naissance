import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';
import '../utils/translate.dart';

class SyncScreen extends StatefulWidget {
  static const String routeName = '/sync';
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  DateTime? _lastSync;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    final syncService = SyncService();

    try {
      final tables = await syncService.getExistingTables();
      if (!tables.contains('users')) {
        throw Exception('La table "users" est absente dans la base locale.');
      }
      await syncService.syncAllUnsynced();
      setState(() {
        _lastSync = DateTime.now();
        _isSyncing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synchronisation réussie!')),
        );
      }
    } catch (e) {
      setState(() => _isSyncing = false);
      String message;
      if (e.toString().contains('no such table: users')) {
        message = 'Erreur critique : la table "users" est manquante. Veuillez vérifier l’installation.';
      } else if (e.toString().contains('La table "users" est absente')) {
        message = e.toString();
      } else {
        message = 'Erreur lors de la synchronisation : $e';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF4CAF9E);

    return Scaffold(
      backgroundColor: themeColor,
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        title: Text(tr(context, 'settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) => Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: child,
                ),
                child: Icon(
                  Icons.sync,
                  size: 80,
                  color: _isSyncing ? Colors.white : Colors.white54,
                ),
              ),
              const SizedBox(height: 30),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isSyncing
                    ? Text(
                        'Synchronisation en cours...',
                        key: const ValueKey('syncing'),
                        style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
                      )
                    : ElevatedButton(
                        key: const ValueKey('button'),
                        onPressed: _syncData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 6,
                          shadowColor: Colors.black45,
                        ),
                        child: Text(
                          'SYNCHRONISER MAINTENANT',
                          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
              ),
              const SizedBox(height: 30),
              Text(
                _lastSync == null
                    ? 'Jamais synchronisé'
                    : 'Dernière synchro: ${DateFormat('dd/MM/yyyy HH:mm').format(_lastSync!)}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
