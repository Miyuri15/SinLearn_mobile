import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingTeachers extends StatefulWidget {
  const SettingTeachers({super.key});

  @override
  State<SettingTeachers> createState() => _SettingTeachersState();
}

class _SettingTeachersState extends State<SettingTeachers> {

  bool isDark = false;
  // State variables for toggles
  bool messagesOn = true;
  bool evaluationsOn = true;
  bool chatHistoryOn = true;
  bool dataCollectionOn = true;

  IconData get _appearanceIcon {
    return isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined;
  }

  // --- FIGMA COLORS ---
  final Color primaryBlue = const Color(0xFF2563EB); // Primary Blue
  // Dark Theme specific input background color (For Language Dropdown)
  final Color darkInputBackground = const Color(0xFF2A2B32);
  // Dark Theme specific profile input background color (As requested: Blue for Profile)
  final Color darkProfileInputBackground = const Color(0xFF2563EB).withOpacity(0.1); // Slightly transparent blue

  @override
  Widget build(BuildContext context) {
    // Color scheme definitions
    final background = isDark ? const Color(0xFF000000) : const Color(0xFFF3F4F6); // Main Scaffold Background
    final card = isDark ? const Color(0xFF1E1F20) : Colors.white; // Card Background
    final text = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827); // Primary Text Color
    final subText = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280); // Secondary Text Color

    // Input/Dropdown Background color for LANGUAGE (Dynamic based on isDark)
    final languageInputBg = isDark ? darkInputBackground : background;

    // Input/Read-only Box Background color for PROFILE (Dynamic based on isDark/request)
    final profileInputBg = isDark ? darkProfileInputBackground : background;

    // Info Box Colors
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: text),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("settings".tr(),
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: text)),
                        Text("manage_preferences".tr(),
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
                              Text("language".tr(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, color: text)),
                              Text("select_interface_language".tr(),
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
                          fillColor: languageInputBg, // Uses languageInputBg (0xFF2A2B32 in Dark Mode)
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
                                "ai_note".tr(),
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
                              "appearance".tr(),
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
                        "customize_theme".tr(),
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
                              Text("dark_mode".tr(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500, color: text)),
                              Text("enable_dark_mode".tr(),
                                  style: TextStyle(fontSize: 12, color: subText)),
                            ],
                          ),
                          Switch(
                            value: isDark,
                            onChanged: (v) {
                              setState(() {
                                isDark = v;
                              });
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
                              "profile".tr(),
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
                        "your_account_information".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: subText,
                        ),
                      ),

                      const SizedBox(height: 16),
                      _label("user_type".tr(), subText),

                      // Read-only Box (Uses profileInputBg for blue background in Dark Mode)
                      _readonlyBox("teacher".tr(), profileInputBg, text, isDark),

                      const SizedBox(height: 12),
                      _label("name".tr(), subText),
                      _inputBox("User Name", profileInputBg, text, isDark), // Corrected: Uses profileInputBg

                      const SizedBox(height: 12),
                      _label("email".tr(), subText),
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
                              "notifications".tr(),
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
                        "manage_notifications_preferences".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: subText,
                        ),
                      ),


                      const SizedBox(height: 16),

                      // Toggle 1 (Switch Style applied)
                      _toggleItem(
                        title: "message_notifications".tr(),
                        subtitle: "message_notifications_desc".tr(),
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
                        title: "evaluation_notifications".tr(),
                        subtitle: "evaluation_notifications_complete".tr(),
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
                              "privacy_security".tr(),
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
                        "data_and_privacy_settings".tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: subText,
                        ),
                      ),


                      const SizedBox(height: 16),

                      // Toggle 3 (Switch Style applied)
                      _toggleItem(
                        title: "save_chat_history".tr(),
                        subtitle: "save_chat_history_desc".tr(),
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
                        title: "data_collection".tr(),
                        subtitle: "data_collection_desc".tr(),
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
                          Text("about".tr(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: text)),
                        ],
                      ),

                      const SizedBox(height: 20),
                      _infoItem("version".tr(), "1.0.0", text, subText),
                      const SizedBox(height: 10),
                      _infoItem("license".tr(), "MIT", text, subText),

                      const SizedBox(height: 20),
                      Divider(color: isDark ? Colors.grey : Colors.grey.shade300),
                      const SizedBox(height: 16),

                      Center(
                        child: Column(
                          children: [
                            Text("terms_conditions".tr(),
                                style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            Text("privacy_policy".tr(),
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










