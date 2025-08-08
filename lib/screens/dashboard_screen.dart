import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import 'declaration_form.dart';
import 'declaration_list.dart';
import 'sync_screen.dart';
import 'edit_profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _recentDeclarations = [];
  bool _isLoading = true;
  String _currentUserEmail = '';
  int _totalDeclarations = 0;
  int _todayDeclarations = 0;
  int _syncPending = 0;

  final Color _mainColor = const Color(0xFF4CAF9E);
  final Color _accentColor = const Color(0xFFFF9800);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user email
      final email = await _storage.read(key: 'user_email');
      if (email != null) {
        setState(() => _currentUserEmail = email);
      }
      
      // Load declarations data
      final data = await DatabaseHelper.instance.getDeclarations();
      
      // Calculate statistics
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      setState(() {
        _totalDeclarations = data.length;
        _todayDeclarations = data.where((d) {
          if (d['dateNaissance'] == null) return false;
          final declDate = DateTime.parse(d['dateNaissance']).toLocal();
          final declDay = DateTime(declDate.year, declDate.month, declDate.day);
          return declDay.isAtSameMomentAs(todayStart);
        }).length;
        
        _syncPending = data.where((d) => d['synced'] == 0).length;
        _recentDeclarations = data.reversed.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_mainColor, _mainColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 28, color: Color(0xFF4CAF9E)),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Bonjour,',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Text(
              _currentUserEmail.split('@').first,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenue sur votre tableau de bord',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(IconData icon, String title, int value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF9E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add,
                  label: 'Nouvelle déclaration',
                  color: _mainColor,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeclarationForm(),
                      ),
                    );
                    if (result == true) _loadDashboardData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.list,
                  label: 'Toutes les déclarations',
                  color: _accentColor,
                  onTap: () => Navigator.pushNamed(context, DeclarationList.routeName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.sync,
                  label: 'Synchroniser',
                  color: const Color(0xFF9C27B0),
                  onTap: () => Navigator.pushNamed(context, SyncScreen.routeName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.person,
                  label: 'Profil',
                  color: const Color(0xFF03A9F4),
                  onTap: () => Navigator.pushNamed(context, EditProfileScreen.routeName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDeclarations() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Déclarations récentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF9E),
            ),
          ),
          const SizedBox(height: 12),
          if (_recentDeclarations.isEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Aucune déclaration enregistrée',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentDeclarations.length,
              itemBuilder: (context, index) {
                final decl = _recentDeclarations[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      '${decl['nom']} ${decl['prenom']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Né(e) le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(decl['dateNaissance']))}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Icon(
                      decl['sexe'] == 'M' ? Icons.male : Icons.female,
                      color: decl['sexe'] == 'M' ? Colors.blue : Colors.pink,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeclarationForm(declaration: decl),
                        ),
                      ).then((result) {
                        if (result == true) _loadDashboardData();
                      });
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSyncStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _syncPending > 0 ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _syncPending > 0 ? Colors.orange : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _syncPending > 0 ? Icons.warning : Icons.check_circle,
            color: _syncPending > 0 ? Colors.orange : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _syncPending > 0 
                    ? 'Synchronisation en attente' 
                    : 'Toutes les données sont synchronisées',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _syncPending > 0
                    ? '$_syncPending déclaration(s) en attente de synchronisation'
                    : 'Aucune donnée en attente',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (_syncPending > 0)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, SyncScreen.routeName),
              child: const Text('Synchroniser'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatsCard(
                              Icons.people,
                              'Total',
                              _totalDeclarations,
                              _mainColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatsCard(
                              Icons.today,
                              "Aujourd'hui",
                              _todayDeclarations,
                              _accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatsCard(
                              Icons.cloud_upload,
                              'À synchroniser',
                              _syncPending,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSyncStatus(),
                    ),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    _buildRecentDeclarations(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}