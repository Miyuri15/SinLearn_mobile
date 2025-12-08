import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sinlearn_mobile/features/auth/sign_in_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SignInPage builds and shows sign in label', (tester) async {
    await EasyLocalization.ensureInitialized();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: [Locale('en'), Locale('si')],
        path: 'assets/languages',
        fallbackLocale: Locale('en'),
        child: MaterialApp(home: const SignInPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
  });
}
