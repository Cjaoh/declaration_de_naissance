import 'dart:io';
// import 'dart:math'; // No longer needed
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:camera/camera.dart';
import '../db/database_helper.dart';
import 'dart:developer' as developer;
import 'package:declaration_naissance/widgets/email_verification_dialog.dart';
import 'package:declaration_naissance/widgets/otp_verification_dialog.dart';
import '../services/email_service.dart';
import '../widgets/verification_notification.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  String? _generatedOTP;
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'email': TextEditingController(),
    'password': TextEditingController(),
    'confirm': TextEditingController(),
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
  };
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _profilePicturePath;
  late AnimationController _mainController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _floatController;
  late AnimationController _cameraSlideController;
  // late Animation<double> _opacityAnim; // Unused field
  // late Animation<Offset> _slideAnim; // Unused field
  late Animation<double> _scaleAnim;
  late Animation<double> _floatAnim;
  late List<Animation<Offset>> _fieldSlideAnims;
  // late Animation<Offset> _cameraSlideAnim; // Unused field
  final LocalAuthentication _localAuth = LocalAuthentication();
  File? _capturedFaceImage;
  bool _faceRecognitionActive = false;
  bool _faceCaptured = false;
  CameraController? _cameraController;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _cameraSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // _opacityAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    // _slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    final slideIntervals = [
      [0.0, 0.3],
      [0.1, 0.4],
      [0.2, 0.5],
      [0.3, 0.6],
      [0.4, 0.7],
    ];
    _fieldSlideAnims = List.generate(5, (i) {
      final start = i % 2 == 0 ? -1.5 : 1.5;
      return Tween<Offset>(begin: Offset(start, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _formController,
          curve: Interval(
            slideIntervals[i][0],
            slideIntervals[i][1],
            curve: Curves.elasticOut,
          ),
        ),
      );
    });
    // _cameraSlideAnim = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: _cameraSlideController, curve: Curves.easeInOut));
    _mainController.forward();
    Future.delayed(
      const Duration(milliseconds: 400),
      () => _formController.forward(),
    );
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _mainController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _floatController.dispose();
    _cameraSlideController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  String generateOTP() {
    return EmailService().generateSecureOTP();
  }

  Future<void> _sendOTP(String email) async {
    _generatedOTP = generateOTP();
    final success = await EmailService().sendOTPEmail(email, _generatedOTP!);
    if (success) {
      developer.log(
        'Code OTP envoyé à $email : $_generatedOTP',
        name: 'RegisterScreen',
      );
    } else {
      developer.log(
        'Erreur lors de l\'envoi de l\'OTP à $email',
        name: 'RegisterScreen',
      );
      if (mounted) {
        _snackBar(
          'Erreur lors de l\'envoi du code OTP. Veuillez réessayer.',
          Colors.red.shade400,
        );
      }
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      bool isSupported = await _localAuth.isDeviceSupported();
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
        name: 'RegisterScreen',
      );
      return false;
    }
  }

  Future<void> _createUserProfile(User user) async {
    final dbHelper = DatabaseHelper.instance;
    final firstName = _controllers['firstName']!.text.trim();
    final lastName = _controllers['lastName']!.text.trim();
    final email = _controllers['email']!.text.trim().toLowerCase();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profilePicture': _profilePicturePath ?? '',
      'faceImagePath': _capturedFaceImage?.path ?? '',
      'uid': user.uid,
      'createdAt': Timestamp.now(),
    });
    await dbHelper.insertUser({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': _profilePicturePath,
      'faceImagePath': _capturedFaceImage?.path,
      'password': _controllers['password']!.text.trim(),
    });
  }

  Future<void> _showEmailVerificationDialog(User user) async {
    bool emailVerified = false;
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailVerificationDialog(user: user),
    );
    if (res == true) {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      emailVerified = refreshedUser?.emailVerified ?? false;
    }
    if (!emailVerified) {
      _snackBar('Email toujours non vérifié.', Colors.red.shade400);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _buttonController.forward().then((_) => _buttonController.reverse());
      return;
    }
    if (_controllers['password']!.text != _controllers['confirm']!.text) {
      _snackBar('Les mots de passe ne correspondent pas', Colors.red.shade400);
      return;
    }
    if (_capturedFaceImage == null || !_faceCaptured) {
      _snackBar(
        'Veuillez capturer votre visage avec la caméra pour continuer.',
        Colors.red.shade400,
      );
      return;
    }
    setState(() => _isLoading = true);
    final email = _controllers['email']!.text.trim().toLowerCase();
    final password = _controllers['password']!.text.trim();
    try {
      await _sendOTP(email);

      // Vérifier si l'OTP a été généré et envoyé
      if (_generatedOTP == null) {
        _snackBar(
          'Erreur lors de la génération du code OTP. Veuillez réessayer.',
          Colors.red.shade400,
        );
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      String? enteredOTP = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => OTPVerificationDialog(
              email: email,
              generatedOTP: _generatedOTP!,
              onVerified: (otp) {
                // Callback pour quand l'OTP est vérifié
              },
            ),
      );
      if (enteredOTP == null || enteredOTP != _generatedOTP) {
        if (mounted) {
          VerificationSnackBar.showError(
            context,
            'Code incorrect ou annulé. Inscription annulée.',
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = cred.user;
      if (user == null) {
        throw Exception('Erreur lors de la création de l\'utilisateur');
      }
      await user.sendEmailVerification();
      if (mounted) {
        VerificationSnackBar.showInfo(
          context,
          'Email de vérification envoyé, vérifiez votre boîte mail.',
        );
      }
      await _showEmailVerificationDialog(user);
      await user.reload();
      User? refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null && refreshedUser.emailVerified) {
        await _createUserProfile(refreshedUser);
        if (mounted) {
          VerificationSnackBar.showSuccess(context, 'Inscription réussie !');
        }
        if (!mounted) return;
        bool useBiometrics =
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Activer la reconnaissance biométrique'),
                    content: const Text(
                      'Voulez-vous activer la reconnaissance faciale ou empreinte digitale pour vous connecter plus rapidement ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Plus tard'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Oui'),
                      ),
                    ],
                  ),
            ) ??
            false;
        if (useBiometrics) {
          bool authSuccess = await _authenticateWithBiometrics();
          if (authSuccess && mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (mounted) {
            _snackBar('Échec de la reconnaissance biométrique.', Colors.red);
          }
        } else {
          if (mounted) Navigator.pop(context);
        }
      } else {
        if (mounted) {
          VerificationSnackBar.showError(
            context,
            'Email non vérifié. Inscription annulée.',
          );
        }
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      _snackBar(e.message ?? 'Erreur Firebase', Colors.red);
    } catch (e) {
      _snackBar('Erreur : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        name: 'RegisterScreen',
      );
      _snackBar('Erreur lors du démarrage de la caméra', Colors.red);
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
          name: 'RegisterScreen',
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
      _snackBar('Visage capturé avec succès !', Colors.green.shade400);
      await _cameraController?.stopImageStream();
    } catch (e) {
      developer.log(
        "Erreur lors de la capture du visage: $e",
        name: 'RegisterScreen',
      );
      _snackBar('Erreur lors de la capture du visage', Colors.red);
    }
  }

  Widget _buildStartFaceRecognitionButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.face, size: 24),
      label: const Text(
        'Commencer la reconnaissance faciale',
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
                  _faceRecognitionActive = true;
                  _faceCaptured = false;
                  _cameraSlideController.forward(from: 0);
                });
                await _startCamera();
              },
    );
  }

  Widget _buildHeader() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        children: const [
          SizedBox(height: 20),
          Text(
            'Créer un compte',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    const labels = [
      'Prénom',
      'Nom',
      'Email',
      'Mot de passe',
      'Confirmer le mot de passe',
    ];
    final icons = [
      Icons.person_outline,
      Icons.person,
      Icons.email,
      Icons.lock,
      Icons.lock,
    ];
    final fields = [
      _controllers['firstName']!,
      _controllers['lastName']!,
      _controllers['email']!,
      _controllers['password']!,
      _controllers['confirm']!,
    ];
    final validators = [
      (String? val) =>
          val?.isEmpty ?? true ? 'Veuillez entrer votre prénom' : null,
      (String? val) =>
          val?.isEmpty ?? true ? 'Veuillez entrer votre nom' : null,
      (String? val) {
        if (val == null || val.isEmpty) {
          return 'Veuillez entrer un email valide';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
          return 'Veuillez entrer un email valide';
        }
        return null;
      },
      (String? val) => (val?.length ?? 0) < 6 ? 'Minimum 6 caractères' : null,
      (String? val) =>
          val != _controllers['password']!.text
              ? 'Les mots de passe ne correspondent pas'
              : null,
    ];
    final obs = [false, false, false, _obscurePassword, _obscureConfirm];
    return Column(
      children: List.generate(5, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == 4 ? 0 : 20),
          child: SlideTransition(
            position: _fieldSlideAnims[i],
            child: FadeTransition(
              opacity: _formController,
              child:
                  i < 3
                      ? _buildTextField(
                        fields[i],
                        labels[i],
                        icons[i],
                        validators[i],
                        obs[i],
                      )
                      : _buildPasswordField(
                        fields[i],
                        labels[i],
                        obs[i],
                        i == 3
                            ? () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            )
                            : () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                        validators[i],
                      ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?) validator,
    bool obscure,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator,
        keyboardType:
            label == 'Email' ? TextInputType.emailAddress : TextInputType.text,
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback onToggle,
    String? Function(String?) validator,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRegisterButton() {
    final scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    final rotateAnim = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    return AnimatedBuilder(
      animation: _buttonController,
      builder:
          (context, child) => Transform.scale(
            scale: scaleAnim.value,
            child: Transform.rotate(
              angle: rotateAnim.value,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                          : const Text(
                            'CRÉER MON COMPTE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildLoginLink() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder:
          (context, child) => Transform.translate(
            offset: Offset(_floatAnim.value * 0.1, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Déjà un compte ? Se connecter',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildProfilePicture() {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _profilePicturePath = pickedFile.path;
          });
        }
      },
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage:
            _profilePicturePath != null
                ? FileImage(File(_profilePicturePath!))
                : null,
        child:
            _profilePicturePath == null
                ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Inscription',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
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
                        setState(() => _faceRecognitionActive = false);
                      },
                    ),
                  ),
                ],
              )
              : Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1ABC9C), Color(0xFF3498DB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildProfilePicture(),
                        const SizedBox(height: 16),
                        _buildStartFaceRecognitionButton(),
                        const SizedBox(height: 14),
                        _buildHeader(),
                        const SizedBox(height: 32),
                        Form(key: _formKey, child: _buildFormFields()),
                        const SizedBox(height: 20),
                        _buildRegisterButton(),
                        const SizedBox(height: 20),
                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
