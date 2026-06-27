// Inline field-validation helpers for the account upgrade form.
//
// Return an error message (shown under the field), or `null` when the value
// is acceptable. These strings are purposely NOT routed through AppStrings
// because they are tight field feedback, not app-chrome.

/// Returns an error message, or null if valid.
String? validateEmail(String email) {
  final e = email.trim();
  if (e.isEmpty) return 'Enter your email';
  // simple but practical: something@something.tld
  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return re.hasMatch(e) ? null : "That email doesn't look right";
}

/// Returns an error message, or null if valid.
String? validatePassword(String password) {
  if (password.length < 8) return 'Use at least 8 characters';
  return null;
}
