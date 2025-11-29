
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

// Your settings page import (IMPORTANT)
import 'features/settings/Settings_Teachers.dart';

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
      child: SinLearnApp(),
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
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaceholderHome(),
      ),
      GoRoute(
        path: '/settings_teachers',
        builder: (context, state) => const SettingTeachers(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "SinLearn",
      debugShowCheckedModeBanner: false,

      // Localization setup
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Themes
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),

      // Router connect
      routerConfig: _router,
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SinLearn Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Go to Settings Teachers Page
            context.go('/settings_teachers');
          },
          child: Text("Go to Settings (Teachers)"),
        ),
      ),
    );
  }
}




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