import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // State to toggle between Sign In and Sign Up
  bool _isSignIn = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final isPhone = size.width < 600;
    final isDark = theme.brightness == Brightness.dark;

    // Background Gradients
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

    // Dynamic Emblem Size
    final emblemSize = isSmallPhone
        ? 56.0
        : isPhone
            ? 64.0
            : 72.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
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
                // Language Toggle
                Positioned(
                  top: isSmallPhone ? 12 : 16,
                  right: isSmallPhone ? 12 : 20,
                  child: const _LanguageToggle(),
                ),

                // Main Scrollable Area
                Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: isSmallPhone ? 40 : 50,
                        bottom: 20,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isSmallPhone
                                ? 12
                                : isPhone
                                    ? 16
                                    : 24,
                            vertical: 8,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: surfaceFill,
                              borderRadius:
                                  BorderRadius.circular(isSmallPhone ? 24 : 28),
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

                                  // --- LOGO (Static) ---
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
                                      size: emblemSize * 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: isSmallPhone ? 16 : 24),

                                  // --- APP NAME (Static) ---
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

                                  // --- SMOOTH TABS ---
                                  _buildTabs(
                                      isSmallPhone, isPhone, surfaceFill),

                                  SizedBox(height: isSmallPhone ? 18 : 22),

                                  // --- ANIMATED FORM TRANSITION ---
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        return FadeTransition(
                                            opacity: animation, child: child);
                                      },
                                      layoutBuilder:
                                          (currentChild, previousChildren) {
                                        return Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            ...previousChildren,
                                            if (currentChild != null)
                                              currentChild,
                                          ],
                                        );
                                      },
                                      child: _isSignIn
                                          ? const SignInForm(
                                              key: ValueKey('signin'))
                                          : SignUpForm(
                                              key: const ValueKey('signup'),
                                              // PASS THE CALLBACK HERE:
                                              onSignUpSuccess: () {
                                                setState(() {
                                                  _isSignIn = true;
                                                });
                                              },
                                            ),
                                    ),
                                  ),
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

  Widget _buildTabs(bool isSmallPhone, bool isPhone, Color surfaceFill) {
    return Container(
      height: isSmallPhone
          ? 44
          : isPhone
              ? 48
              : 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceFill,
        borderRadius: BorderRadius.circular(isSmallPhone ? 16 : 20),
        border: Border.all(color: Colors.grey.withOpacity(0.06)),
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
          _buildTabItem(
            text: 'sign_in'.tr(),
            isActive: _isSignIn,
            onTap: () => setState(() => _isSignIn = true),
            isSmallPhone: isSmallPhone,
            surfaceFill: surfaceFill,
          ),
          SizedBox(width: isSmallPhone ? 6 : 8),
          _buildTabItem(
            text: 'sign_up'.tr(),
            isActive: !_isSignIn,
            onTap: () => setState(() => _isSignIn = false),
            isSmallPhone: isSmallPhone,
            surfaceFill: surfaceFill,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
    required bool isSmallPhone,
    required Color surfaceFill,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isSmallPhone ? 14 : 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? surfaceFill : Colors.transparent,
            borderRadius: BorderRadius.circular(isSmallPhone ? 14 : 18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
            border: Border.all(
              color:
                  isActive ? Colors.blue.withOpacity(0.15) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isSmallPhone ? 13 : null,
              color: isActive ? null : Colors.grey[500],
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
          Icon(Icons.language,
              size: isSmallPhone
                  ? 14
                  : isPhone
                      ? 16
                      : 20,
              color: iconColor),
          SizedBox(
              width: isSmallPhone
                  ? 6
                  : isPhone
                      ? 8
                      : 12),
          _langOption(context, 'si', 'si_name', locale.languageCode == 'si',
              isSmallPhone, isPhone, textUnselected),
          SizedBox(
              width: isSmallPhone
                  ? 6
                  : isPhone
                      ? 8
                      : 10),
          _langOption(context, 'en', 'en_name', locale.languageCode == 'en',
              isSmallPhone, isPhone, textUnselected),
        ],
      ),
    );
  }

  Widget _langOption(BuildContext context, String code, String key,
      bool isSelected, bool isSmall, bool isPhone, Color? unselectedColor) {
    return GestureDetector(
      onTap: () => context.setLocale(Locale(code)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall
              ? 8
              : isPhone
                  ? 10
                  : 12,
          vertical: isSmall
              ? 4
              : isPhone
                  ? 6
                  : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          key.tr(),
          style: TextStyle(
            fontSize: isSmall
                ? 11
                : isPhone
                    ? 12
                    : 14,
            color: isSelected ? Colors.white : unselectedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
