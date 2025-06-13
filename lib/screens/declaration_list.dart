import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../utils/translate.dart';

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
    final data = await DatabaseHelper.instance.getDeclarations();
    setState(() {
      _declarations = data;
      _filteredDeclarations = data;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDeclarations = _declarations.where((d) {
        return (d['nom'] ?? '').toLowerCase().contains(query) ||
               (d['prenom'] ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  void _editDeclaration(Map<String, dynamic> declaration) async {
    final result = await Navigator.pushNamed(
      context,
      '/form',
      arguments: declaration,
    );
    if (result == true) {
      _loadDeclarations();
    }
  }

  void _deleteDeclaration(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer cette déclaration ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteDeclaration(id);
      _loadDeclarations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Déclarations'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom ou prénom',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredDeclarations.isEmpty
                ? const Center(child: Text('Aucune déclaration enregistrée'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredDeclarations.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        int garcons = _filteredDeclarations.where((d) => d['sexe'] == 'M').length;
                        int filles = _filteredDeclarations.where((d) => d['sexe'] == 'F').length;
                        return Card(
                          color: Colors.blue[50],
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.male, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text('Garçons: $garcons', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.female, color: Colors.pink),
                                    const SizedBox(width: 8),
                                    Text('Filles: $filles', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final decl = _filteredDeclarations[index - 1];
                      return AnimatedListItem(
                        index: index - 1,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(decl['nom']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  decl['dateNaissance'] != null
                                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(decl['dateNaissance']))
                                    : '',
                                ),
                                Text(decl['lieu'] ?? ''),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  decl['sexe'] == 'M' ? Icons.male : Icons.female,
                                  color: decl['sexe'] == 'M' ? Colors.blue : Colors.pink,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _editDeclaration(decl),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteDeclaration(decl['id']),
                                ),
                              ],
                            ),
                            onTap: () => _editDeclaration(decl),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/form');
          _loadDeclarations(); // Recharge la liste après retour du formulaire
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const AnimatedListItem({
    required this.index,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * 50, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
