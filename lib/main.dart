import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinlearn_mobile/core/auth/auth_gate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'utils/timeago_si.dart';
import 'package:sinlearn_mobile/core/network/api_client.dart';
import 'package:sinlearn_mobile/features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  timeago.setLocaleMessages('si', SiMessages());

  // Load the saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;

  ApiClient.onRefresh = () => AuthService().refreshToken();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('si')],
      path: 'assets/languages',
      fallbackLocale: const Locale('en'),
      child: MyApp(
        key: MyApp.stateKey, // use global key to access state
        isDark: isDark,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isDark;
  // Provide a global key for accessing state from anywhere (e.g., Settings)
  static final GlobalKey<_MyAppState> stateKey = GlobalKey<_MyAppState>();
  static _MyAppState of(BuildContext context) => stateKey.currentState!;

  const MyApp({super.key, required this.isDark});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isDark;

  @override
  void initState() {
    super.initState();
    isDark = widget.isDark;
  }

  Future<void> toggleTheme(bool value) async {
    setState(() {
      isDark = value;
    });
    // persist the preference so it survives app restarts
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SinLearn Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E63FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const AuthGate(),
    );
  }
}
