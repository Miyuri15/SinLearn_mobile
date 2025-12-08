

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // provider

// 💡folder path
import 'features/settings/Settings_Teachers.dart';
import 'features/recent_chat/recent_chats_page.dart';

// ---------------------------
//  THEME SETTINGS (CHANGE NOTIFIER)
// ---------------------------

class ThemeSettings extends ChangeNotifier {
  // Dark Mode  Default
  bool _isDark = false;

  bool get isDark => _isDark;

  // toggle procss
  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }

  // theme
  ThemeData get currentTheme =>
      _isDark
          ? ThemeData(brightness: Brightness.dark, useMaterial3: true)
          : ThemeData(brightness: Brightness.light, useMaterial3: true);
}


// ---------------------------
//  MAIN FUNCTION (ENTRY POINT)
// ---------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  //  Provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeSettings(), // ThemeSettings instance
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('si'), // සිංහල
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
  // _router  GoRouter constructor
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaceholderHome(), // const
      ),
      GoRoute(
        path: '/settings_teachers',
        builder: (context, state) {
          // ⭐️ Provider value
          final themeSettings = context.watch<ThemeSettings>();


          return SettingTeachers(
            isDark: themeSettings.isDark,
            toggleTheme: themeSettings.toggleTheme,
          );
        },
      ),

      GoRoute(
        path: '/recent_chats_page',
        //  RecentChatsPag
        builder: (context, state) => const RecentChatsDrawer(), // const
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    //  Provider  ThemeSettings  (watch)
    final themeSettings = context.watch<ThemeSettings>();
    final isDark = themeSettings.isDark;

    return MaterialApp.router(
      title: "SinLearn",
      debugShowCheckedModeBanner: false,

      // Localization setup
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Themes (Light/Dark mode )
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2563EB), // Primary Blue
          onBackground: Color(0xFF111827), // Primary Text
          secondary: Color(0xFF6B7280), // Secondary Text (SubText)
          surface: Colors.white, // Default Input/Surface Background
          background: Color(0xFFF3F4F6),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF000000),
        cardColor: const Color(0xFF1E1F20),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB), // Primary Blue
          onBackground: Color(0xFFF9FAFB), // Primary Text
          secondary: Color(0xFF9CA3AF), // Secondary Text (SubText)
          surface: Color(0xFF2A2B32), // Input Background
          background: Color(0xFF000000),
        ),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

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
    // 💡 context.watch මඟින් තේමා වෙනස්වීම් වලට සවන් දෙයි
    final isDark = context.watch<ThemeSettings>().isDark;
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(
        title: Text("SinLearn Home", style: TextStyle(color: textColor)).tr(),
        backgroundColor: theme.cardColor,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("This is the Main Page.", style: TextStyle(color: textColor)).tr(),
            Text("Current Theme: ${isDark ? 'Dark' : 'Light'}", style: TextStyle(color: textColor)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/settings_teachers');
              },
              child: const Text("settings.header").tr(), // Localization key
            ),
            const SizedBox(height: 10),
            //  Recent Chats Button
            ElevatedButton(
              onPressed: () {
                context.go('/recent_chats_page'); //  Route
              },
              child: const Text("recent_chats.header").tr(),
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