import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class DeclarationForm extends StatefulWidget {
  static const String routeName = '/form';
  final Map<String, dynamic>? declaration;

  const DeclarationForm({super.key, this.declaration});

  @override
  State<DeclarationForm> createState() => _DeclarationFormState();
}

class _DeclarationFormState extends State<DeclarationForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  DateTime? _dateNaissance;
  String? _sexe;
  DateTime? _dateNaissancePere;
  DateTime? _dateNaissanceMere;
  String? _statutPere;
  String? _statutMere;
  String? _statutMaritalParents;
  bool _parentsMaries = false;
  DateTime? _dateMariageParents;
  bool _showMarriageDetails = false;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  final Color _mainColor = const Color(0xFF4CAF9E);
  // final Color _accentColor = const Color(0xFFFF9800); // Unused field
  final Color _backgroundColor = Colors.white;
  final Color _textColor = Colors.grey[800]!;
  final Color _borderColor = Colors.grey[200]!;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    _animationController.forward();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.declaration != null) _populateFields();
  }

  void _initializeControllers() {
    _controllers.addAll({
      'nom': TextEditingController(),
      'prenom': TextEditingController(),
      'lieuNaissance': TextEditingController(),
      'heureNaissance': TextEditingController(),
      'dateNaissance': TextEditingController(),
      'nomPere': TextEditingController(),
      'prenomPere': TextEditingController(),
      'lieuNaissancePere': TextEditingController(),
      'professionPere': TextEditingController(),
      'nationalitePere': TextEditingController(),
      'adressePere': TextEditingController(),
      'pieceIdPere': TextEditingController(),
      'dateNaissancePere': TextEditingController(),
      'nomMere': TextEditingController(),
      'prenomMere': TextEditingController(),
      'nomJeuneFilleMere': TextEditingController(),
      'lieuNaissanceMere': TextEditingController(),
      'professionMere': TextEditingController(),
      'nationaliteMere': TextEditingController(),
      'adresseMere': TextEditingController(),
      'pieceIdMere': TextEditingController(),
      'dateNaissanceMere': TextEditingController(),
      'lieuMariageParents': TextEditingController(),
      'nomDeclarant': TextEditingController(),
      'prenomDeclarant': TextEditingController(),
      'adresseDeclarant': TextEditingController(),
      'lienDeclarant': TextEditingController(),
      'pieceIdDeclarant': TextEditingController(),
      'certificatAccouchement': TextEditingController(),
      'livretFamille': TextEditingController(),
      'acteNaissPere': TextEditingController(),
      'acteNaissMere': TextEditingController(),
      'acteReconnaissance': TextEditingController(),
      'certificatNationalite': TextEditingController(),
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context, {
    required String controllerKey,
    bool isMarriageDate = false,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isMarriageDate) {
          _dateMariageParents = picked;
        } else {
          switch (controllerKey) {
            case 'dateNaissance':
              _dateNaissance = picked;
              break;
            case 'dateNaissancePere':
              _dateNaissancePere = picked;
              break;
            case 'dateNaissanceMere':
              _dateNaissanceMere = picked;
              break;
          }
        }
        _updateDateControllerText();
      });
    }
  }

  void _updateDateControllerText() {
    if (_dateNaissance != null) {
      _controllers['dateNaissance']!.text = DateFormat(
        'dd/MM/yyyy',
      ).format(_dateNaissance!);
    }
    if (_dateNaissancePere != null) {
      _controllers['dateNaissancePere']!.text = DateFormat(
        'dd/MM/yyyy',
      ).format(_dateNaissancePere!);
    }
    if (_dateNaissanceMere != null) {
      _controllers['dateNaissanceMere']!.text = DateFormat(
        'dd/MM/yyyy',
      ).format(_dateNaissanceMere!);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateNaissance == null) {
      _showValidationError(
        'Veuillez sélectionner la date de naissance de l\'enfant',
      );
      _tabController.animateTo(0);
      return;
    }

    if (_parentsMaries) {
      if (_dateMariageParents == null) {
        _showValidationError(
          'Veuillez sélectionner la date de mariage des parents',
        );
        _tabController.animateTo(1);
        return;
      }
      if (_controllers['lieuMariageParents']!.text.isEmpty) {
        _showValidationError(
          'Veuillez indiquer le lieu de mariage des parents',
        );
        _tabController.animateTo(1);
        return;
      }
      if (_controllers['nomPere']!.text.isEmpty ||
          _controllers['prenomPere']!.text.isEmpty) {
        _showValidationError('Veuillez compléter les informations du père');
        _tabController.animateTo(1);
        return;
      }
    }

    if (_controllers['nomMere']!.text.isEmpty ||
        _controllers['prenomMere']!.text.isEmpty) {
      _showValidationError('Veuillez compléter les informations de la mère');
      _tabController.animateTo(1);
      return;
    }

    if (!_validatePieceId(_controllers['pieceIdPere']!.text)) {
      _showValidationError(
        'Numéro pièce d\'identité du père invalide (doit être alphanumérique et faire entre 9 et 12 caractères)',
      );
      _tabController.animateTo(1);
      return;
    }

    if (!_validatePieceId(_controllers['pieceIdMere']!.text)) {
      _showValidationError(
        'Numéro pièce d\'identité de la mère invalide (doit être alphanumérique et faire entre 9 et 12 caractères)',
      );
      _tabController.animateTo(1);
      return;
    }

    if (!_validatePieceId(_controllers['pieceIdDeclarant']!.text)) {
      _showValidationError(
        'Numéro pièce d\'identité du déclarant invalide (doit être alphanumérique et faire entre 9 et 12 caractères)',
      );
      _tabController.animateTo(2);
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'nom': _controllers['nom']!.text,
      'prenom': _controllers['prenom']!.text,
      'dateNaissance': _dateNaissance!.toIso8601String(),
      'heureNaissance': _controllers['heureNaissance']!.text,
      'lieuNaissance': _controllers['lieuNaissance']!.text,
      'sexe': _sexe,
      'nomPere': _controllers['nomPere']!.text,
      'prenomPere': _controllers['prenomPere']!.text,
      'dateNaissancePere': _dateNaissancePere?.toIso8601String(),
      'lieuNaissancePere': _controllers['lieuNaissancePere']!.text,
      'professionPere': _controllers['professionPere']!.text,
      'nationalitePere': _controllers['nationalitePere']!.text,
      'adressePere': _controllers['adressePere']!.text,
      'pieceIdPere': _controllers['pieceIdPere']!.text,
      'statutPere': _statutPere,
      'nomMere': _controllers['nomMere']!.text,
      'prenomMere': _controllers['prenomMere']!.text,
      'nomJeuneFilleMere': _controllers['nomJeuneFilleMere']!.text,
      'dateNaissanceMere': _dateNaissanceMere?.toIso8601String(),
      'lieuNaissanceMere': _controllers['lieuNaissanceMere']!.text,
      'professionMere': _controllers['professionMere']!.text,
      'nationaliteMere': _controllers['nationaliteMere']!.text,
      'adresseMere': _controllers['adresseMere']!.text,
      'pieceIdMere': _controllers['pieceIdMere']!.text,
      'statutMere': _statutMere,
      'statutMarital': _statutMaritalParents,
      'parentsMaries': _parentsMaries ? 1 : 0,
      'dateMariageParents': _dateMariageParents?.toIso8601String(),
      'lieuMariageParents': _controllers['lieuMariageParents']!.text,
      'nomDeclarant': _controllers['nomDeclarant']!.text,
      'prenomDeclarant': _controllers['prenomDeclarant']!.text,
      'adresseDeclarant': _controllers['adresseDeclarant']!.text,
      'lienDeclarant': _controllers['lienDeclarant']!.text,
      'pieceIdDeclarant': _controllers['pieceIdDeclarant']!.text,
      'certificatAccouchement': _controllers['certificatAccouchement']!.text,
      'livretFamille': _controllers['livretFamille']!.text,
      'acteNaissPere': _controllers['acteNaissPere']!.text,
      'acteNaissMere': _controllers['acteNaissMere']!.text,
      'acteReconnaissance': _controllers['acteReconnaissance']!.text,
      'certificatNationalite': _controllers['certificatNationalite']!.text,
      'synced': 0,
    };

    try {
      if (widget.declaration != null) {
        await DatabaseHelper.instance.updateDeclaration(
          widget.declaration!['id'],
          data,
        );
      } else {
        await DatabaseHelper.instance.insertDeclaration(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Déclaration enregistrée avec succès!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _mainColor,
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

  bool _validatePieceId(String value) {
    if (value.trim().isEmpty) return true; // Optional field, skip if empty
    final regExp = RegExp(r'^[a-zA-Z0-9]{9,12}$');
    return regExp.hasMatch(value.trim());
  }

  void _populateFields() {
    final d = widget.declaration!;
    _controllers['nom']!.text = d['nom'] ?? '';
    _controllers['prenom']!.text = d['prenom'] ?? '';
    _dateNaissance =
        d['dateNaissance'] != null ? DateTime.parse(d['dateNaissance']) : null;
    _controllers['lieuNaissance']!.text = d['lieuNaissance'] ?? '';
    _controllers['heureNaissance']!.text = d['heureNaissance'] ?? '';
    _sexe = d['sexe'];
    _controllers['nomPere']!.text = d['nomPere'] ?? '';
    _controllers['prenomPere']!.text = d['prenomPere'] ?? '';
    _dateNaissancePere =
        d['dateNaissancePere'] != null
            ? DateTime.parse(d['dateNaissancePere'])
            : null;
    _controllers['lieuNaissancePere']!.text = d['lieuNaissancePere'] ?? '';
    _controllers['professionPere']!.text = d['professionPere'] ?? '';
    _controllers['nationalitePere']!.text = d['nationalitePere'] ?? '';
    _controllers['adressePere']!.text = d['adressePere'] ?? '';
    _controllers['pieceIdPere']!.text = d['pieceIdPere'] ?? '';
    _statutPere = d['statutPere'] ?? 'Vivant';
    _controllers['nomMere']!.text = d['nomMere'] ?? '';
    _controllers['prenomMere']!.text = d['prenomMere'] ?? '';
    _controllers['nomJeuneFilleMere']!.text = d['nomJeuneFilleMere'] ?? '';
    _dateNaissanceMere =
        d['dateNaissanceMere'] != null
            ? DateTime.parse(d['dateNaissanceMere'])
            : null;
    _controllers['lieuNaissanceMere']!.text = d['lieuNaissanceMere'] ?? '';
    _controllers['professionMere']!.text = d['professionMere'] ?? '';
    _controllers['nationaliteMere']!.text = d['nationaliteMere'] ?? '';
    _controllers['adresseMere']!.text = d['adresseMere'] ?? '';
    _controllers['pieceIdMere']!.text = d['pieceIdMere'] ?? '';
    _statutMere = d['statutMere'] ?? 'Vivant';
    _statutMaritalParents = d['statutMarital'];
    _parentsMaries = d['parentsMaries'] == 1;
    _dateMariageParents =
        d['dateMariageParents'] != null
            ? DateTime.parse(d['dateMariageParents'])
            : null;
    _showMarriageDetails = _parentsMaries;
    _controllers['lieuMariageParents']!.text = d['lieuMariageParents'] ?? '';
    _controllers['nomDeclarant']!.text = d['nomDeclarant'] ?? '';
    _controllers['prenomDeclarant']!.text = d['prenomDeclarant'] ?? '';
    _controllers['adresseDeclarant']!.text = d['adresseDeclarant'] ?? '';
    _controllers['lienDeclarant']!.text = d['lienDeclarant'] ?? '';
    _controllers['pieceIdDeclarant']!.text = d['pieceIdDeclarant'] ?? '';
    _controllers['certificatAccouchement']!.text =
        d['certificatAccouchement'] ?? '';
    _controllers['livretFamille']!.text = d['livretFamille'] ?? '';
    _controllers['acteNaissPere']!.text = d['acteNaissPere'] ?? '';
    _controllers['acteNaissMere']!.text = d['acteNaissMere'] ?? '';
    _controllers['acteReconnaissance']!.text = d['acteReconnaissance'] ?? '';
    _controllers['certificatNationalite']!.text =
        d['certificatNationalite'] ?? '';
    _updateDateControllerText();
  }

  Widget _buildTextField({
    required String controllerKey,
    required String label,
    String? hint,
    bool isRequired = true,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[controllerKey],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          filled: true,
          fillColor: _backgroundColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _mainColor, width: 2),
          ),
        ),
        keyboardType: keyboardType,
        validator:
            isRequired
                ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Champ obligatoire';
                  }
                  return null;
                }
                : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePickerTextField({
    required String controllerKey,
    required String label,
    bool isRequired = true,
    bool isMarriageDate = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[controllerKey],
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          filled: true,
          fillColor: _backgroundColor,
          suffixIcon: Icon(Icons.calendar_today, color: _mainColor),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _mainColor, width: 2),
          ),
        ),
        validator:
            isRequired
                ? (value) =>
                    value == null || value.isEmpty ? 'Champ obligatoire' : null
                : null,
        onTap:
            () async => await _selectDate(
              context,
              controllerKey: controllerKey,
              isMarriageDate: isMarriageDate,
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
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          filled: true,
          fillColor: _backgroundColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _mainColor, width: 2),
          ),
        ),
        items: items,
        onChanged: onChanged,
        validator:
            isRequired
                ? (value) => value == null ? 'Champ obligatoire' : null
                : null,
        style: TextStyle(color: _textColor),
      ),
    );
  }

  Widget _buildMaritalStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Mariés'),
                selected: _parentsMaries,
                onSelected:
                    (_) => setState(() {
                      _parentsMaries = true;
                      _statutMaritalParents = 'Marié';
                      _showMarriageDetails = true;
                    }),
                selectedColor: _mainColor,
                labelStyle: TextStyle(
                  color: _parentsMaries ? Colors.white : _textColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Non mariés'),
                selected: !_parentsMaries,
                onSelected:
                    (_) => setState(() {
                      _parentsMaries = false;
                      _statutMaritalParents = 'Non marié';
                      _showMarriageDetails = false;
                    }),
                selectedColor: _mainColor,
                labelStyle: TextStyle(
                  color: !_parentsMaries ? Colors.white : _textColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child:
              _showMarriageDetails
                  ? Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildDatePickerTextField(
                        controllerKey: 'dateMariageParents',
                        label: 'Date de mariage',
                        isMarriageDate: true,
                      ),
                      _buildTextField(
                        controllerKey: 'lieuMariageParents',
                        label: 'Lieu de mariage',
                        hint: 'Ville où les parents se sont mariés',
                      ),
                    ],
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildParentStatusField(
    String parent,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return _buildDropdownField(
      value: value,
      label: 'Statut du $parent',
      items: const [
        DropdownMenuItem(value: 'Vivant', child: Text('Vivant')),
        DropdownMenuItem(value: 'Décédé', child: Text('Décédé')),
      ],
      onChanged: onChanged,
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _mainColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              color: _mainColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Informations de l'enfant"),
        _buildTextField(controllerKey: 'nom', label: "Nom de l'enfant"),
        _buildTextField(controllerKey: 'prenom', label: "Prénom de l'enfant"),
        _buildDatePickerTextField(
          controllerKey: 'dateNaissance',
          label: 'Date de naissance',
        ),
        _buildTextField(
          controllerKey: 'heureNaissance',
          label: 'Heure de naissance',
          hint: 'HH:mm',
          keyboardType: TextInputType.datetime,
        ),
        _buildTextField(
          controllerKey: 'lieuNaissance',
          label: "Lieu de naissance",
        ),
        _buildDropdownField(
          value: _sexe,
          label: 'Sexe',
          items: const [
            DropdownMenuItem(value: "M", child: Text('Garçon')),
            DropdownMenuItem(value: "F", child: Text('Fille')),
          ],
          onChanged: (value) => setState(() => _sexe = value),
        ),
      ],
    );
  }

  Widget _buildParentsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Statut marital des parents'),
        _buildMaritalStatusField(),
        if (_parentsMaries) ...[
          _buildSectionTitle("Informations du père"),
          _buildTextField(
            controllerKey: 'nomPere',
            label: 'Nom du père',
            isRequired: true,
          ),
          _buildTextField(
            controllerKey: 'prenomPere',
            label: 'Prénom du père',
            isRequired: true,
          ),
          _buildDatePickerTextField(
            controllerKey: 'dateNaissancePere',
            label: 'Date de naissance du père',
            isRequired: false,
          ),
          _buildTextField(
            controllerKey: 'lieuNaissancePere',
            label: 'Lieu de naissance du père',
            isRequired: false,
          ),
          _buildTextField(
            controllerKey: 'professionPere',
            label: 'Profession du père',
            isRequired: false,
          ),
          _buildTextField(
            controllerKey: 'nationalitePere',
            label: 'Nationalité du père',
            isRequired: false,
          ),
          _buildTextField(
            controllerKey: 'adressePere',
            label: 'Adresse du père',
            isRequired: false,
          ),
          _buildTextField(
            controllerKey: 'pieceIdPere',
            label: 'Numéro pièce d\'identité du père',
            isRequired: false,
          ),
          _buildParentStatusField(
            'père',
            _statutPere,
            (value) => setState(() => _statutPere = value),
          ),
        ],
        _buildSectionTitle("Informations de la mère"),
        _buildTextField(controllerKey: 'nomMere', label: 'Nom de la mère'),
        _buildTextField(
          controllerKey: 'prenomMere',
          label: 'Prénom de la mère',
        ),
        _buildDatePickerTextField(
          controllerKey: 'dateNaissanceMere',
          label: 'Date de naissance de la mère',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'lieuNaissanceMere',
          label: 'Lieu de naissance de la mère',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'professionMere',
          label: 'Profession de la mère',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'nationaliteMere',
          label: 'Nationalité de la mère',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'adresseMere',
          label: 'Adresse de la mère',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'pieceIdMere',
          label: 'Numéro pièce d\'identité de la mère',
          isRequired: false,
        ),
        _buildParentStatusField(
          'mère',
          _statutMere,
          (value) => setState(() => _statutMere = value),
        ),
      ],
    );
  }

  Widget _buildDeclarantInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations du déclarant'),
        _buildTextField(
          controllerKey: 'nomDeclarant',
          label: 'Nom du déclarant',
        ),
        _buildTextField(
          controllerKey: 'prenomDeclarant',
          label: 'Prénom du déclarant',
        ),
        _buildTextField(
          controllerKey: 'adresseDeclarant',
          label: 'Adresse du déclarant',
        ),
        _buildTextField(
          controllerKey: 'lienDeclarant',
          label: 'Lien avec l\'enfant',
        ),
        _buildTextField(
          controllerKey: 'pieceIdDeclarant',
          label: 'Numéro pièce d\'identité du déclarant',
        ),
      ],
    );
  }

  Widget _buildDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Documents justificatifs'),
        _buildTextField(
          controllerKey: 'certificatAccouchement',
          label: 'Certificat d\'accouchement',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'livretFamille',
          label: 'Livret de famille',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'acteNaissPere',
          label: 'Acte de naissance du père',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'acteNaissMere',
          label: 'Acte de naissance de la mère',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'acteReconnaissance',
          label: 'Acte de reconnaissance',
          isRequired: false,
        ),
        _buildTextField(
          controllerKey: 'certificatNationalite',
          label: 'Certificat de nationalité',
          isRequired: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Déclaration de Naissance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.black12,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: _mainColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_mainColor, _mainColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submit,
            tooltip: 'Enregistrer',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Enfant', icon: Icon(Icons.child_care)),
            Tab(text: 'Parents', icon: Icon(Icons.family_restroom)),
            Tab(text: 'Déclarant', icon: Icon(Icons.person)),
            Tab(text: 'Documents', icon: Icon(Icons.attach_file)),
          ],
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildChildInfo(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildParentsInfo(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildDeclarantInfo(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildDocuments(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
