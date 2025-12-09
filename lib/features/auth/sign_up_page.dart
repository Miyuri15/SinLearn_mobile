import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'sign_in_page.dart';
import '../evaluation/evaluation_text.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // --- ADDED: theme-aware variables to match SignInPage behavior ---
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isPhone = size.width < 600; // Increased threshold for tablets
    final isSmallPhone = size.width < 380; // Very small phones
    final isDark = theme.brightness == Brightness.dark;

    // Keep blue accents intact; adapt surfaces/inputs/gradients for dark mode
    final bgColors = isDark
        ? [const Color(0xFF0B1220), const Color(0xFF0D1320)]
        : [const Color(0xFFE8EDFF), const Color(0xFFD8DFFF)];

    final cardPadding = EdgeInsets.symmetric(
      horizontal: isSmallPhone ? 20 : isPhone ? 24 : 36,
      vertical: isSmallPhone ? 20 : isPhone ? 28 : 36,
    );

    final surfaceFill = isDark ? theme.cardColor : Colors.white;
    final inputFill = isDark ? const Color(0xFF141414) : const Color(0xFFF6F9FF);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE0E4F0);
    final labelColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final hintColor = isDark ? Colors.grey[500] : const Color(0xFFA9B0C3);
    // ---------------------------------------------------------------------

    final emblemSize = isSmallPhone ? 56.0 : isPhone ? 64.0 : 88.0;
    final emblemIcon = isSmallPhone ? 28.0 : isPhone ? 32.0 : 44.0;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Important for mobile
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            // USE theme-aware background gradient
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: bgColors,
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false, // Allow content to go above keyboard
            child: Stack(
              children: [
                // Language Toggle - Positioned for mobile
                Positioned(
                  top: isSmallPhone ? 12 : 16,
                  right: isSmallPhone ? 12 : 20,
                  child: const _LanguageToggle(),
                ),
                // Main Content
                Padding(
                  padding: EdgeInsets.only(
                    top: isSmallPhone ? 50 : 60, // Space for language toggle
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
                              horizontal: isSmallPhone ? 12 : isPhone ? 16 : 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              // USE theme-aware surface fill for the card
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
                                    width: emblemSize,
                                    height: emblemSize,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E63FF),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.school,
                                      size: emblemIcon,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 16 : 24),
                                  // App Name
                                  Text(
                                    'app_name'.tr(),
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      fontSize: isSmallPhone ? 22 : null,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 4 : 6),
                                  // Subtitle - match SignInPage style
                                  Text(
                                    'ai_subtitle'.tr(),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: isSmallPhone ? 11 : isPhone ? 12 : 13,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 20 : 28),

                                  // Tabs
                                  Container(
                                    height: isSmallPhone ? 44 : isPhone ? 48 : 52,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      // USE surface fill for tab container as well
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
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(isSmallPhone ? 14 : 18),
                                            onTap: () => Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(builder: (_) => const SignInPage()),
                                            ),
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                'sign_in'.tr(),
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: isSmallPhone ? 13 : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: isSmallPhone ? 6 : 8),
                                        Expanded(
                                          child: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: surfaceFill,
                                              borderRadius:
                                                  BorderRadius.circular(isSmallPhone ? 14 : 18),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(0.15),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'sign_up'.tr(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: isSmallPhone ? 13 : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 18 : 22),

                                  // Form
                                  const _SignUpForm(),
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
  const _LanguageToggle({super.key});

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
        horizontal: isSmallPhone ? 6 : isPhone ? 8 : 12,
        vertical: isSmallPhone ? 4 : isPhone ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language,
            size: isSmallPhone ? 14 : isPhone ? 16 : 20,
            color: iconColor,
          ),
          SizedBox(width: isSmallPhone ? 6 : isPhone ? 8 : 12),
          // Sinhala
          GestureDetector(
            onTap: () => context.setLocale(const Locale('si')),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 8 : isPhone ? 10 : 12,
                vertical: isSmallPhone ? 4 : isPhone ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: locale.languageCode == 'si' ? Colors.blue[600] : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'si_name'.tr(),
                style: TextStyle(
                  fontSize: isSmallPhone ? 11 : isPhone ? 12 : 14,
                  color: locale.languageCode == 'si' ? Colors.white : textUnselected,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallPhone ? 6 : isPhone ? 8 : 10),
          // English
          GestureDetector(
            onTap: () => context.setLocale(const Locale('en')),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 8 : isPhone ? 12 : 14,
                vertical: isSmallPhone ? 4 : isPhone ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: locale.languageCode == 'en' ? Colors.blue[600] : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'en_name'.tr(),
                style: TextStyle(
                  fontSize: isSmallPhone ? 11 : isPhone ? 12 : 14,
                  color: locale.languageCode == 'en' ? Colors.white : textUnselected,
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

class _SignUpForm extends StatefulWidget {
  const _SignUpForm({super.key});

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  String _userType = 'student';
  
  // For keyboard handling
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final isPhone = size.width < 600;

    // ADDED: theme-aware inputs for dark mode (same logic as SignInPage)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill = isDark ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE0E4F0);
    final labelColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final hintColor = isDark ? Colors.grey[500] : const Color(0xFFA9B0C3);

    return Column(
      children: [
        // Name Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'name'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: labelColor, // use theme-aware label color
              fontSize: isSmallPhone ? 13 : null,
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 4 : 6),
        Container(
          decoration: BoxDecoration(
            color: inputFill, // changed to theme-aware fill
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
            controller: _nameCtrl,
            focusNode: _nameFocus,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _emailFocus.requestFocus(),
            decoration: InputDecoration(
              hintText: 'name_hint'.tr(),
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

        // Email Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'email'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: labelColor, // theme-aware
              fontSize: isSmallPhone ? 13 : null,
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 4 : 6),
        Container(
          decoration: BoxDecoration(
            color: inputFill, // changed to theme-aware fill
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

        // Password Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'password'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: labelColor, // theme-aware
              fontSize: isSmallPhone ? 13 : null,
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 4 : 6),
        Container(
          decoration: BoxDecoration(
            color: inputFill, // changed to theme-aware fill
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
            controller: _pwdCtrl,
            focusNode: _passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              // Handle sign up
              _passwordFocus.unfocus();
            },
            decoration: InputDecoration(
              hintText: 'password_hint'.tr(),
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

        // User Type
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'user_type'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: labelColor, // theme-aware
              fontSize: isSmallPhone ? 13 : null,
            ),
          ),
        ),
        SizedBox(height: isSmallPhone ? 4 : 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _userType = 'student'),
                child: Container(
                  height: isSmallPhone ? 84 : isPhone ? 96 : 112,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallPhone ? 10 : 12,
                    vertical: isSmallPhone ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: _userType == 'student'
                        ? const Color(0xFFEAF2FF)
                        : inputFill, // use inputFill for unselected to match surface/input
                    borderRadius: BorderRadius.circular(isSmallPhone ? 14 : 16),
                    border: Border.all(
                      color: _userType == 'student'
                          ? Colors.blue.withOpacity(0.5)
                          : borderColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: isSmallPhone ? 20 : isPhone ? 22 : 26,
                        color: _userType == 'student' ? Colors.blue[700] : labelColor,
                      ),
                      SizedBox(height: isSmallPhone ? 6 : 8),
                      Text(
                        'student'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallPhone ? 12 : isPhone ? 13 : 14,
                          color: _userType == 'student' ? Colors.blue[700] : labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmallPhone ? 6 : 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _userType = 'teacher'),
                child: Container(
                  height: isSmallPhone ? 84 : isPhone ? 96 : 112,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallPhone ? 10 : 12,
                    vertical: isSmallPhone ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: _userType == 'teacher'
                        ? const Color(0xFFEAF2FF)
                        : inputFill, // use inputFill for unselected
                    borderRadius: BorderRadius.circular(isSmallPhone ? 14 : 16),
                    border: Border.all(
                      color: _userType == 'teacher'
                          ? Colors.blue.withOpacity(0.5)
                          : borderColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: isSmallPhone ? 20 : isPhone ? 22 : 26,
                        color: _userType == 'teacher' ? Colors.blue[700] : labelColor,
                      ),
                      SizedBox(height: isSmallPhone ? 6 : 8),
                      Text(
                        'teacher'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallPhone ? 12 : isPhone ? 13 : 14,
                          color: _userType == 'teacher' ? Colors.blue[700] : labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: isSmallPhone ? 16 : 18),

        // Sign Up Button
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
              // Proceed to app (mock)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const EvaluationTextPage()),
              );
            },
            child: Text(
              'sign_up'.tr(),
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
