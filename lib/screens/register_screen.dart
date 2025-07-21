import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
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
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _floatAnim;
  late List<Animation<Offset>> _fieldSlideAnims;

  @override
  void initState() {
    super.initState();
    _mainController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _formController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _buttonController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _floatController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _initAnims();
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _formController.forward());
    _floatController.repeat(reverse: true);
  }

  void _initAnims() {
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _mainController, curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    final slideIntervals = [
      [0.0, 0.3],
      [0.1, 0.4],
      [0.2, 0.5],
      [0.3, 0.6],
      [0.4, 0.7]
    ];
    _fieldSlideAnims = List.generate(5, (i) {
      final start = i % 2 == 0 ? -1.5 : 1.5;
      return Tween<Offset>(begin: Offset(start, 0), end: Offset.zero).animate(
        CurvedAnimation(
            parent: _formController,
            curve: Interval(slideIntervals[i][0], slideIntervals[i][1],
                curve: Curves.elasticOut)),
      );
    });
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    _buttonController.forward().then((_) => _buttonController.reverse());
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profilePicturePath = pickedFile.path);
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
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getUserByEmail(_controllers['email']!.text);
      if (user == null) {
        await dbHelper.insertUser({
          'email': _controllers['email']!.text,
          'password': _controllers['password']!.text,
          'firstName': _controllers['firstName']!.text,
          'lastName': _controllers['lastName']!.text,
          'profilePicture': _profilePicturePath,
        });
        if (!mounted) return;
        _snackBar('Inscription réussie !', Colors.green.shade400);
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        _snackBar('Un utilisateur avec cet email existe déjà', Colors.orange.shade400);
      }
    } catch (e) {
      if (!mounted) return;
      _snackBar('Une erreur est survenue: $e', Colors.red.shade400);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Inscription',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
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
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _opacityAnim,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfilePicture(),
                        const SizedBox(height: 16),
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildFormFields(),
                        const SizedBox(height: 32),
                        _buildRegisterButton(),
                        const SizedBox(height: 20),
                        _buildLoginLink(),
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

  Widget _buildProfilePicture() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _profilePicturePath != null
                        ? FileImage(File(_profilePicturePath!))
                        : null,
                    child: _profilePicturePath == null
                        ? const Icon(Icons.camera_alt,
                            color: Colors.white, size: 40)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 8,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1ABC9C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.add_a_photo,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
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
          const SizedBox(height: 8),
          Text(
            '',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w300,
            ),
          ),
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
      'Confirmer le mot de passe'
    ];
    final icons = [
      Icons.person_outline,
      Icons.person,
      Icons.email,
      Icons.lock,
      Icons.lock
    ];
    final fields = [
      _controllers['firstName']!,
      _controllers['lastName']!,
      _controllers['email']!,
      _controllers['password']!,
      _controllers['confirm']!
    ];
    final validators = [
      (String? val) => val?.isEmpty ?? true ? 'Veuillez entrer votre prénom' : null,
      (String? val) => val?.isEmpty ?? true ? 'Veuillez entrer votre nom' : null,
      (String? val) {
        if (val == null || val.isEmpty) return 'Veuillez entrer un email valide';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
          return 'Veuillez entrer un email valide';
        }
        return null;
      },
      (String? val) => (val?.length ?? 0) < 6 ? 'Minimum 6 caractères' : null,
      (String? val) =>
          val != _controllers['password']!.text ? 'Les mots de passe ne correspondent pas' : null,
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
              child: i < 3
                  ? _buildTextField(
                      fields[i], labels[i], icons[i], validators[i], obs[i])
                  : _buildPasswordField(
                      fields[i],
                      labels[i],
                      obs[i],
                      i == 3
                          ? () => setState(() => _obscurePassword = !_obscurePassword)
                          : () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validators[i]),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, String? Function(String?) validator, bool obscure) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 2)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      String? Function(String?) validator) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade300, width: 2)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      builder: (context, child) => Transform.scale(
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
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1ABC9C),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: const Color(0xFF1ABC9C), strokeWidth: 3),
                    )
                  : const Text(
                      'CRÉER MON COMPTE',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2),
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
      builder: (context, child) => Transform.translate(
        offset: Offset(_floatAnim.value * 0.1, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
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
}
