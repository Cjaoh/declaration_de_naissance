import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

enum ConnectionStatus { checking, connected, disconnected, error }

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _checkConnection();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          _connectionStatus =
              !connectivityResult.contains(ConnectivityResult.none)
                  ? ConnectionStatus.connected
                  : ConnectionStatus.disconnected;
        });
      }
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        _connectionStatus == ConnectionStatus.connected
            ? AuthScreen.routeName
            : '/offline',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _connectionStatus = ConnectionStatus.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1ABC9C), Color(0xFF3498DB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.asset(
                    'assets/images/bb.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "DECLARATION DE NAISSANCE",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildStatusText(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(BuildContext context) {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return const Text(
          'Connecté',
          style: TextStyle(color: Colors.green, fontSize: 12),
          textAlign: TextAlign.center,
        );
      case ConnectionStatus.disconnected:
        return const Text(
          'Mode hors ligne',
          style: TextStyle(color: Colors.orange, fontSize: 12),
          textAlign: TextAlign.center,
        );
      case ConnectionStatus.error:
        return const Text(
          'Erreur de connexion',
          style: TextStyle(color: Colors.red, fontSize: 12),
          textAlign: TextAlign.center,
        );
      default:
        return Text(
          'Vérification de la connexion...',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        );
    }
  }
}
