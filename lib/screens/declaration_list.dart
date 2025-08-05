import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'declaration_form.dart';

class DeclarationList extends StatefulWidget {
  static const String routeName = '/list';

  const DeclarationList({super.key});

  @override
  State<DeclarationList> createState() => _DeclarationListState();
}

class _DeclarationListState extends State<DeclarationList> {
  List<Map<String, dynamic>> _declarations = [];
  List<Map<String, dynamic>> _filteredDeclarations = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeclarations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeclarations() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getDeclarations();
    setState(() {
      _declarations = data;
      _filteredDeclarations = data;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDeclarations = _declarations.where((d) {
        return (d['nom']?.toString().toLowerCase() ?? '').contains(query) ||
            (d['prenom']?.toString().toLowerCase() ?? '').contains(query) ||
            (d['nomPere']?.toString().toLowerCase() ?? '').contains(query) ||
            (d['nomMere']?.toString().toLowerCase() ?? '').contains(query);
      }).toList();
    });
  }

  Future<void> _editDeclaration(Map<String, dynamic> declaration) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationForm(declaration: declaration),
      ),
    );
    if (result == true) {
      _loadDeclarations();
    }
  }

  Future<void> _deleteDeclaration(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cette déclaration ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteDeclaration(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déclaration supprimée avec succès'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF4CAF9E),
          ),
        );
      }
      _loadDeclarations();
    }
  }

  Widget _buildStatsCard() {
    int garcons = _filteredDeclarations.where((d) => d['sexe'] == 'M').length;
    int filles = _filteredDeclarations.where((d) => d['sexe'] == 'F').length;
    int maries = _filteredDeclarations.where((d) => d['parentsMaries'] == 1).length;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.male, 'Garçons', garcons, Colors.blue),
                _buildStatItem(Icons.female, 'Filles', filles, Colors.pink),
                _buildStatItem(Icons.family_restroom, 'Mariés', maries, const Color(0xFF4CAF9E)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${_filteredDeclarations.length} déclarations',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDeclarationItem(Map<String, dynamic> decl, int index) {
    final isMarried = decl['parentsMaries'] == 1;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editDeclaration(decl),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${decl['nom']} ${decl['prenom']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(decl['sexe'] == 'M' ? Icons.male : Icons.female,
                      color: decl['sexe'] == 'M' ? Colors.blue : Colors.pink),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Né(e) le : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(decl['dateNaissance']))} à ${decl['heureNaissance'] ?? 'HH:mm'}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text('Lieu : ${decl['lieuNaissance'] ?? 'Non spécifié'}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              _buildParentInfo('Père', decl['nomPere'], decl['prenomPere'], decl['statutPere']),
              _buildParentInfo('Mère', decl['nomMere'], decl['prenomMere'], decl['statutMere']),
              if (decl['nomJeuneFilleMere'] != null && decl['nomJeuneFilleMere'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('Nom de jeune fille de la mère : ${decl['nomJeuneFilleMere']}',
                      style: const TextStyle(color: Colors.grey)),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isMarried ? Icons.favorite : Icons.favorite_border,
                    color: isMarried ? Colors.red : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isMarried ? 'Parents mariés' : 'Parents non mariés',
                      style: TextStyle(color: isMarried ? const Color(0xFF4CAF9E) : Colors.grey, fontSize: 14),
                    ),
                  ),
                  if (isMarried && decl['dateMariageParents'] != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(decl['dateMariageParents']))}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                  if (isMarried && decl['lieuMariageParents'] != null && decl['lieuMariageParents'].toString().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'à ${decl['lieuMariageParents']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _editDeclaration(decl)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteDeclaration(decl['id'])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentInfo(String role, String? nom, String? prenom, String? statut) {
    IconData icon = statut == 'Vivant' ? Icons.check_circle : Icons.highlight_off;
    Color iconColor = statut == 'Vivant' ? Colors.green : Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$role : ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Expanded(child: Text('${nom ?? 'Non spécifié'} ${prenom ?? ''}', style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Déclarations'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4CAF9E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _filteredDeclarations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty ? 'Aucune déclaration enregistrée' : 'Aucun résultat trouvé',
                                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredDeclarations.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildStatsCard();
                              return _buildDeclarationItem(_filteredDeclarations[index - 1], index - 1);
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const DeclarationForm()));
          if (result == true) _loadDeclarations();
        },
        backgroundColor: const Color(0xFF4CAF9E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
