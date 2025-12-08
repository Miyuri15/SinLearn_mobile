import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

enum UserType { student, teacher }

class _SignUpPageState extends State<SignUpPage> {
  UserType _selected = UserType.student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF3F9FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(padding: const EdgeInsets.all(16.0), child: _LanguageToggle()),
              ),

              Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // logo
                          Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(color: Color(0xFF1E63FF), shape: BoxShape.circle),
                            child: const Icon(Icons.school, size: 44, color: Colors.white),
                          ),

                          const SizedBox(height: 18),
                          Text('app_name'.tr(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('ai_subtitle'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.center),

                          const SizedBox(height: 18),

                          // Tabs — Sign In / Sign Up capsule, active is Sign Up
                          Container(
                            width: 360,
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 6))],
                              border: Border.all(color: Colors.grey.withOpacity(0.06)),
                            ),
                            child: Row(children: [
                              Expanded(
                                  child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text('sign_in'.tr(), style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w700)),
                                ),
                              )),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF1E7EFF), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: Offset(0, 6))]),
                                child: Text('sign_up'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              )),
                            ]),
                          ),

                          const SizedBox(height: 18),

                          // Form fields
                          Align(alignment: Alignment.centerLeft, child: Text('name'.tr(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]))),
                          const SizedBox(height: 6),
                          _boxedField(hint: 'name_hint'.tr()),
                          const SizedBox(height: 12),

                          Align(alignment: Alignment.centerLeft, child: Text('email'.tr(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]))),
                          const SizedBox(height: 6),
                          _boxedField(hint: 'email_hint'.tr()),
                          const SizedBox(height: 12),

                          Align(alignment: Alignment.centerLeft, child: Text('password'.tr(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]))),
                          const SizedBox(height: 6),
                          _boxedField(hint: 'password_hint'.tr(), obscure: true),

                          const SizedBox(height: 18),

                          // user type selection
                          Align(alignment: Alignment.centerLeft, child: Text('user_type'.tr(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selected = UserType.student),
                                  child: _roleCard(
                                    icon: Icons.menu_book,
                                    label: 'student'.tr(),
                                    active: _selected == UserType.student,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selected = UserType.teacher),
                                  child: _roleCard(
                                    icon: Icons.school,
                                    label: 'teacher'.tr(),
                                    active: _selected == UserType.teacher,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E7EFF), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () => Navigator.pop(context),
                              child: Text('sign_up'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                            ),
                          ),

                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // internal language toggle for sign-up page (simple copy of sign-in's toggle)
  Widget _LanguageToggle() {
    return Builder(builder: (context) {
      final locale = context.locale;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.language, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.setLocale(const Locale('si')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: locale.languageCode == 'si' ? Colors.blue[600] : Colors.transparent, borderRadius: BorderRadius.circular(16)),
              child: Text('si_name'.tr(), style: TextStyle(fontSize: 14, color: locale.languageCode == 'si' ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.setLocale(const Locale('en')),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: locale.languageCode == 'en' ? Colors.blue[600] : Colors.transparent, borderRadius: BorderRadius.circular(16)),
              child: Text('en_name'.tr(), style: TextStyle(fontSize: 14, color: locale.languageCode == 'en' ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      );
    });
  }

  Widget _boxedField({required String hint, bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0xFFF6F9FF), border: Border.all(color: const Color(0xFFE0E4F0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0,2))]),
      child: TextFormField(
        obscureText: obscure,
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFFA9B0C3)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
      ),
    );
  }

  Widget _roleCard({required IconData icon, required String label, bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0xFFF6F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? const Color(0xFF1E7EFF) : Colors.transparent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E4F0)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, size: 20, color: active ? const Color(0xFF1E7EFF) : Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: active ? const Color(0xFF1E7EFF) : Colors.grey[700], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
