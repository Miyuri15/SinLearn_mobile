
// main.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; //  Provider

// 💡 folder path
import 'features/settings/Settings_Teachers.dart';

// ---------------------------
//  1. THEME SETTINGS (CHANGE NOTIFIER)
// ---------------------------
// manage theme color
class ThemeSettings extends ChangeNotifier {
  // Dark Mode  Default status
  bool _isDark = false;

  bool get isDark => _isDark;

  // toggle
  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }

  // still theme
  ThemeData get currentTheme =>
      _isDark
          ? ThemeData(brightness: Brightness.dark, useMaterial3: true)
          : ThemeData(brightness: Brightness.light, useMaterial3: true);
}


// ---------------------------
// MAIN FUNCTION (ENTRY POINT)
// ---------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 💡 support provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeSettings(), // ThemeSettings instance
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('si'), // sinhala
        ],
        path: 'assets/languages',
        fallbackLocale: const Locale('en'),
        child: SinLearnApp(),
      ),
    ),
  );
}

class SinLearnApp extends StatelessWidget {
  SinLearnApp({super.key});

  // ---------------------------
  // ROUTER SETUP (GoRouter)
  // ---------------------------
  final GoRouter _router = GoRouter(
    routes: [
      // 1. Home Page / Main Page
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaceholderHome(),
      ),
      // 2. Settings Page
      GoRoute(
        path: '/settings_teachers',
        builder: (context, state) => const SettingTeachers(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // 💡 Provider
    final themeSettings = context.watch<ThemeSettings>();

    return MaterialApp.router(
      title: "SinLearn",
      debugShowCheckedModeBanner: false,

      // Localization setup
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Themes (Light/Dark mode )
      theme: themeSettings.currentTheme,
      darkTheme: themeSettings.currentTheme,
      themeMode: themeSettings.isDark ? ThemeMode.dark : ThemeMode.light,

      // Router connect
      routerConfig: _router,
    );
  }
}

// ---------------------------
// PLACEHOLDER HOME PAGE
// ---------------------------
class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 context.watch
    final isDark = context.watch<ThemeSettings>().isDark;

    return Scaffold(
      appBar: AppBar(
          title: const Text("SinLearn Home").tr(),
          backgroundColor: isDark
              ? const Color(0xFF1E1F20)
              : Colors.blue
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("This is the Main Page.").tr(),
            Text("Current Theme: ${isDark ? 'Dark' : 'Light'}"), // show theme
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/settings_teachers');
              },
              // 💡 Localization key
              child: const Text("go_to_settings_teachers").tr(),
            ),
          ],
        ),
      ),
    );
  }
}





//*************************************************************
/*
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [
        Locale('en'),
        Locale('si'),
      ],
      path: 'assets/languages',
      fallbackLocale: Locale('en'),
      child: const SinLearnApp(),
    ),
  );
}

class SinLearnApp extends StatelessWidget {
  const SinLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SinLearn",
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const PlaceholderHome(),
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SinLearn Home")),
      body: Center(child: Text("Project Structure Ready")),
      // org.gradle.java.home=C:/Program Files/Java/jdk-17
    );
  }
}
*/