import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'edit_profile_screen.dart';
import '../db/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  final String currentUserEmail;

  const SettingsScreen({Key? key, required this.currentUserEmail}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final Color mainColor = const Color(0xFF4CAF9E);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocaleProvider>(context);
    final gradientColors = [
      mainColor,
      mainColor.withOpacity(0.85),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Paramètres',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
                stops: const [0.2, 0.9],
              ),
            ),
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildAnimatedHeader(),
                          const SizedBox(height: 30),
                          _buildSectionCard(
                            title: 'Préférences',
                            children: [
                              _buildAnimatedSettingItem(index: 0, child: _buildDarkModeTile(provider)),
                              _buildAnimatedSettingItem(index: 1, child: _buildLanguageTile(provider)),
                            ],
                          ),
                          const SizedBox(height: 25),
                          _buildSectionCard(
                            title: 'Compte',
                            children: [
                              _buildAnimatedSettingItem(index: 2, child: _buildChangePasswordTile(context)),
                              _buildAnimatedSettingItem(index: 4, child: _buildEditProfileTile(context)),
                              _buildAnimatedSettingItem(index: 3, child: _buildLogoutTile(context)),
                            ],
                          ),
                          const SizedBox(height: 40),
                          _buildAnimatedSettingItem(
                            index: 5,
                            child: const Center(
                              child: Text(
                                '',
                                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Icon(
            Icons.settings,
            key: ValueKey<int>(_controller.value.round()),
            size: 70,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Configuration',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 12),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSettingItem({required int index, required Widget child}) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3 + (0.1 * index), 1.0, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildDarkModeTile(ThemeAndLocaleProvider provider) {
    return _buildSwitchTile(
      title: 'Mode sombre',
      value: provider.themeMode == ThemeMode.dark,
      onChanged: (value) => provider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
    );
  }

  Widget _buildLanguageTile(ThemeAndLocaleProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        title: const Text('Langue', style: TextStyle(color: Colors.white)),
        trailing: DropdownButton<Locale>(
          dropdownColor: Colors.teal[800],
          value: provider.locale,
          underline: const SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: mainColor),
          items: const [
            DropdownMenuItem(value: Locale('fr'), child: Text('Français', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: Locale('mg'), child: Text('Malagasy', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: Locale('en'), child: Text('Anglais', style: TextStyle(color: Colors.white))),
          ],
          onChanged: (locale) {
            if (locale != null) provider.setLocale(locale);
          },
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required bool value, required Function(bool) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.1),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        activeColor: mainColor,
        activeTrackColor: mainColor.withOpacity(0.4),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildChangePasswordTile(BuildContext context) {
    return _buildInteractiveTile(
      icon: Icons.lock,
      title: 'Changer le mot de passe',
      color: mainColor,
      onTap: () => _navigateToEditProfile(context),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return _buildInteractiveTile(
      icon: Icons.logout,
      title: 'Déconnexion',
      color: Colors.redAccent,
      onTap: () => Navigator.pushReplacementNamed(context, '/auth'),
    );
  }

  Widget _buildEditProfileTile(BuildContext context) {
    return _buildInteractiveTile(
      icon: Icons.person,
      title: 'Modifier le profil',
      color: mainColor.withOpacity(0.8),
      onTap: () => _navigateToEditProfile(context),
    );
  }

  Future<void> _navigateToEditProfile(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final user = await db.getUserByEmail(widget.currentUserEmail);
    if (user != null && context.mounted) {
      final updated = await Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => EditProfileScreen(user: user),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
        ),
      );

      if (updated == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: mainColor,
            content: const Text('Profil mis à jour'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildInteractiveTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: title == 'Déconnexion' ? Colors.red[100] : Colors.white,
            fontWeight: title == 'Déconnexion' ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.7), size: 16),
        onTap: onTap,
      ),
    );
  }
}
