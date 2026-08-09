/// Input Validation Utility for VirtuaNetLab
///
/// Enforces RegEx validation rules for institutional Matriculation Numbers,
/// Email Addresses, and Password Strength.
class Validators {
  Validators._();

  /// RegEx pattern for institutional Matriculation Numbers
  /// Format: NT + 4-digit admission year + 5-digit sequence (e.g., NT202401115)
  /// Updated pattern: ^NT\d{4}\d{5,7}$ (supports 5 to 7 digit student sequences like NT20240111512)
  static final RegExp _matricRegExp = RegExp(
    r'^NT\d{4}\d{5,7}$',
    caseSensitive: false,
  );

  /// Standard Email RegEx pattern
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );

  /// Validates institutional Matriculation Number (e.g., NT20240111512)
  static bool isValidMatricNumber(String input) {
    final cleanInput = input.trim().toUpperCase();
    return _matricRegExp.hasMatch(cleanInput);
  }

  /// Validates Email Address format
  static bool isValidEmail(String input) {
    final cleanInput = input.trim();
    return _emailRegExp.hasMatch(cleanInput);
  }

  /// Determines whether the login input is a Matriculation Number or Email Address
  static bool isMatricNumber(String input) {
    final cleanInput = input.trim().toUpperCase();
    return cleanInput.startsWith('NT') || isValidMatricNumber(cleanInput);
  }

  /// Validates password strength (Minimum 6 characters)
  static bool isPasswordValid(String input) {
    return input.length >= 6;
  }

  /// Validates display name non-empty
  static bool isValidDisplayName(String input) {
    return input.trim().isNotEmpty && input.trim().length >= 2;
  }
}
