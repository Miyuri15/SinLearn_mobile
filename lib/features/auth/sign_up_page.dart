import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignUpForm extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  const SignUpForm({super.key, required this.onSignUpSuccess});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  String _userType = 'student';

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _loading = false;

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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inputFill = isDark ? const Color(0xFF141414) : Colors.white;
    final surfaceFill =
        isDark ? const Color(0xFF141414) : const Color(0xFFF6F9FF);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE0E4F0);
    final labelColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final hintColor = isDark ? Colors.grey[500] : const Color(0xFFA9B0C3);

    return Column(
      children: [
        _buildLabel('name'.tr(), labelColor, isSmallPhone),
        _buildInput(_nameCtrl, _nameFocus, _emailFocus, false, 'name_hint'.tr(),
            hintColor, surfaceFill, borderColor, isSmallPhone),
        SizedBox(height: isSmallPhone ? 10 : 12),
        _buildLabel('email'.tr(), labelColor, isSmallPhone),
        _buildInput(
            _emailCtrl,
            _emailFocus,
            _passwordFocus,
            false,
            'email_hint'.tr(),
            hintColor,
            surfaceFill,
            borderColor,
            isSmallPhone),
        SizedBox(height: isSmallPhone ? 10 : 12),
        _buildLabel('password'.tr(), labelColor, isSmallPhone),
        _buildInput(_pwdCtrl, _passwordFocus, null, true, 'password_hint'.tr(),
            hintColor, surfaceFill, borderColor, isSmallPhone),
        SizedBox(height: isSmallPhone ? 10 : 12),
        _buildLabel('user_type'.tr(), labelColor, isSmallPhone),
        Row(
          children: [
            Expanded(
                child: _buildUserTypeBtn('student', Icons.menu_book_outlined,
                    isSmallPhone, isPhone, inputFill, borderColor, labelColor)),
            SizedBox(width: isSmallPhone ? 6 : 8),
            Expanded(
                child: _buildUserTypeBtn('teacher', Icons.school_outlined,
                    isSmallPhone, isPhone, inputFill, borderColor, labelColor)),
          ],
        ),
        SizedBox(height: isSmallPhone ? 16 : 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 14 : 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallPhone ? 10 : 12)),
              backgroundColor: const Color(0xFF1E7EFF),
              elevation: 0,
            ),
            onPressed: _loading
                ? null
                : () async {
                    FocusScope.of(context).unfocus();

                    final name = _nameCtrl.text.trim();
                    final email = _emailCtrl.text.trim();
                    final password = _pwdCtrl.text;

                    if (name.isEmpty || email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    setState(() => _loading = true);

                    try {
                      final result = await _authService.signUp(
                        fullName: name,
                        email: email,
                        password: password,
                      );

                      // ✅ Tokens returned
                      final accessToken = result['access_token'];
                      final refreshToken = result['refresh_token'];

                      // Persist tokens securely for later use
                      try {
                        if (accessToken != null) {
                          await _secureStorage.write(
                              key: 'access_token',
                              value: accessToken.toString());
                        }
                        if (refreshToken != null) {
                          await _secureStorage.write(
                              key: 'refresh_token',
                              value: refreshToken.toString());
                        }
                      } catch (e) {
                        // If secure storage write fails, log and continue (user still created)
                        // You may want to report this to analytics or show a non-blocking message
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Account created successfully')),
                      );
                      widget.onSignUpSuccess();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    } finally {
                      setState(() => _loading = false);
                    }
                  },
            child: Text(
              'sign_up'.tr(),
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isSmallPhone ? 15 : 16,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLabel(String text, Color? color, bool isSmall) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: isSmall ? 4 : 6),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: isSmall ? 13 : null)),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController ctrl,
      FocusNode focus,
      FocusNode? next,
      bool isPwd,
      String hint,
      Color? hintColor,
      Color fill,
      Color border,
      bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        focusNode: focus,
        obscureText: isPwd,
        keyboardType: isPwd ? TextInputType.text : TextInputType.emailAddress,
        textInputAction:
            next != null ? TextInputAction.next : TextInputAction.done,
        onEditingComplete: () =>
            next != null ? next.requestFocus() : focus.unfocus(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: isSmall ? 13 : null),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(isSmall ? 12 : 14),
        ),
      ),
    );
  }

  Widget _buildUserTypeBtn(String type, IconData icon, bool isSmall,
      bool isPhone, Color fill, Color border, Color? labelColor) {
    final isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isSmall
            ? 84
            : isPhone
                ? 96
                : 112,
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF2FF) : fill,
          borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
          border: Border.all(
            color: isSelected ? Colors.blue.withOpacity(0.5) : border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: isSmall
                    ? 20
                    : isPhone
                        ? 22
                        : 26,
                color: isSelected ? Colors.blue[700] : labelColor),
            SizedBox(height: isSmall ? 6 : 8),
            Text(
              type.tr(),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall
                      ? 12
                      : isPhone
                          ? 13
                          : 14,
                  color: isSelected ? Colors.blue[700] : labelColor),
            ),
          ],
        ),
      ),
    );
  }
}
