import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animations/animations.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'declaration_list.dart';
import 'sync_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';
import '../db/database_helper.dart'; 

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  String? _userName;
  String? _userEmail;
  String? _profilePicture;

  final List<String> imgList = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
  ];

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_updatePage);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    _userEmail = await _storage.read(key: 'user_email');
    final dbHelper = DatabaseHelper.instance;
    final user = await dbHelper.getUserByEmail(_userEmail!);

    setState(() {
      _userName = user?['name'] ?? "User Name";
      _userEmail = _userEmail ?? "user@example.com";
      _profilePicture = user?['profilePicture'] ?? "https://example.com/path/to/profile/picture.jpg";
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profilePicture = pickedFile.path;
      });

      // Mettre à jour le chemin de l'image de profil dans la base de données
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateUserProfilePicture(_userEmail!, pickedFile.path);
    }
  }

  void _updatePage() {
    final page = _pageController.page ?? 0.0;
    if (mounted) {
      setState(() => _currentPage = page.round());
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_updatePage);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        backgroundColor: const Color(0xFF4CAF9E),
        actions: [
          IconButton(
            icon: const badges.Badge(
              child: Icon(Icons.notifications),
            ),
            onPressed: _showNotifications,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/5.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildImageCarousel(),
                      const SizedBox(height: 16),
                      _buildPageIndicator(context),
                      const SizedBox(height: 24),
                      _buildDashboardGrid(context, theme),
                    ],
                  ),
                ),
              ),
              _buildFooter(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF9E).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '© 2025 - by homme serpent',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: imgList.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return _buildCarouselItem(context, index);
        },
      ),
    );
  }

  Widget _buildCarouselItem(BuildContext context, int index) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 700),
      openBuilder: (context, _) => _buildFullScreenImage(index),
      closedBuilder: (context, openContainer) =>
          _buildCarouselThumbnail(index, openContainer),
      transitionType: ContainerTransitionType.fadeThrough,
      closedColor: Colors.transparent,
      middleColor: Colors.transparent,
      openColor: Colors.transparent,
    );
  }

  Widget _buildFullScreenImage(int index) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: 'carousel-$index',
          child: Image.asset(
            imgList[index],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildImageError(),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselThumbnail(int index, VoidCallback openContainer) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
        }
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: openContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Hero(
                tag: 'carousel-$index',
                child: Image.asset(
                  imgList[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImageError(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 0.8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(imgList.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? const Color(0xFF4CAF9E)
                  : Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                if (_currentPage == index)
                  BoxShadow(
                    color: const Color(0xFF4CAF9E).withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDashboardGrid(BuildContext context, ThemeData theme) {
    final items = [
      _DashboardItem(
        icon: Icons.child_care,
        title: 'Déclarer',
        color: const Color(0xFF4CAF9E),
        onTap: () => _navigateWithAnimation(context, '/form'),
      ),
      _DashboardItem(
        icon: Icons.list_alt,
        title: 'Liste',
        color: Colors.blue,
        onTap: () =>
            _navigateWithAnimation(context, DeclarationList.routeName),
      ),
      _DashboardItem(
        icon: Icons.sync,
        title: 'Synchroniser',
        color: const Color(0xFF4CAF9E),
        onTap: () => _navigateWithAnimation(context, SyncScreen.routeName),
      ),
      _DashboardItem(
        icon: Icons.settings,
        title: 'Paramètres',
        color: Colors.blue,
        onTap: () =>
            _navigateWithAnimation(context, SettingsScreen.routeName),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimationLimiter(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 600),
              columnCount: 2,
              child: ScaleAnimation(
                curve: Curves.fastOutSlowIn,
                duration: const Duration(milliseconds: 900),
                child: FadeInAnimation(
                  child: items[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.error, color: Colors.red, size: 50),
      ),
    );
  }

  void _showNotifications() {
    // Implement notification logic here
  }

  void _navigateWithAnimation(BuildContext context, String routeName) {
    final route = _getRouteFromName(routeName);
    if (route != null) {
      Navigator.push(context, _createRoute(route));
    }
  }

  Widget? _getRouteFromName(String routeName) {
    switch (routeName) {
      case DeclarationList.routeName:
        return const DeclarationList();
      case SyncScreen.routeName:
        return const SyncScreen();
      case SettingsScreen.routeName:
        return const SettingsScreen();
      case '/form':
      default:
        return null;
    }
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 800),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.fastOutSlowIn;

        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerHeader(context),
            ..._buildDrawerItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF9E),
            const Color(0xFF4CAF9E).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 30,
              backgroundImage: _profilePicture != null
                  ? (_profilePicture!.startsWith('http')
                      ? NetworkImage(_profilePicture!)
                      : FileImage(File(_profilePicture!)))
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
              child: _profilePicture == null
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white.withOpacity(0.9),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName ?? 'Agent',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            _userEmail ?? 'agent@example.com',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context) {
    return [
      _buildDrawerItem(
        context,
        icon: Icons.dashboard,
        title: 'Tableau de bord',
        onTap: () => _navigateWithAnimation(context, DashboardScreen.routeName),
      ),
      _buildDrawerItem(
        context,
        icon: Icons.child_care,
        title: 'Déclarations',
        onTap: () =>
            _navigateWithAnimation(context, DeclarationList.routeName),
      ),
      _buildDrawerItem(
        context,
        icon: Icons.sync,
        title: 'Synchronisation',
        onTap: () => _navigateWithAnimation(context, SyncScreen.routeName),
      ),
      _buildDrawerItem(
        context,
        icon: Icons.settings,
        title: 'Paramètres',
        onTap: () =>
            _navigateWithAnimation(context, SettingsScreen.routeName),
      ),
      const Divider(),
      _buildDrawerItem(
        context,
        icon: Icons.logout,
        title: 'Déconnexion',
        onTap: () => Navigator.pushReplacementNamed(context, AuthScreen.routeName),
      ),
    ];
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF9E)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      hoverColor: const Color(0xFF4CAF9E).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      hoverColor: color.withOpacity(0.1),
      splashColor: color.withOpacity(0.2),
      highlightColor: color.withOpacity(0.05),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: color.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
