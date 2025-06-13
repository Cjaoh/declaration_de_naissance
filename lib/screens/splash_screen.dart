import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_screen.dart'; 
import '../db/database_helper.dart';
import '../utils/translate.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

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
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut); // More subtle curve
    _checkConnection();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() {
          _connectionStatus = result != ConnectivityResult.none
              ? ConnectionStatus.connected
              : ConnectionStatus.disconnected;
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushReplacementNamed(
          context,
          _connectionStatus == ConnectionStatus.connected
              ? AuthScreen.routeName // Use route names
              : '/offline'); // Consider a dedicated offline screen
    } catch (e) {
      print("Connection check error: $e"); // Log the error
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
                // Logo bien centré
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
                Text(
                  "DECLARATION DE NAISSANCE",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black26,
                        offset: Offset(1, 2),
                      ),
                    ],
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
    // Take BuildContext as parameter
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return Text('Connecté', style: TextStyle(color: Colors.green, fontSize: 12), textAlign: TextAlign.center,); // Smaller font size
      case ConnectionStatus.disconnected:
        return Text('Mode hors ligne',
            style: TextStyle(color: Colors.orange, fontSize: 12), textAlign: TextAlign.center,); // Smaller font size
      case ConnectionStatus.error:
        return Text('Erreur de connexion',
            style: TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center,); // Smaller font size
      default:
        return Text('Vérification de la connexion...',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12), textAlign: TextAlign.center,); // Use theme text color
    }
  }
}

enum ConnectionStatus { checking, connected, disconnected, error }