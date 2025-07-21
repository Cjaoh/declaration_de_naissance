import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 


import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/declaration_form.dart';
import 'screens/declaration_list.dart';
import 'screens/sync_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/register_screen.dart';


import 'utils/translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeAndLocaleProvider()),
        Provider(create: (context) => const FlutterSecureStorage()),
      ],
      child: const MyApp(),
    ),
  );
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeAndLocaleProvider>();
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);

    return MaterialApp(
      title: 'Déclaration Naissance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: provider.themeMode,
      locale: provider.locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('mg'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MalagasyLocalizations.materialDelegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return supportedLocales.first;
      },
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        AuthScreen.routeName: (context) => const AuthScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        DeclarationForm.routeName: (context) => const DeclarationForm(),
        DeclarationList.routeName: (context) => const DeclarationList(),
        SyncScreen.routeName: (context) => const SyncScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        SettingsScreen.routeName: (context) => FutureBuilder<String?>(
          future: storage.read(key: 'user_email'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data != null) {
              return SettingsScreen(currentUserEmail: snapshot.data!);
            }
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        ),
      },
    );
  }
}
