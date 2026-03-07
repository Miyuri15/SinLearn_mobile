import 'package:flutter/material.dart';
import 'package:sinlearn_mobile/core/network/token_storage.dart';
import 'package:sinlearn_mobile/features/auth/auth_page.dart';
import 'package:sinlearn_mobile/features/learning/learning_mode.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isLoggedIn() async {
    return await TokenStorage.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        // Still checking token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in → Home
        if (snapshot.data == true) {
          return const LearningModePage();
        }

        // Not logged in → Auth
        return const AuthPage();
      },
    );
  }
}
