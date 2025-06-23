import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      final user = await dbHelper.getUserByEmail(_emailController.text);

      if (user == null) {
        await dbHelper.insertUser({
          'email': _emailController.text,
          'password': _passwordController.text,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inscription réussie !')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un utilisateur avec cet email existe déjà')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une erreur est survenue: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Veuillez entrer un email valide' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) =>
                    ((value?.length ?? 0) < 6) ? 'Minimum 6 caractères' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                obscureText: _obscureConfirm,
                validator: (value) =>
                    value != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('INSCRIPTION'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Déjà un compte ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
