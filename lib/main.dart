import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/declaration_form.dart';
import 'screens/declaration_list.dart';
import 'screens/sync_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeAndLocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocaleProvider>(context);
    return MaterialApp(
      title: 'Déclaration Naissance',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: provider.themeMode,
      locale: provider.locale,
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // Anglais
        Locale('mg'), // Malgache
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        AuthScreen.routeName: (context) => const AuthScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        DeclarationForm.routeName: (context) => const DeclarationForm(),
        DeclarationList.routeName: (context) => const DeclarationList(),
        SyncScreen.routeName: (context) => const SyncScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
      },
    );
  }
}

class ThemeAndLocaleProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
