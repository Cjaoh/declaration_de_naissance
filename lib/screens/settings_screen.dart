import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Pour accéder à ThemeAndLocaleProvider
import '../utils/translate.dart';

class SettingsScreen extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocaleProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr(context, 'preferences'), style: const TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: Text(tr(context, 'dark_mode')),
            value: provider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              provider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            title: Text(tr(context, 'language')),
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
          Text(tr(context, 'account'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ListTile(
            title: Text(tr(context, 'change_password')),
            leading: const Icon(Icons.lock),
            onTap: () {},
          ),
          ListTile(
            title: Text(tr(context, 'logout')),
            leading: const Icon(Icons.logout, color: Colors.red),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              Navigator.pushReplacementNamed(context, '/auth');
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