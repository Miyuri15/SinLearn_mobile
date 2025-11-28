# TODO: Implement Dark/Light Themes and Sinhala/English Languages

## Step 1: Update Language Files
- [x] Add missing translation keys to assets/languages/en.json
- [x] Add missing translation keys to assets/languages/si.json

## Step 2: Make Main App Stateful for Theme Toggle
- [x] Modify lib/main.dart to support dynamic themeMode toggle

## Step 3: Update Rubric Selection Screen
- [x] Replace hardcoded colors with theme-aware colors in lib/features/evaluation/rubric_selection_screen.dart
- [x] Add .tr() for all hardcoded texts in rubric_selection_screen.dart

## Step 4: Update Home Screen
- [x] Add .tr() for hardcoded texts in lib/features/home/main_home_screen.dart
- [x] Add language and theme toggle buttons to app bar in main_home_screen.dart

## Step 5: Testing
- [x] Test theme toggle functionality
- [x] Test language toggle functionality
- [x] Verify rubric screen adapts to themes and languages
