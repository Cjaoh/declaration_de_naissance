import '../utils/translate.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../utils/translate.dart';

class SyncScreen extends StatefulWidget {
  static const String routeName = '/sync';

  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  DateTime? _lastSync;
  late AnimationController _rotationController;

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);

    try {
      await Future.delayed(const Duration(seconds: 2)); // Simuler la synchro
      setState(() {
        _lastSync = DateTime.now();
        _isSyncing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Synchronisation réussie!')),
      );
    } catch (e) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'settings'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: child,
                );
              },
              child: Icon(
                Icons.sync,
                size: 60,
                color: _isSyncing ? const Color(0xFF6C63FF) : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _isSyncing
                ? const Text('Synchronisation en cours...')
                : ElevatedButton(
                    onPressed: _syncData,
                    child: const Text('SYNCHRONISER MAINTENANT'),
                  ),
            const SizedBox(height: 20),
            Text(
              _lastSync == null
                  ? 'Jamais synchronisé'
                  : 'Dernière synchro: ${DateFormat('dd/MM/yyyy HH:mm').format(_lastSync!)}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
