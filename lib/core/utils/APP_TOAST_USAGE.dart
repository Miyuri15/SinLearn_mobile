// AppToast Usage Guide

// ============================================================================
//                            SUCCESS TOAST
// ============================================================================

AppToast.success(
  context,
  'Operation completed successfully',
);

// With custom duration
AppToast.success(
  context,
  'Your changes have been saved',
  duration: const Duration(seconds: 5),
);

// With callback when dismissed
AppToast.success(
  context,
  'File uploaded',
  onDismiss: () {
    print('Toast dismissed');
  },
);

// ============================================================================
//                            ERROR TOAST
// ============================================================================

AppToast.error(
  context,
  'Failed to load data. Please try again.',
);

// With custom duration (default is 4 seconds)
AppToast.error(
  context,
  'Network error',
  duration: const Duration(seconds: 6),
);

// ============================================================================
//                            WARNING TOAST
// ============================================================================

AppToast.warning(
  context,
  'This action cannot be undone',
);

// ============================================================================
//                            INFO TOAST
// ============================================================================

AppToast.info(
  context,
  'New version available. Please update the app.',
);

// ============================================================================
//                        USAGE WITH ERROR HANDLER
// ============================================================================

try {
  // Some operation
} catch (e) {
  final errorMessage = ErrorHandler.getErrorMessage(e);
  AppToast.error(context, errorMessage);
}

// ============================================================================
//                            TOAST FEATURES
// ============================================================================

// 1. Floating behavior (appears above keyboard)
// 2. Rounded corners (12px border radius)
// 3. Icons for visual distinction:
//    - Success: check_circle_outline (green)
//    - Error: error_outline (red)
//    - Warning: warning_outline (orange)
//    - Info: info_outline (blue)
// 4. Dismiss button for manual closure
// 5. Customizable duration
// 6. Optional callback on dismiss
// 7. Responsive to theme (light/dark mode)
// 8. Localization support via 'auth.login_successful'.tr()
