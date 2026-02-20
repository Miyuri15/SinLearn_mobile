import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sinlearn_mobile/features/auth/auth_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SignInPage builds and shows sign in label', (tester) async {
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('si')],
        path: 'assets/languages',
        fallbackLocale: const Locale('en'),
        child: const MaterialApp(home: AuthPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
  });
}
