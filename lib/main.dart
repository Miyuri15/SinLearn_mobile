import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'layouts/mobile/sign_in_page.dart';

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
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1E63FF),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1E63FF),
      ),
      home: const SignInPage(),
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
    );
  }
}

// placeholder home kept for reference (not currently used)
