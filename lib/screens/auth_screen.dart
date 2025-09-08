import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:camera/camera.dart';
import '../db/database_helper.dart';
import 'dart:developer' as developer;
// import 'package:declaration_naissance/widgets/email_verification_dialog.dart'; // Not used yet
// import '../widgets/verification_notification.dart'; // Not used yet

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth';

  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _cameraSlideController;
  // late Animation<Offset> _cameraSlideAnim; // Unused field
  File? _capturedFaceImage;
  bool _faceRecognitionActive = false;
  bool _faceLoginActive = false;
  bool _faceCaptured = false;
  CameraController? _cameraController;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _animationController.forward();
    _cameraSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // _cameraSlideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
    //   CurvedAnimation(parent: _cameraSlideController, curve: Curves.easeInOut),
    // );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cameraSlideController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<bool> _authenticateBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour continuer',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      developer.log(
        "Erreur lors de l'authentification biométrique: $e",
        name: 'AuthScreen',
      );
      return false;
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      final userCredential = await FirebaseAuth.instance.signInWithProvider(
        googleProvider,
      );
      final user = userCredential.user;
      if (user == null) throw Exception('Erreur lors de la connexion Google');

      await _storage.write(key: 'user_email', value: user.email);
      final biometricSuccess = await _authenticateBiometrics();
      if (!biometricSuccess) {
        _showSnackBar('Authentification biométrique requise.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      _showSnackBar('Erreur lors de la connexion Google : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithFace() async {
    setState(() => _isLoading = true);
    try {
      if (_capturedFaceImage == null || !_faceCaptured) {
        _showSnackBar(
          'Veuillez capturer votre visage pour la connexion.',
          Colors.red.shade400,
        );
        setState(() => _isLoading = false);
        return;
      }
      final dbHelper = DatabaseHelper.instance;
      final userLocal = await dbHelper.getUserByFaceImagePath(
        _capturedFaceImage!.path,
      );
      if (userLocal == null) {
        _showSnackBar(
          'Aucun utilisateur trouvé avec ce visage.',
          Colors.red.shade400,
        );
        setState(() => _isLoading = false);
        return;
      }
      await _storage.write(key: 'user_email', value: userLocal['email']);
      final biometricSuccess = await _authenticateBiometrics();
      if (!biometricSuccess) {
        _showSnackBar('Authentification biométrique requise.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      _showSnackBar('Erreur lors de la connexion par visage : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_faceRecognitionActive) {
      setState(() {
        _faceRecognitionActive = false;
        _faceLoginActive = false;
        _capturedFaceImage = null;
        _faceCaptured = false;
      });
    }
    setState(() => _isLoading = true);
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);
      if (isOnline) {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final user = credential.user;
        if (user == null) throw Exception("Erreur d'authentification");
        if (!user.emailVerified) {
          await FirebaseAuth.instance.signOut();
          _showSnackBar(
            "Vous devez vérifier votre email avant de vous connecter",
            Colors.red,
          );
          setState(() => _isLoading = false);
          return;
        }
        await _storage.write(key: 'user_email', value: user.email);
      } else {
        final userLocal = await DatabaseHelper.instance.getUserByEmail(email);
        if (userLocal == null) {
          throw Exception("Utilisateur inconnu en mode hors-ligne");
        }
        final localPassword = userLocal['password'];
        if (localPassword != password) {
          throw Exception("Mot de passe incorrect en mode hors-ligne");
        }
        await _storage.write(key: 'user_email', value: email);
      }
      final biometricSuccess = await _authenticateBiometrics();
      if (!biometricSuccess) {
        _showSnackBar('Authentification biométrique requise.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de la connexion';
      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur trouvé avec cet email';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect';
      } else if (e.code == 'invalid-email') {
        message = 'Email invalide';
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      _showSnackBar('Erreur hors-ligne : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      setState(() {});
      _detectFacesContinuously();
    } catch (e) {
      developer.log(
        "Erreur lors du démarrage de la caméra: $e",
        name: 'AuthScreen',
      );
      _showSnackBar('Erreur lors du démarrage de la caméra', Colors.red);
    }
  }

  void _detectFacesContinuously() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!_faceCaptured) {
          await _captureFaceImage();
          await _cameraController?.stopImageStream();
        }
      } catch (e) {
        developer.log(
          "Erreur lors de la détection des visages: $e",
          name: 'AuthScreen',
        );
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<void> _captureFaceImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final file = await _cameraController!.takePicture();
      setState(() {
        _capturedFaceImage = File(file.path);
        _faceRecognitionActive = false;
        _faceCaptured = true;
      });
      _showSnackBar('Visage capturé avec succès !', Colors.green.shade400);
      await Future.delayed(const Duration(seconds: 1));
      await _cameraController?.stopImageStream();
    } catch (e) {
      developer.log(
        "Erreur lors de la capture du visage: $e",
        name: 'AuthScreen',
      );
      _showSnackBar('Erreur lors de la capture du visage', Colors.red);
    }
  }

  Widget _buildStartFaceRecognitionButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.face, size: 20),
      label: const Text(
        'Connexion par visage',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1ABC9C),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed:
          _faceRecognitionActive
              ? null
              : () async {
                setState(() {
                  _capturedFaceImage = null;
                  _faceCaptured = false;
                  _faceRecognitionActive = true;
                  _cameraSlideController.forward(from: 0);
                  _faceLoginActive = true;
                });
                await _startCamera();
              },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _faceRecognitionActive
              ? Stack(
                children: [
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    Positioned.fill(child: CameraPreview(_cameraController!)),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () async {
                        await _cameraController?.stopImageStream();
                        setState(() {
                          _faceRecognitionActive = false;
                          _faceLoginActive = false;
                          _capturedFaceImage = null;
                          _faceCaptured = false;
                        });
                      },
                    ),
                  ),
                  if (_faceLoginActive)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login, size: 22),
                          label:
                              _isLoading
                                  ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Connexion avec le visage',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1ABC9C),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isLoading ? null : _loginWithFace,
                        ),
                      ),
                    ),
                ],
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1ABC9C), Color(0xFF3498DB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Card(
                          elevation: 12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(48),
                                  child: Image.asset(
                                    'assets/images/bb.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildStartFaceRecognitionButton(),
                                const SizedBox(height: 24),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          prefixIcon: const Icon(
                                            Icons.email,
                                            color: Color(0xFF3498DB),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF1ABC9C),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer un email valide';
                                          }
                                          if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value)) {
                                            return 'Veuillez entrer un email valide';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          labelText: 'Mot de passe',
                                          prefixIcon: const Icon(
                                            Icons.lock,
                                            color: Color(0xFF3498DB),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: const Color(0xFF1ABC9C),
                                            ),
                                            onPressed:
                                                () => setState(
                                                  () =>
                                                      _obscurePassword =
                                                          !_obscurePassword,
                                                ),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF1ABC9C),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        validator:
                                            (value) =>
                                                (value?.length ?? 0) < 6
                                                    ? 'Minimum 6 caractères'
                                                    : null,
                                      ),
                                      const SizedBox(height: 26),
                                      ElevatedButton(
                                        onPressed: _isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(
                                            double.infinity,
                                            50,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF1ABC9C,
                                          ),
                                          elevation: 8,
                                          shadowColor: const Color(0xFF16A085),
                                        ),
                                        child:
                                            _isLoading
                                                ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 3,
                                                      ),
                                                )
                                                : const Text(
                                                  'CONNEXION',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(color: Colors.grey),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          'OU',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    icon: Image.asset(
                                      'assets/images/google_logo.png',
                                      height: 28,
                                    ),
                                    label:
                                        _isLoading
                                            ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : const Text(
                                              'Se connecter avec Google',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1ABC9C),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 8,
                                      shadowColor: const Color(0xFFB33628),
                                    ),
                                    onPressed:
                                        _isLoading ? null : _signInWithGoogle,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed:
                                      () => Navigator.pushNamed(
                                        context,
                                        '/register',
                                      ),
                                  child: const Text(
                                    "Créer un compte",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF3498DB),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
