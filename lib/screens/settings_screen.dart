import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'edit_profile_screen.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';
  final String currentUserEmail;

  const SettingsScreen({super.key, required this.currentUserEmail});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Préférences', style: TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Mode sombre'),
            value: provider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              provider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            title: const Text('Langue'),
            trailing: DropdownButton<Locale>(
              value: provider.locale,
              items: const [
                DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                DropdownMenuItem(value: Locale('mg'), child: Text('Malagasy')),
                DropdownMenuItem(value: Locale('en'), child: Text('Anglais')),
              ],
              onChanged: (locale) {
                if (locale != null) {
                  provider.setLocale(locale);
                }
              },
            ),
          ),
          const Divider(),
          const Text('Compte', style: TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Changer le mot de passe'),
            leading: const Icon(Icons.lock),
            onTap: () async {
              final db = DatabaseHelper.instance;
              final user = await db.getUserByEmail(currentUserEmail);
              if (user != null && context.mounted) {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: user),
                  ),
                );
                if (updated == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mot de passe mis à jour')),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
          ListTile(
            title: const Text('Modifier le profil'),
            leading: const Icon(Icons.person),
            onTap: () async {
              final db = DatabaseHelper.instance;
              final user = await db.getUserByEmail(currentUserEmail);
              if (user != null && context.mounted) {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: user),
                  ),
                );
                if (updated == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil mis à jour')),
                  );
                }
              }
            },
          ),
          const Divider(),
          const Center(
            child: Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
