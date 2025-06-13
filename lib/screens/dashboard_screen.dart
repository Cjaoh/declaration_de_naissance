import 'package:flutter/material.dart';
import 'declaration_list.dart';
import 'sync_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';
import '../db/database_helper.dart';
import '../utils/translate.dart';

class DashboardScreen extends StatelessWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _DashboardItem(
        icon: Icons.child_care,
        title: 'Déclarer',
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/form'),
      ),
      _DashboardItem(
        icon: Icons.list_alt,
        title: 'Liste',
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, DeclarationList.routeName),
      ),
      _DashboardItem(
        icon: Icons.sync,
        title: 'Synchroniser',
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, SyncScreen.routeName),
      ),
      _DashboardItem(
        icon: Icons.settings,
        title: 'Paramètres',
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, SettingsScreen.routeName),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + index * 100),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            ),
            child: items[index],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1ABC9C), 
                  Color(0xFF3498DB),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF1ABC9C)),
                ),
                const SizedBox(height: 10),
                Text('Agent',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        )),
                Text('agent@example.com',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        )),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Tableau de bord',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.child_care,
            title: 'Déclarations',
            onTap: () => Navigator.pushNamed(context, DeclarationList.routeName),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.sync,
            title: 'Synchronisation',
            onTap: () => Navigator.pushNamed(context, SyncScreen.routeName),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: tr(context, 'settings'),
            onTap: () => Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help,
            title: 'Aide',
            onTap: () {},
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Déconnexion',
            onTap: () => Navigator.pushReplacementNamed(context, AuthScreen.routeName),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6C63FF)),
      title: Text(title),
      onTap: onTap,
      hoverColor: const Color(0xFF6C63FF).withOpacity(0.1),
    );
  }
}

class _DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}