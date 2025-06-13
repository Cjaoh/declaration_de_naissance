import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../db/database_helper.dart';
import '../utils/translate.dart';

class DeclarationForm extends StatefulWidget {
  static const String routeName = '/form';

  const DeclarationForm({super.key});

  @override
  State<DeclarationForm> createState() => _DeclarationFormState();
}

class _DeclarationFormState extends State<DeclarationForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _lieuController = TextEditingController();
  DateTime? _dateNaissance;
  String? _sexe;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;


  static const InputDecoration _inputDecoration = InputDecoration(
    border: OutlineInputBorder(),
  );

 
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  
  @override
  void dispose() {
    _animationController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _lieuController.dispose();
    super.dispose();
  }

  
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'dateNaissance': _dateNaissance?.toIso8601String(),
        'lieu': _lieuController.text,
        'sexe': _sexe,
        'synced': 0,
      };
      await DatabaseHelper.instance.insertDeclaration(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Déclaration enregistrée avec succès!')),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclaration de Naissance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_nomController, 'Nom de l\'enfant'),
                const SizedBox(height: 16),
                _buildTextField(_prenomController, 'Prénom de l\'enfant'),
                const SizedBox(height: 16),
                _buildDateField(context),
                const SizedBox(height: 16),
                _buildTextField(_lieuController, 'Lieu de naissance'),
                const SizedBox(height: 16),
                _buildDropdownField(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

 
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration.copyWith(labelText: label),
      validator: (value) => value?.isEmpty ?? true ? 'Champ obligatoire' : null,
    );
  }

  // Helper method to build date field
  Widget _buildDateField(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: _inputDecoration.copyWith(labelText: 'Date de naissance'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateNaissance == null
                  ? 'Sélectionner une date'
                  : DateFormat('dd/MM/yyyy').format(_dateNaissance!),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  // Helper method to build dropdown field
  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _sexe,
      decoration: _inputDecoration.copyWith(labelText: 'Sexe'),
      items: const [
        DropdownMenuItem(value: 'M', child: Text('Garçon')),
        DropdownMenuItem(value: 'F', child: Text('Fille')),
      ],
      onChanged: (value) => setState(() => _sexe = value),
      validator: (value) => value == null ? 'Champ obligatoire' : null,
    );
  }

  // Helper method to build submit button
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isSubmitting
          ? const CircularProgressIndicator()
          : const Text('ENREGISTRER'),
    );
  }
}