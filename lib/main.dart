import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'layouts/mobile/sign_in_page.dart';
import '../features/recent_chat/recent_chats_page.dart';
import '../features/syllabus/syllabus_page.dart';

import 'widgets/students_main_app_bar.dart'; // <-- ADD THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('si'),
      ],
      path: 'assets/languages',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode =
          themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubric System',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1E63FF),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1E63FF),
      ),
      home: const SignInPage(),
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: HomePage(
        themeMode: themeMode,
        toggleTheme: toggleTheme,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RecentChatsDrawer(), // <-- ADD THIS LINE
      appBar: MainAppBar(
        selectedIndex: selectedSegment,
        onMenuPressed: () {
          Scaffold.of(context).openDrawer(); // <-- OPEN SIDEBAR HERE
        },
        onSegmentSelected: (index) {
          setState(() => selectedSegment = index);
        },
        onRightIconPressed: () {
    showSyllabusSidebar(context); // <-- this context is from HomePage, safe!
  },
        onAddPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add button pressed")),
          );
        },
      ),

      body: const Center(
        child: Text('Welcome to the Rubric System'),
      ),
    );
  }
}

// placeholder home kept for reference (not currently used)
}
