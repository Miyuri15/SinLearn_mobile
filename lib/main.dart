import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// correct folder path
import 'features/settings/Settings_Teachers.dart';
import 'features/recent_chat/recent_chats_page.dart';

import 'features/evaluation/evaluation_voice.dart';
import 'features/evaluation/evaluation_text.dart';
import 'features/evaluation/evaluation_response.dart';
// import 'features/learning_mode/learning_mode_page.dart';
import 'features/question_paper/question_paper_page.dart';


// ---------------------------
//  1. THEME SETTINGS (CHANGE NOTIFIER)
// ---------------------------
// theme managment
class ThemeSettings extends ChangeNotifier {
  // Dark Mode
  bool _isDark = false;

  bool get isDark => _isDark;

  //  (Toggle) process
  void toggleTheme(bool value) {
    _isDark = value;
    notifyListeners();
  }


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
  //  const
  SinLearnApp({super.key});

  // ---------------------------
  // ROUTER SETUP (GoRouter)
  // ---------------------------
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PlaceholderHome(), // const
      ),
      GoRoute(
        path: '/settings_teachers',
        builder: (context, state) {
          //  Provider
          final themeSettings = context.watch<ThemeSettings>();

          return SettingTeachers(
            isDark: themeSettings.isDark,
            toggleTheme: themeSettings.toggleTheme,
          );
        },
      ),

      GoRoute(
        path: '/recent_chats_page',
        builder: (context, state) => const RecentChatsDrawer(),

        //builder: (context, state) => const RecentChatsPage(), // const විය හැක

      ),

      //  new Routes
      GoRoute(
        path: '/evaluation_voice',
        builder: (context, state) => const EvaluationVoicePage(),
      ),
      GoRoute(
        path: '/evaluation_text',
        builder: (context, state) => const EvaluationTextPage(),
      ),
      GoRoute(
        path: '/evaluation_response',
        builder: (context, state) => const EvaluationResponsePage(),
      ),

      GoRoute(
        path: '/question_paper',
        builder: (context, state) => const QuestionPaperPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    //  Provider
    final themeSettings = context.watch<ThemeSettings>();
    final isDark = themeSettings.isDark;

    return MaterialApp.router(
      title: "SinLearn",
      debugShowCheckedModeBanner: false,

      // Localization setup
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Themes
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
    // context.watch
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("This is the Main Page.", style: TextStyle(color: textColor, fontSize: 18)).tr(),
              Text("Current Theme: ${isDark ? 'Dark' : 'Light'}", style: TextStyle(color: textColor)),
              const SizedBox(height: 30),

              // Settings & Recent Chats
              ElevatedButton(
                onPressed: () => context.go('/settings_teachers'),
                child: const Text("settings.header").tr(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.go('/recent_chats_page'),
                child: const Text("recent_chats.header").tr(),
              ),

              const SizedBox(height: 30),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text("Evaluation Modes:", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(),


              //   Navigation Buttons
              const SizedBox(height: 10),
              //  Learning Mode Button

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.go('/evaluation_voice'),
                child: const Text("Go to Evaluation (Voice)"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.go('/evaluation_text'),
                child: const Text("Go to Evaluation (Text)"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.go('/evaluation_response'),
                child: const Text("Go to Evaluation (Response)"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.go('/question_paper'),
                child: const Text("Go to Question Paper"),
              ),
            ],
          ),
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