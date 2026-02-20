import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/auth_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/app_toast.dart';
import '../learning/learning_mode.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();
  bool _loading = false;
  bool _showPassword = false;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill =
        isDark ? const Color(0xFF141414) : const Color(0xFFF6F9FF);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE0E4F0);
    final labelColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final hintColor = isDark ? Colors.grey[500] : const Color(0xFFA9B0C3);

    return Column(
      children: [
        _buildLabel('email'.tr(), labelColor, isSmallPhone),
        _buildInput(_emailCtrl, _emailFocus, _passwordFocus, false,
            'email_hint'.tr(), hintColor, inputFill, borderColor, isSmallPhone),
        SizedBox(height: isSmallPhone ? 10 : 12),
        _buildLabel('password'.tr(), labelColor, isSmallPhone),
        _buildInput(_pwdCtrl, _passwordFocus, null, true, 'password_hint'.tr(),
            hintColor, inputFill, borderColor, isSmallPhone),
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

                    final email = _emailCtrl.text.trim();
                    final password = _pwdCtrl.text;

                    if (email.isEmpty || password.isEmpty) {
                      AppToast.warning(
                        context,
                        'Please enter email and password',
                      );
                      return;
                    }

                    setState(() => _loading = true);

                    try {
                      final result = await _authService.signIn(
                        email: email,
                        password: password,
                      );

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

                      AppToast.success(
                        context,
                        'auth.login_successful'.tr(),
                      );

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const LearningModePage()),
                      );
                    } catch (e) {
                      final errorMessage = ErrorHandler.getErrorMessage(e);

                      debugPrint(
                          'Login error: ${ErrorHandler.getErrorCode(e)} - $e');

                      if (mounted) {
                        AppToast.error(
                          context,
                          errorMessage,
                        );
                      }
                    } finally {
                      setState(() => _loading = false);
                    }
                  },
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'sign_in'.tr(),
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isSmallPhone ? 15 : 16,
                        color: Colors.white),
                  ),
          ),
        ),
        // Bottom spacer for animation smoothness
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
        obscureText: isPwd && !_showPassword,
        keyboardType: isPwd ? TextInputType.text : TextInputType.emailAddress,
        textCapitalization:
            isPwd ? TextCapitalization.none : TextCapitalization.none,
        autofillHints: isPwd
            ? const [AutofillHints.password]
            : const [AutofillHints.email],
        textInputAction:
            next != null ? TextInputAction.next : TextInputAction.done,
        onEditingComplete: () =>
            next != null ? next.requestFocus() : focus.unfocus(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: isSmall ? 13 : null),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(isSmall ? 12 : 14),
          suffixIcon: isPwd
              ? IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                )
              : null,
        ),
      ),
    );
  }
}
