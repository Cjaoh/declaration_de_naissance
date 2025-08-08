import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'utils/translate.dart';
import 'providers/theme_locale_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/declaration_form.dart';
import 'screens/declaration_list.dart';
import 'screens/sync_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeAndLocaleProvider()),
        Provider(create: (_) => const FlutterSecureStorage()),
      ],
      child: const MyApp(),
    ),
  );
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
          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return supportedLocales.first;
      },
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        AuthScreen.routeName: (_) => const AuthScreen(),
        DashboardScreen.routeName: (_) => const DashboardScreen(),
        DeclarationForm.routeName: (_) => const DeclarationForm(),
        DeclarationList.routeName: (_) => const DeclarationList(),
        SyncScreen.routeName: (_) => const SyncScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        SettingsScreen.routeName: (_) => FutureBuilder<String?>(
          future: storage.read(key: 'user_email'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data != null) {
              return SettingsScreen(currentUserEmail: snapshot.data!);
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      },
    );
  }
}
