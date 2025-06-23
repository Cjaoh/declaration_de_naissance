import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class DeclarationForm extends StatefulWidget {
  static const String routeName = '/form';
  final Map<String, dynamic>? declaration;

  const DeclarationForm({Key? key, this.declaration}) : super(key: key);

  @override
  State<DeclarationForm> createState() => _DeclarationFormState();
}

class _DeclarationFormState extends State<DeclarationForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _lieuController = TextEditingController();
  DateTime? _dateNaissance;
  String? _sexe;

  final _nomPereController = TextEditingController();
  final _prenomPereController = TextEditingController();
  final _nomMereController = TextEditingController();
  final _prenomMereController = TextEditingController();

  String? _statutMaritalParents;
  bool _parentsMaries = false;
  DateTime? _dateMariageParents;
  String? _lieuMariageParents;

  bool _isSubmitting = false;
  bool _showMarriageDetails = false;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _animationController.forward();

    if (widget.declaration != null) {
      _nomController.text = widget.declaration!['nom'] ?? '';
      _prenomController.text = widget.declaration!['prenom'] ?? '';
      _dateNaissance = widget.declaration!['dateNaissance'] != null
          ? DateTime.parse(widget.declaration!['dateNaissance'])
          : null;
      _lieuController.text = widget.declaration!['lieu'] ?? '';
      _sexe = widget.declaration!['sexe'];
      _nomPereController.text = widget.declaration!['nomPere'] ?? '';
      _prenomPereController.text = widget.declaration!['prenomPere'] ?? '';
      _nomMereController.text = widget.declaration!['nomMere'] ?? '';
      _prenomMereController.text = widget.declaration!['prenomMere'] ?? '';
      _statutMaritalParents = widget.declaration!['statutMarital'];
      _parentsMaries = widget.declaration!['parentsMaries'] == 1;
      _dateMariageParents = widget.declaration!['dateMariageParents'] != null
          ? DateTime.parse(widget.declaration!['dateMariageParents'])
          : null;
      _lieuMariageParents = widget.declaration!['lieuMariageParents'];
      _showMarriageDetails = _parentsMaries;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _lieuController.dispose();
    _nomPereController.dispose();
    _prenomPereController.dispose();
    _nomMereController.dispose();
    _prenomMereController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {bool isMarriageDate = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isMarriageDate ? (_dateMariageParents ?? DateTime.now()) : (_dateNaissance ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isMarriageDate) {
          _dateMariageParents = picked;
        } else {
          _dateNaissance = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateNaissance == null) {
      _showValidationError('Veuillez sélectionner une date de naissance');
      return;
    }
    if (_parentsMaries && _dateMariageParents == null) {
      _showValidationError('Veuillez sélectionner la date de mariage des parents');
      return;
    }
    if (_parentsMaries && (_lieuMariageParents == null || _lieuMariageParents!.isEmpty)) {
      _showValidationError('Veuillez indiquer le lieu de mariage des parents');
      return;
    }
    if (!_parentsMaries && (_nomMereController.text.isEmpty || _prenomMereController.text.isEmpty)) {
      _showValidationError('Veuillez compléter les informations de la mère');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'dateNaissance': _dateNaissance!.toIso8601String(),
        'lieu': _lieuController.text,
        'sexe': _sexe,
        'nomPere': _parentsMaries ? _nomPereController.text : null,
        'prenomPere': _parentsMaries ? _prenomPereController.text : null,
        'nomMere': _nomMereController.text,
        'prenomMere': _prenomMereController.text,
        'statutMarital': _statutMaritalParents,
        'parentsMaries': _parentsMaries ? 1 : 0,
        'dateMariageParents': _dateMariageParents?.toIso8601String(),
        'lieuMariageParents': _lieuMariageParents,
        'synced': 0,
      };

      if (widget.declaration != null) {
        await DatabaseHelper.instance.updateDeclaration(widget.declaration!['id'], data);
      } else {
        await DatabaseHelper.instance.insertDeclaration(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déclaration enregistrée avec succès!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF4CAF9E),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showValidationError('Erreur : ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = true,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        validator: isRequired ? (value) => value == null || value.trim().isEmpty ? 'Champ obligatoire' : null : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField(BuildContext context, {bool isMarriageDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectDate(context, isMarriageDate: isMarriageDate),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: isMarriageDate ? 'Date de mariage' : 'Date de naissance',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMarriageDate
                    ? (_dateMariageParents == null ? 'Sélectionner une date' : DateFormat('dd/MM/yyyy').format(_dateMariageParents!))
                    : (_dateNaissance == null ? 'Sélectionner une date' : DateFormat('dd/MM/yyyy').format(_dateNaissance!)),
              ),
              const Icon(Icons.calendar_today),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items,
        onChanged: onChanged,
        validator: isRequired ? (value) => value == null ? 'Champ obligatoire' : null : null,
      ),
    );
  }

  Widget _buildMaritalStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statut marital des parents',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Mariés'),
                selected: _parentsMaries,
                onSelected: (selected) {
                  setState(() {
                    _parentsMaries = true;
                    _statutMaritalParents = 'Marié';
                    _showMarriageDetails = true;
                  });
                },
                selectedColor: const Color(0xFF4CAF9E),
                labelStyle: TextStyle(
                  color: _parentsMaries ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Non mariés'),
                selected: !_parentsMaries,
                onSelected: (selected) {
                  setState(() {
                    _parentsMaries = false;
                    _statutMaritalParents = 'Non marié';
                    _showMarriageDetails = false;
                  });
                },
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: !_parentsMaries ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: _showMarriageDetails
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildDateField(context, isMarriageDate: true),
                    _buildTextField(
                      controller: TextEditingController(text: _lieuMariageParents),
                      label: 'Lieu de mariage',
                      hint: 'Ville où les parents se sont mariés',
                      onChanged: (value) => _lieuMariageParents = value,
                    ),
                  ],
                )
              : Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nomMereController,
                      label: 'Nom de la mère',
                      isRequired: true,
                    ),
                    _buildTextField(
                      controller: _prenomMereController,
                      label: 'Prénom de la mère',
                      isRequired: true,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: const Color(0xFF4CAF9E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'ENREGISTRER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF9E),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4CAF9E).withOpacity(0.3), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclaration de Naissance'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4CAF9E),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFE8F5E9)],
              ),
            ),
            child: Form(
              key: _formKey,
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Informations de l\'enfant'),
                      _buildTextField(controller: _nomController, label: 'Nom de l\'enfant'),
                      _buildTextField(controller: _prenomController, label: 'Prénom de l\'enfant'),
                      _buildDateField(context),
                      _buildTextField(controller: _lieuController, label: 'Lieu de naissance'),
                      _buildDropdownField(
                        value: _sexe,
                        label: 'Sexe',
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Garçon')),
                          DropdownMenuItem(value: 'F', child: Text('Fille')),
                        ],
                        onChanged: (value) => setState(() => _sexe = value),
                      ),
                      _buildSectionTitle('Statut marital des parents'),
                      _buildMaritalStatusField(),
                      _buildSectionTitle('Informations du père'),
                      _parentsMaries ? _buildTextField(controller: _nomPereController, label: 'Nom du père') : const SizedBox.shrink(),
                      _parentsMaries ? _buildTextField(controller: _prenomPereController, label: 'Prénom du père') : const SizedBox.shrink(),
                      _buildSectionTitle('Informations de la mère'),
                      _buildTextField(controller: _nomMereController, label: 'Nom de la mère'),
                      _buildTextField(controller: _prenomMereController, label: 'Prénom de la mère'),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                    ],
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
