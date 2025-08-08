import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/translate.dart';
import 'auth_screen.dart';
import '../providers/theme_locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  final String currentUserEmail;

  const SettingsScreen({super.key, required this.currentUserEmail});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Color _mainColor = const Color(0xFF4CAF9E);
  final Color _accentColor = const Color(0xFFFF9800);
  String _appVersion = '1.0.0';
  bool _isBiometricEnabled = false;
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'fr';
  ThemeMode _selectedTheme = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadSettings() async {
    // Load saved settings
    final biometric = await _storage.read(key: 'biometric_enabled');
    final notifications = await _storage.read(key: 'notifications_enabled');
    final language = await _storage.read(key: 'language');
    final theme = await _storage.read(key: 'theme_mode');
    
    setState(() {
      _isBiometricEnabled = biometric == 'true';
      _isNotificationsEnabled = notifications != 'false';
      _selectedLanguage = language ?? 'fr';
      _selectedTheme = theme == 'dark' ? ThemeMode.dark : 
                      theme == 'system' ? ThemeMode.system : ThemeMode.light;
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AuthScreen.routeName,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    await _saveSetting('language', languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    // In a real app, you would update the app's locale here
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Langue changée avec succès'),
          backgroundColor: Color(0xFF4CAF9E),
        ),
      );
    }
  }

  Future<void> _changeTheme(ThemeMode themeMode) async {
    final themeString = themeMode == ThemeMode.dark ? 'dark' : 
                      themeMode == ThemeMode.system ? 'system' : 'light';
    
    await _saveSetting('theme_mode', themeString);
    setState(() {
      _selectedTheme = themeMode;
    });
    
    // Update the app theme through the provider
    final provider = context.read<ThemeAndLocaleProvider>();
    provider.setThemeMode(themeMode);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thème changé avec succès'),
          backgroundColor: Color(0xFF4CAF9E),
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF9E),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: _mainColor),
        title: Text(title),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_mainColor, _mainColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36, color: Color(0xFF4CAF9E)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compte',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.currentUserEmail,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        centerTitle: true,
        backgroundColor: _mainColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            
            _buildSectionHeader('Préférences'),
            
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Langue',
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'mg', child: Text('Malagasy')),
                ],
                onChanged: (value) {
                  if (value != null) _changeLanguage(value);
                },
                underline: const SizedBox(),
              ),
            ),
            
            _buildSettingsTile(
              icon: Icons.brightness_6,
              title: 'Thème',
              trailing: DropdownButton<ThemeMode>(
                value: _selectedTheme,
                items: const [
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
                  DropdownMenuItem(value: ThemeMode.system, child: Text('Système')),
                ],
                onChanged: (value) {
                  if (value != null) _changeTheme(value);
                },
                underline: const SizedBox(),
              ),
            ),
            
            _buildSettingsTile(
              icon: Icons.fingerprint,
              title: 'Authentification biométrique',
              trailing: Switch(
                value: _isBiometricEnabled,
                activeColor: _mainColor,
                onChanged: (value) async {
                  await _saveSetting('biometric_enabled', value.toString());
                  setState(() => _isBiometricEnabled = value);
                },
              ),
            ),
            
            _buildSettingsTile(
              icon: Icons.notifications,
              title: 'Notifications',
              trailing: Switch(
                value: _isNotificationsEnabled,
                activeColor: _mainColor,
                onChanged: (value) async {
                  await _saveSetting('notifications_enabled', value.toString());
                  setState(() => _isNotificationsEnabled = value);
                },
              ),
            ),
            
            _buildSectionHeader('Sécurité'),
            
            _buildSettingsTile(
              icon: Icons.lock,
              title: 'Changer le mot de passe',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // In a real app, you would implement password change functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à implémenter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Sécurité du compte',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // In a real app, you would implement account security functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à implémenter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            
            _buildSectionHeader('À propos'),
            
            _buildSettingsTile(
              icon: Icons.info,
              title: 'Version de l\'application',
              trailing: Text('v$_appVersion'),
            ),
            
            _buildSettingsTile(
              icon: Icons.description,
              title: 'Conditions d\'utilisation',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // In a real app, you would show terms of service
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à implémenter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: 'Politique de confidentialité',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // In a real app, you would show privacy policy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à implémenter'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            
            _buildSectionHeader('Actions'),
            
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion'),
                textColor: Colors.red,
                onTap: _logout,
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}