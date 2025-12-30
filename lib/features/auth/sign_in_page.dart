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
    final isSmallPhone = size.width < 380;
    final isPhone = size.width < 600;
    final isDark = theme.brightness == Brightness.dark;

    // Keep blue accents intact; adapt surfaces/inputs/gradients for dark mode
    final bgColors = isDark
        ? [const Color(0xFF0B1220), const Color(0xFF0D1320)]
        : [const Color(0xFFE8EDFF), const Color(0xFFD8DFFF)];

    final cardPadding = EdgeInsets.symmetric(
      horizontal: isSmallPhone
          ? 20
          : isPhone
              ? 24
              : 36,
      vertical: isSmallPhone
          ? 20
          : isPhone
              ? 28
              : 36,
    );

    final surfaceFill = isDark ? theme.cardColor : Colors.white;
    final inputFill =
        isDark ? const Color(0xFF141414) : const Color(0xFFF6F9FF);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE0E4F0);
    final labelColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final hintColor = isDark ? Colors.grey[500] : const Color(0xFFA9B0C3);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: bgColors,
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Language Toggle - Positioned for mobile
                Positioned(
                  top: isSmallPhone ? 12 : 16,
                  right: isSmallPhone ? 12 : 20,
                  child:
                      _LanguageToggle(), // updated to use theme inside toggle
                ),
                // Main Content
                Padding(
                  padding: EdgeInsets.only(
                    top: isSmallPhone ? 50 : 60,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 480,
                            minHeight: size.height -
                                (isSmallPhone ? 100 : 120) -
                                MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: isSmallPhone
                                  ? 12
                                  : isPhone
                                      ? 16
                                      : 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceFill,
                              borderRadius: BorderRadius.circular(
                                isSmallPhone ? 24 : 28,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: cardPadding,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isSmallPhone) const SizedBox(height: 6),
                                  // Logo/Emblem
                                  Container(
                                    width: 56.0,
                                    height: 56.0,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E63FF),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.school,
                                      size: 28.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 16 : 24),
                                  // App Name
                                  Text(
                                    'app_name'.tr(),
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      fontSize: isSmallPhone ? 22 : null,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 4 : 6),
                                  // Subtitle
                                  Text(
                                    'ai_subtitle'.tr(),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                      fontSize: isSmallPhone
                                          ? 11
                                          : isPhone
                                              ? 12
                                              : 13,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 20 : 28),

                                  // Tabs
                                  Container(
                                    height: isSmallPhone
                                        ? 44
                                        : isPhone
                                            ? 48
                                            : 52,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: surfaceFill,
                                      borderRadius: BorderRadius.circular(
                                        isSmallPhone ? 16 : 20,
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.06),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 12,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: surfaceFill,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      isSmallPhone ? 14 : 18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 8),
                                                )
                                              ],
                                              border: Border.all(
                                                color: Colors.blue
                                                    .withOpacity(0.15),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Text(
                                              'sign_in'.tr(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize:
                                                    isSmallPhone ? 13 : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isSmallPhone ? 6 : 8),
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                                isSmallPhone ? 14 : 18),
                                            onTap: () =>
                                                Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const SignUpPage(),
                                              ),
                                            ),
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                'sign_up'.tr(),
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      isSmallPhone ? 13 : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(height: isSmallPhone ? 18 : 22),

                                  const _AuthForm(),
                                ],
                              ),
                            ),
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
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final isPhone = size.width < 600;

    // ADDED: theme-aware colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.cardColor : Colors.white;
    final iconColor = isDark ? Colors.grey[300] : Colors.grey;
    final textUnselected = isDark ? Colors.grey[300] : Colors.grey[700];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallPhone
            ? 6
            : isPhone
                ? 8
                : 12,
        vertical: isSmallPhone
            ? 4
            : isPhone
                ? 6
                : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language,
            size: isSmallPhone
                ? 14
                : isPhone
                    ? 16
                    : 20,
            color: iconColor,
          ),
          SizedBox(
              width: isSmallPhone
                  ? 6
                  : isPhone
                      ? 8
                      : 12),
          // Sinhala
          GestureDetector(
            onTap: () => context.setLocale(const Locale('si')),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone
                    ? 8
                    : isPhone
                        ? 10
                        : 12,
                vertical: isSmallPhone
                    ? 4
                    : isPhone
                        ? 6
                        : 8,
              ),
              decoration: BoxDecoration(
                color: locale.languageCode == 'si'
                    ? Colors.blue[600]
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'si_name'.tr(),
                style: TextStyle(
                  fontSize: isSmallPhone
                      ? 11
                      : isPhone
                          ? 12
                          : 14,
                  color: locale.languageCode == 'si'
                      ? Colors.white
                      : textUnselected,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(
              width: isSmallPhone
                  ? 6
                  : isPhone
                      ? 8
                      : 10),
          // English
          GestureDetector(
            onTap: () => context.setLocale(const Locale('en')),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone
                    ? 8
                    : isPhone
                        ? 12
                        : 14,
                vertical: isSmallPhone
                    ? 4
                    : isPhone
                        ? 6
                        : 8,
              ),
              decoration: BoxDecoration(
                color: locale.languageCode == 'en'
                    ? Colors.blue[600]
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'en_name'.tr(),
                style: TextStyle(
                  fontSize: isSmallPhone
                      ? 11
                      : isPhone
                          ? 12
                          : 14,
                  color: locale.languageCode == 'en'
                      ? Colors.white
                      : textUnselected,
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
  const _AuthForm({Key? key}) : super(key: key);

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  // Focus nodes for keyboard navigation
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final isPhone = size.width < 600;

    // --- ADDED: compute theme-dependent colors locally so they are in scope ---
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill =
        isDark ? const Color(0xFF141414) : const Color(0xFFF6F9FF);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE0E4F0);
    final labelColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final hintColor = isDark ? Colors.grey[500] : const Color(0xFFA9B0C3);
    // -----------------------------------------------------------------------

    return Column(
      children: [
        // Email label
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'email'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: isSmallPhone ? 13 : null,
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 4 : 6),
        // Email input
        Container(
          decoration: BoxDecoration(
            color: inputFill,
            borderRadius: BorderRadius.circular(isSmallPhone ? 14 : 18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _passwordFocus.requestFocus(),
            decoration: InputDecoration(
              hintText: 'email_hint'.tr(),
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: isSmallPhone ? 13 : null,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 12 : 14,
                vertical: isSmallPhone ? 12 : 14,
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 10 : 12),
        // Password label
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'password'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: labelColor,
              fontSize: isSmallPhone ? 13 : null,
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 4 : 6),
        // Password input (use theme-aware inputFill instead of hard-coded white)
        Container(
          decoration: BoxDecoration(
            color: inputFill, // changed from Colors.white
            borderRadius: BorderRadius.circular(isSmallPhone ? 14 : 18),
            border: Border.all(color: borderColor), // use theme-aware border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _pwdCtrl,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              // Handle sign in
              _passwordFocus.unfocus();
            },
            decoration: InputDecoration(
              hintText: 'password_hint'.tr(),
              hintStyle: TextStyle(
                  color: hintColor, fontSize: isSmallPhone ? 13 : null),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 12 : 14,
                vertical: isSmallPhone ? 12 : 14,
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 16 : 18),
        // Sign In Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isSmallPhone ? 14 : 16,
                horizontal: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallPhone ? 10 : 12),
              ),
              backgroundColor: const Color(0xFF1E7EFF),
              elevation: 0,
            ),
            onPressed: () {
              // Close keyboard before navigation
              FocusScope.of(context).unfocus();
              // Navigate to EvaluationTextPage
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const EvaluationTextPage()),
              );
            },
            child: Text(
              'sign_in'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isSmallPhone ? 15 : 16,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Bottom padding for keyboard
        SizedBox(
          height: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom + 8
              : (isSmallPhone ? 8 : 12),
        ),
      ],
    );
  }
}
