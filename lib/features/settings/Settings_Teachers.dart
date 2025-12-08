
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class SettingTeachers extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> toggleTheme;

  const SettingTeachers({
    super.key,
    required this.isDark,
    required this.toggleTheme,
  });

  @override
  State<SettingTeachers> createState() => _SettingTeachersState();
}

class _SettingTeachersState extends State<SettingTeachers> {

  bool get isDark => widget.isDark;

  // State variables for toggles
  bool messagesOn = true;
  bool evaluationsOn = true;
  bool chatHistoryOn = true;
  bool dataCollectionOn = true;

  IconData get _appearanceIcon {
    return isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined;
  }

  // --- FIGMA COLORS (Now defined via Theme or used locally for specific elements) ---
  final Color primaryBlue = const Color(0xFF2563EB); // Primary Blue
  // Dark Theme specific profile input background color (As requested: Blue for Profile)
  final Color darkProfileInputBackground = const Color(0xFF2563EB).withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    //  Theme
    Theme.of(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    //  Theme API colors
    final background = theme.scaffoldBackgroundColor; // Main Scaffold Background
    final card = theme.cardColor; // Card Background
    final text = colorScheme.onBackground; // Primary Text Color
    final subText = colorScheme.secondary; // Secondary Text Color (SubText)
    final languageInputBg = colorScheme.surface; // Input Background (from ColorScheme)

    // Input/Read-only Box Background color for PROFILE (Custom rule kept)
    final profileInputBg = isDark ? darkProfileInputBackground : colorScheme.surface;

    // Info Box Colors (Local hardcoded colors kept for precise control)
    final infoBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final infoBorder = isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE);
    final infoText = isDark ? const Color(0xFF93C5FD) : const Color(0xFF374151);

    // Header background (using card color for consistency)
    final headerBg = card;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          // --- HEADER & BODY WRAPPED IN A COLUMN WITH HEADER BACKGROUND ---
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16).copyWith(bottom: 20),
                decoration: BoxDecoration(
                  color: headerBg,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      icon: Icon(Icons.arrow_back, color: text),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Localization Key
                        Text("settings.header".tr(),
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: text)),
                        // Localization Key
                        Text("settings.manage_preferences".tr(),
                            style: TextStyle(fontSize: 13, color: subText)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16), // Gap between header and first card

              // ---------------- LANGUAGE ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCard(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language, color: text),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //  Localization Key
                              Text("settings.language".tr(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, color: text)),
                              //  Localization Key
                              Text("settings.select_interface_language".tr(),
                                  style: TextStyle(fontSize: 13, color: subText)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<Locale>(
                        value: context.locale,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: languageInputBg, //  Theme API
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? subText.withOpacity(0.3) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: isDark ? subText.withOpacity(0.3) : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryBlue), // Focus border color
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        style: TextStyle(color: text),
                        dropdownColor: card,
                        items: [
                          DropdownMenuItem(
                              value: const Locale('en'), child: Text("English", style: TextStyle(color: text))),
                          DropdownMenuItem(
                              value: const Locale('si'), child: Text("සිංහල", style: TextStyle(color: text))),
                        ],
                        onChanged: (newLocale) {
                          if (newLocale != null) {
                            context.setLocale(newLocale);
                            setState(() {});
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: infoBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: infoBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: infoText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                //  Localization Key
                                "settings.ai_note".tr(),
                                style: TextStyle(fontSize: 12, color: infoText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- APPEARANCE ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCard(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Row for Icon and Title ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_appearanceIcon, color: text, size: 26),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              //  Localization Key
                              "settings.appearance".tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: text,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // --- Subtitle ---
                      Text(
                        // Localization Key
                        "settings.customize_theme".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: subText,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- Dark Mode Toggle Row ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Localization Key
                              Text("settings.dark_mode".tr(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500, color: text)),
                              //  Localization Key
                              Text("settings.enable_dark_mode".tr(),
                                  style: TextStyle(fontSize: 12, color: subText)),
                            ],
                          ),
                          Switch(
                            value: isDark,
                            onChanged: (v) {
                              widget.toggleTheme(v);
                              Future.microtask(() => setState(() {}));
                            },
                            // Requested Switch Style
                            activeColor: Colors.white,
                            inactiveThumbColor: Colors.white,
                            activeTrackColor: primaryBlue,
                            inactiveTrackColor: Colors.grey.shade400,
                          )

                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- PROFILE ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCard(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Icon(Icons.person_outline, color: text, size: 26),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(

                              "settings.profile".tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: text,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        //  Localization Key
                        "settings.your_account_information".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: subText,
                        ),
                      ),

                      const SizedBox(height: 16),
                      //  Localization Key
                      _label("settings.user_type".tr(), subText),

                      // Read-only Box (Uses profileInputBg for blue background in Dark Mode)
                      _readonlyBox("teacher".tr(), profileInputBg, text, isDark),

                      const SizedBox(height: 12),
                      // Localization Key
                      _label("settings.name".tr(), subText),
                      _inputBox("User Name", profileInputBg, text, isDark), // Corrected: Uses profileInputBg

                      const SizedBox(height: 12),
                      // ✅ Localization Key සංශෝධනය කර ඇත
                      _label("settings.email".tr(), subText),
                      _inputBox("user@example.com", profileInputBg, text, isDark), // Corrected: Uses profileInputBg
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),


              // ---------------- NOTIFICATIONS ----------------

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCard(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notifications_none, color: text, size: 26),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              // Localization Key
                              "settings.notifications".tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: text,
                              ),
                            ),
                          ),
                        ],
                      ),


                      const SizedBox(height: 4),

                      Text(
                        //  Localization Key
                        "settings.manage_notifications_preferences".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: subText,
                        ),
                      ),


                      const SizedBox(height: 16),

                      // Toggle 1 (Switch Style applied)
                      _toggleItem(
                        //  Localization Key
                        title: "settings.message_notifications".tr(),
                        //  Localization Key
                        subtitle: "settings.message_notifications_desc".tr(),
                        value: messagesOn,
                        onChanged: (v) => setState(() => messagesOn = v),
                        // Using custom style for all toggles
                        activeColor: Colors.white,
                        inactiveThumbColor: Colors.white,
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: Colors.grey.shade400,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Toggle 2 (Switch Style applied)
                      _toggleItem(
                        //  Localization Key
                        title: "settings.evaluation_notifications".tr(),
                        //  Localization Key
                        subtitle: "settings.evaluation_notifications_complete".tr(),
                        value: evaluationsOn,
                        onChanged: (v) => setState(() => evaluationsOn = v),
                        // Using custom style for all toggles
                        activeColor: Colors.white,
                        inactiveThumbColor: Colors.white,
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: Colors.grey.shade400,
                        isDark: isDark,
                      ),

                    ],
                  ),
                ),
              ),


              const SizedBox(height: 20),


              // ---------------- Privacy ----------------

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCard(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: text, size: 26),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              //  Localization Key
                              "settings.privacy_security".tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                color: text,
                              ),
                            ),
                          ),
                        ],
                      ),


                      const SizedBox(height: 4),

                      Text(
                        //  Localization Key
                        "settings.data_and_privacy_settings".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: subText,
                        ),
                      ),


                      const SizedBox(height: 16),

                      // Toggle 3 (Switch Style applied)
                      _toggleItem(
                        // Localization Key
                        title: "settings.save_chat_history".tr(),
                        //  Localization Key
                        subtitle: "settings.save_chat_history_desc".tr(),
                        value: chatHistoryOn,
                        onChanged: (v) => setState(() => chatHistoryOn = v),
                        // Using custom style for all toggles
                        activeColor: Colors.white,
                        inactiveThumbColor: Colors.white,
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: Colors.grey.shade400,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Toggle 4 (Switch Style applied)
                      _toggleItem(

                        title: "settings.data_collection".tr(),

                        subtitle: "settings.data_collection_desc".tr(),
                        value: dataCollectionOn,
                        onChanged: (v) => setState(() => dataCollectionOn = v),
                        // Using custom style for all toggles
                        activeColor: Colors.white,
                        inactiveThumbColor: Colors.white,
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: Colors.grey.shade400,
                        isDark: isDark,
                      ),

                    ],
                  ),
                ),
              ),


              const SizedBox(height: 20),

              // ---------------- ABOUT ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCard(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: text),
                          const SizedBox(width: 12),

                          Text("settings.about".tr(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: text)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _infoItem("settings.version".tr(), "1.0.0", text, subText),
                      const SizedBox(height: 10),

                      _infoItem("settings.license".tr(), "MIT", text, subText),

                      const SizedBox(height: 20),
                      Divider(color: isDark ? Colors.grey : Colors.grey.shade300),
                      const SizedBox(height: 16),

                      Center(
                        child: Column(
                          children: [

                            Text("settings.terms_conditions".tr(),
                                style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),

                            Text("settings.privacy_policy".tr(),
                                style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _infoItem(String title, String value, Color text, Color subText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: subText)),
        Text(value, style: TextStyle(color: text, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCard({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _label(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  // Bg color parameter now uses the specific inputBg color
  Widget _readonlyBox(String value, Color bg, Color text, bool isDark) {
    // Border should be lighter for the profile blue input background
    final borderColor = isDark ? text.withOpacity(0.1) : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.0)
      ),
      child: Text(value, style: TextStyle(color: text, fontWeight: FontWeight.w500)),
    );
  }

  // Bg color parameter now uses the specific inputBg color
  Widget _inputBox(String value, Color bg, Color text, bool isDark) {
    final borderColor = isDark ? text.withOpacity(0.1) : Colors.grey.shade300;
    final primaryBlue = const Color(0xFF2563EB);

    return TextField(
      style: TextStyle(color: text),
      decoration: InputDecoration(
        filled: true,
        fillColor: bg,
        hintText: value,
        hintStyle: TextStyle(color: text.withOpacity(0.5)),
        contentPadding: const EdgeInsets.all(12),
        // Dark theme needs a subtle border, especially with blue background
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryBlue, width: 2.0)),
      ),
      controller: TextEditingController(text: value),
    );
  }

  // Toggle switch functionality and colors fixed
  Widget _toggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required Color inactiveThumbColor,
    required Color activeTrackColor,
    required Color inactiveTrackColor,
    required bool isDark,
  }) {
    final currentText = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final currentSubText = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: currentText)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: currentSubText)),
          ]),
        ),
        Switch(
          value: value,
          activeColor: activeColor, // White dot when active
          inactiveThumbColor: inactiveThumbColor, // White dot when inactive
          activeTrackColor: activeTrackColor, // Blue track when active
          inactiveTrackColor: inactiveTrackColor, // Gray track when inactive
          onChanged: onChanged,
        ),
      ],
    );
  }
}


/*
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  args:
    dependency: transitive
    description:
      name: args
      sha256: d0481093c50b1da8910eb0bb301626d4d8eb7284aa739614d2b394ee09e3ea04
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  async:
    dependency: transitive
    description:
      name: async
      sha256: d2872f9c19731c2e5f10444b14686eb7cc85c76274bd6c16e1816bff9a3bab63
      url: "https://pub.dev"
    source: hosted
    version: "2.12.0"
  audio_waveforms:
    dependency: "direct main"
    description:
      name: audio_waveforms
      sha256: "658fef41bbab299184b65ba2fd749e8ec658c1f7d54a21f7cf97fa96b173b4ce"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.0"
  boolean_selector:
    dependency: transitive
    description:
      name: boolean_selector
      sha256: "8aab1771e1243a5063b8b0ff68042d67334e3feab9e95b9490f9a6ebf73b42ea"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  characters:
    dependency: transitive
    description:
      name: characters
      sha256: f71061c654a3380576a52b451dd5532377954cf9dbd272a78fc8479606670803
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  clock:
    dependency: transitive
    description:
      name: clock
      sha256: fddb70d9b5277016c77a80201021d40a2247104d9f4aa7bab7157b7e3f05b84b
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  collection:
    dependency: transitive
    description:
      name: collection
      sha256: "2f5709ae4d3d59dd8f7cd309b4e023046b57d8a6c82130785d2b0e5868084e76"
      url: "https://pub.dev"
    source: hosted
    version: "1.19.1"
  connectivity_plus:
    dependency: "direct main"
    description:
      name: connectivity_plus
      sha256: b5e72753cf63becce2c61fd04dfe0f1c430cc5278b53a1342dc5ad839eab29ec
      url: "https://pub.dev"
    source: hosted
    version: "6.1.5"
  connectivity_plus_platform_interface:
    dependency: transitive
    description:
      name: connectivity_plus_platform_interface
      sha256: "42657c1715d48b167930d5f34d00222ac100475f73d10162ddf43e714932f204"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.1"
  cross_file:
    dependency: transitive
    description:
      name: cross_file
      sha256: "7caf6a750a0c04effbb52a676dce9a4a592e10ad35c34d6d2d0e4811160d5670"
      url: "https://pub.dev"
    source: hosted
    version: "0.3.4+2"
  cupertino_icons:
    dependency: "direct main"
    description:
      name: cupertino_icons
      sha256: ba631d1c7f7bef6b729a622b7b752645a2d076dba9976925b8f25725a30e1ee6
      url: "https://pub.dev"
    source: hosted
    version: "1.0.8"
  dbus:
    dependency: transitive
    description:
      name: dbus
      sha256: "79e0c23480ff85dc68de79e2cd6334add97e48f7f4865d17686dd6ea81a47e8c"
      url: "https://pub.dev"
    source: hosted
    version: "0.7.11"
  easy_localization:
    dependency: "direct main"
    description:
      name: easy_localization
      sha256: "2ccdf9db8fe4d9c5a75c122e6275674508fd0f0d49c827354967b8afcc56bbed"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.8"
  easy_logger:
    dependency: transitive
    description:
      name: easy_logger
      sha256: c764a6e024846f33405a2342caf91c62e357c24b02c04dbc712ef232bf30ffb7
      url: "https://pub.dev"
    source: hosted
    version: "0.0.2"
  fake_async:
    dependency: transitive
    description:
      name: fake_async
      sha256: "5368f224a74523e8d2e7399ea1638b37aecfca824a3cc4dfdf77bf1fa905ac44"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.3"
  ffi:
    dependency: transitive
    description:
      name: ffi
      sha256: "16ed7b077ef01ad6170a3d0c57caa4a112a38d7a2ed5602e0aca9ca6f3d98da6"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.3"
  file:
    dependency: transitive
    description:
      name: file
      sha256: a3b4f84adafef897088c160faf7dfffb7696046cb13ae90b508c2cbc95d3b8d4
      url: "https://pub.dev"
    source: hosted
    version: "7.0.1"
  file_picker:
    dependency: "direct main"
    description:
      name: file_picker
      sha256: ab13ae8ef5580a411c458d6207b6774a6c237d77ac37011b13994879f68a8810
      url: "https://pub.dev"
    source: hosted
    version: "8.3.7"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_lints:
    dependency: "direct dev"
    description:
      name: flutter_lints
      sha256: "3f41d009ba7172d5ff9be5f6e6e6abb4300e263aab8866d2a0842ed2a70f8f0c"
      url: "https://pub.dev"
    source: hosted
    version: "4.0.0"
  flutter_localizations:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_plugin_android_lifecycle:
    dependency: transitive
    description:
      name: flutter_plugin_android_lifecycle
      sha256: "1c2b787f99bdca1f3718543f81d38aa1b124817dfeb9fb196201bea85b6134bf"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.26"
  flutter_riverpod:
    dependency: "direct main"
    description:
      name: flutter_riverpod
      sha256: "9532ee6db4a943a1ed8383072a2e3eeda041db5657cdf6d2acecf3c21ecbe7e1"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  flutter_test:
    dependency: "direct dev"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_web_plugins:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  http:
    dependency: "direct main"
    description:
      name: http
      sha256: "87721a4a50b19c7f1d49001e51409bddc46303966ce89a65af4f4e6004896412"
      url: "https://pub.dev"
    source: hosted
    version: "1.6.0"
  http_parser:
    dependency: transitive
    description:
      name: http_parser
      sha256: "2aa08ce0341cc9b354a498388e30986515406668dbcc4f7c950c3e715496693b"
      url: "https://pub.dev"
    source: hosted
    version: "4.0.2"
  intl:
    dependency: transitive
    description:
      name: intl
      sha256: "3df61194eb431efc39c4ceba583b95633a403f46c9fd341e550ce0bfa50e9aa5"
      url: "https://pub.dev"
    source: hosted
    version: "0.20.2"
  leak_tracker:
    dependency: transitive
    description:
      name: leak_tracker
      sha256: "33e2e26bdd85a0112ec15400c8cbffea70d0f9c3407491f672a2fad47915e2de"
      url: "https://pub.dev"
    source: hosted
    version: "11.0.2"
      sha256: "33e2e26bdd85a0112ec15400c8cbffea70d0f9c3407491f672a2fad47915e2de"
      url: "https://pub.dev"
    source: hosted
    version: "11.0.2"
      sha256: c35baad643ba394b40aac41080300150a4f08fd0fd6a10378f8f7c6bc161acec
      url: "https://pub.dev"
    source: hosted
    version: "10.0.8"
at/evaluation/rubrics
  leak_tracker_flutter_testing:
    dependency: transitive
    description:
      name: leak_tracker_flutter_testing
      sha256: "1dbc140bb5a23c75ea9c4811222756104fbcd1a27173f0c34ca01e16bea473c1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.10"
      sha256: "1dbc140bb5a23c75ea9c4811222756104fbcd1a27173f0c34ca01e16bea473c1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.10"
      sha256: f8b613e7e6a13ec79cfdc0e97638fddb3ab848452eff057653abd3edba760573
      url: "https://pub.dev"
    source: hosted
    version: "3.0.9"
  leak_tracker_testing:
    dependency: transitive
    description:
      name: leak_tracker_testing
      sha256: "8d5a2d49f4a66b49744b23b018848400d23e54caf9463f4eb20df3eb8acb2eb1"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.2"
  lints:
    dependency: transitive
    description:
      name: lints
      sha256: "976c774dd944a42e83e2467f4cc670daef7eed6295b10b36ae8c85bcbf828235"
      url: "https://pub.dev"
    source: hosted
    version: "4.0.0"
  matcher:
    dependency: transitive
    description:
      name: matcher
      sha256: dc58c723c3c24bf8d3e2d3ad3f2f9d7bd9cf43ec6feaa64181775e60190153f2
      url: "https://pub.dev"
    source: hosted
    version: "0.12.17"
  material_color_utilities:
    dependency: transitive
    description:
      name: material_color_utilities
      sha256: f7142bb1154231d7ea5f96bc7bde4bda2a0945d2806bb11670e30b850d56bdec
      url: "https://pub.dev"
    source: hosted
    version: "0.11.1"
  meta:
    dependency: transitive
    description:
      name: meta
      sha256: "23f08335362185a5ea2ad3a4e597f1375e78bce8a040df5c600c8d3552ef2394"
      url: "https://pub.dev"
    source: hosted
    version: "1.17.0"
      sha256: "23f08335362185a5ea2ad3a4e597f1375e78bce8a040df5c600c8d3552ef2394"
      url: "https://pub.dev"
    source: hosted
    version: "1.17.0"
      sha256: e3641ec5d63ebf0d9b41bd43201a66e3fc79a65db5f61fc181f04cd27aab950c
      url: "https://pub.dev"
    source: hosted
    version: "1.16.0"
  nm:
    dependency: transitive
    description:
      name: nm
      sha256: "2c9aae4127bdc8993206464fcc063611e0e36e72018696cd9631023a31b24254"
      url: "https://pub.dev"
    source: hosted
    version: "0.5.0"
  path:
    dependency: transitive
    description:
      name: path
      sha256: "75cca69d1490965be98c73ceaea117e8a04dd21217b37b292c9ddbec0d955bc5"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.1"
  path_provider_linux:
    dependency: transitive
    description:
      name: path_provider_linux
      sha256: f7a1fe3a634fe7734c8d3f2766ad746ae2a2884abe22e241a8b301bf5cac3279
      url: "https://pub.dev"
    source: hosted
    version: "2.2.1"
  path_provider_platform_interface:
    dependency: transitive
    description:
      name: path_provider_platform_interface
      sha256: "88f5779f72ba699763fa3a3b06aa4bf6de76c8e5de842cf6f29e2e06476c2334"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  path_provider_windows:
    dependency: transitive
    description:
      name: path_provider_windows
      sha256: bd6f00dbd873bfb70d0761682da2b3a2c2fccc2b9e84c495821639601d81afe7
      url: "https://pub.dev"
    source: hosted
    version: "2.3.0"
  petitparser:
    dependency: transitive
    description:
      name: petitparser
      sha256: c15605cd28af66339f8eb6fbe0e541bfe2d1b72d5825efc6598f3e0a31b9ad27
      url: "https://pub.dev"
    source: hosted
    version: "6.0.2"
  platform:
    dependency: transitive
    description:
      name: platform
      sha256: "5d6b1b0036a5f331ebc77c850ebc8506cbc1e9416c27e59b439f917a902a4984"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.6"
  plugin_platform_interface:
    dependency: transitive
    description:
      name: plugin_platform_interface
      sha256: "4820fbfdb9478b1ebae27888254d445073732dae3d6ea81f0b7e06d5dedc3f02"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.8"
  riverpod:
    dependency: transitive
    description:
      name: riverpod
      sha256: "59062512288d3056b2321804332a13ffdd1bf16df70dcc8e506e411280a72959"
      url: "https://pub.dev"
    source: hosted
    version: "2.6.1"
  shared_preferences:
    dependency: transitive
    description:
      name: shared_preferences
      sha256: "6e8bf70b7fef813df4e9a36f658ac46d107db4b4cfe1048b477d4e453a8159f5"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.3"
  shared_preferences_android:
    dependency: transitive
    description:
      name: shared_preferences_android
      sha256: "9f9f3d372d4304723e6136663bb291c0b93f5e4c8a4a6314347f481a33bda2b1"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.7"
  shared_preferences_foundation:
    dependency: transitive
    description:
      name: shared_preferences_foundation
      sha256: "6a52cfcdaeac77cad8c97b539ff688ccfc458c007b4db12be584fbe5c0e49e03"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.4"
  shared_preferences_linux:
    dependency: transitive
    description:
      name: shared_preferences_linux
      sha256: "580abfd40f415611503cae30adf626e6656dfb2f0cee8f465ece7b6defb40f2f"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  shared_preferences_platform_interface:
    dependency: transitive
    description:
      name: shared_preferences_platform_interface
      sha256: "57cbf196c486bc2cf1f02b85784932c6094376284b3ad5779d1b1c6c6a816b80"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  shared_preferences_web:
    dependency: transitive
    description:
      name: shared_preferences_web
      sha256: c49bd060261c9a3f0ff445892695d6212ff603ef3115edbb448509d407600019
      url: "https://pub.dev"
    source: hosted
    version: "2.4.3"
  shared_preferences_windows:
    dependency: transitive
    description:
      name: shared_preferences_windows
      sha256: "94ef0f72b2d71bc3e700e025db3710911bd51a71cefb65cc609dd0d9a982e3c1"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  source_span:
    dependency: transitive
    description:
      name: source_span
      sha256: "254ee5351d6cb365c859e20ee823c3bb479bf4a293c22d17a9f1bf144ce86f7c"
      url: "https://pub.dev"
    source: hosted
    version: "1.10.1"
  stack_trace:
    dependency: transitive
    description:
      name: stack_trace
      sha256: "8b27215b45d22309b5cddda1aa2b19bdfec9df0e765f2de506401c071d38d1b1"
      url: "https://pub.dev"
    source: hosted
    version: "1.12.1"
  state_notifier:
    dependency: transitive
    description:
      name: state_notifier
      sha256: b8677376aa54f2d7c58280d5a007f9e8774f1968d1fb1c096adcb4792fba29bb
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
  stream_channel:
    dependency: transitive
    description:
      name: stream_channel
      sha256: "969e04c80b8bcdf826f8f16579c7b14d780458bd97f56d107d3950fdbeef059d"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  string_scanner:
    dependency: transitive
    description:
      name: string_scanner
      sha256: "921cd31725b72fe181906c6a94d987c78e3b98c2e205b397ea399d4054872b43"
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  term_glyph:
    dependency: transitive
    description:
      name: term_glyph
      sha256: "7f554798625ea768a7518313e58f83891c7f5024f88e46e7182a4558850a4b8e"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.2"
  test_api:
    dependency: transitive
    description:
      name: test_api
      sha256: ab2726c1a94d3176a45960b6234466ec367179b87dd74f1611adb1f3b5fb9d55
      url: "https://pub.dev"
    source: hosted
    version: "0.7.7"
      sha256: ab2726c1a94d3176a45960b6234466ec367179b87dd74f1611adb1f3b5fb9d55
      url: "https://pub.dev"
    source: hosted
    version: "0.7.7"
      sha256: fb31f383e2ee25fbbfe06b40fe21e1e458d14080e3c67e7ba0acfde4df4e0bbd
      url: "https://pub.dev"
    source: hosted
    version: "0.7.4"

  typed_data:
    dependency: transitive
    description:
      name: typed_data
      sha256: f9049c039ebfeb4cf7a7104a675823cd72dba8297f264b6637062516699fa006
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  vector_math:
    dependency: transitive
    description:
      name: vector_math
      sha256: d530bd74fea330e6e364cda7a85019c434070188383e1cd8d9777ee586914c5b
      url: "https://pub.dev"
    source: hosted
    version: "2.2.0"
  vm_service:
    dependency: transitive
    description:
      name: vm_service
      sha256: "0968250880a6c5fe7edc067ed0a13d4bae1577fe2771dcf3010d52c4a9d3ca14"
      url: "https://pub.dev"
    source: hosted
    version: "14.3.1"
  web:
    dependency: transitive
    description:
      name: web
      sha256: "868d88a33d8a87b18ffc05f9f030ba328ffefba92d6c127917a2ba740f9cfe4a"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  win32:
    dependency: transitive
    description:
      name: win32
      sha256: daf97c9d80197ed7b619040e86c8ab9a9dad285e7671ee7390f9180cc828a51e
      url: "https://pub.dev"
    source: hosted
    version: "5.10.1"
  xdg_directories:
    dependency: transitive
    description:
      name: xdg_directories
      sha256: "7a3f37b05d989967cdddcbb571f1ea834867ae2faa29725fd085180e0883aa15"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  xml:
    dependency: transitive
    description:
      name: xml
      sha256: b015a8ad1c488f66851d762d3090a21c600e479dc75e68328c52774040cf9226
      url: "https://pub.dev"
    source: hosted
    version: "6.5.0"
sdks:
  dart: ">=3.8.0-0 <4.0.0"
  dart: ">=3.8.0-0 <4.0.0"
  dart: ">=3.7.0-0 <4.0.0"

  flutter: ">=3.24.0"

 */