import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'sign_up_page.dart';
import '../evaluation/evaluation_text.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isPhone = size.width < 480;
    final cardPadding = EdgeInsets.all(isPhone ? 24 : 36);
    final emblemSize = isPhone ? 64.0 : 88.0;
    final emblemIcon = isPhone ? 32.0 : 44.0;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8EDFF), Color(0xFFD8DFFF)],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _LanguageToggle(), // compact renders on phones
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // brighter card background
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        child: Padding(
                          padding: cardPadding,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 6),
                              // top emblem: solid hard blue circle with white graduation icon
                              // Emblem: thicker solid blue circle with white hat centered
                              // Emblem: deep blue circle with white hat — unify with SignUp page
                              Container(
                                width: emblemSize,
                                height: emblemSize,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E63FF),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.school,
                                    size: emblemIcon, color: Colors.white),
                              ),

                              const SizedBox(height: 24),
                              Text(
                                'app_name'.tr(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ai_subtitle'.tr(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: isPhone ? 12 : 13,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 28),

                              // Tabs — design aims to match the mock's pill tabs
                              Container(
                                width: double.infinity,
                                height: isPhone ? 48 : 52,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 8))
                                  ],
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.06)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 8),
                                            )
                                          ],
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.15),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          'sign_in'.tr(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const SignUpPage())),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Text(
                                            'sign_up'.tr(),
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              _AuthForm(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final isPhone = MediaQuery.of(context).size.width < 480;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isPhone ? 8 : 12, vertical: isPhone ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language, size: isPhone ? 16 : 20, color: Colors.grey),
          SizedBox(width: isPhone ? 8 : 12),
          GestureDetector(
            onTap: () => context.setLocale(const Locale('si')),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 12, vertical: isPhone ? 6 : 8),
              decoration: BoxDecoration(
                color: locale.languageCode == 'si'
                    ? Colors.blue[600]
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'si_name'.tr(),
                style: TextStyle(
                  fontSize: isPhone ? 12 : 14,
                  color: locale.languageCode == 'si'
                      ? Colors.white
                      : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: isPhone ? 8 : 10),
          GestureDetector(
            onTap: () => context.setLocale(const Locale('en')),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 14, vertical: isPhone ? 6 : 8),
              decoration: BoxDecoration(
                color: locale.languageCode == 'en'
                    ? Colors.blue[600]
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'en_name'.tr(),
                style: TextStyle(
                  fontSize: isPhone ? 12 : 14,
                  color: locale.languageCode == 'en'
                      ? Colors.white
                      : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Email label above input (placeholder inside) per design
        Align(
          alignment: Alignment.centerLeft,
          child: Text('email'.tr(),
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey[800])),
        ),
        const SizedBox(height: 6),
        // boxed input with soft lift + light blue border
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F9FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E4F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'email_hint'.tr(),
              hintStyle: const TextStyle(color: Color(0xFFA9B0C3)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Password label above input
        Align(
          alignment: Alignment.centerLeft,
          child: Text('password'.tr(),
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey[800])),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E4F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: TextFormField(
            controller: _pwdCtrl,
            obscureText: true, // keep hidden; no visibility toggle per design
            decoration: InputDecoration(
              hintText: 'password_hint'.tr(),
              hintStyle: const TextStyle(color: Color(0xFFA9B0C3)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF1E7EFF),
            ),
            onPressed: () {
              // Navigate to EvaluationTextPage
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const EvaluationTextPage()),
              );
            },
            child: Text(
              'sign_in'.tr(),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
