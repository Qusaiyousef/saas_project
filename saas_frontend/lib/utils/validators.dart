/// Helper validators for form fields across the app.
class FormValidators {
  /// Validates human names (prevents random keyboard mashing like "jsdhlakjdoo" or "تانيتاسبستن")
  static bool isValidName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 3) return false;

    // Must contain only letters (Arabic or English), spaces, dots, or hyphens
    final nameRegex = RegExp(r'^[\u0600-\u06FFa-zA-Z\s\-\.]+$');
    if (!nameRegex.hasMatch(trimmed)) return false;

    // Reject 3+ repeating identical characters (e.g., "aaaa", "بببب")
    if (RegExp(r'(.)\1{2,}').hasMatch(trimmed)) return false;

    // Reject English 4+ consecutive consonants without vowels (e.g. "jsdhl", "dfghj")
    if (RegExp(r'[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]{4,}').hasMatch(trimmed)) {
      return false;
    }

    // Check common keyboard pattern mashes (English & Arabic)
    final lower = trimmed.toLowerCase();
    final keyboardMashes = [
      'qwerty', 'asdf', 'zxcv', 'dfgh', 'fghj', 'ghjk', 'hjkl', 'jklm',
      'شسيبل', 'ثصقف', 'شسي', 'حخهع', 'منتأ', 'ةىوز',
      'تانيت', 'سبست', 'سيبلا', 'تنمك', 'شسيب'
    ];

    for (var pattern in keyboardMashes) {
      if (lower.contains(pattern)) return false;
    }

    return true;
  }

  /// Validates Yemen mobile phone numbers (9 digits starting with 77, 78, 73, or 71)
  static bool isValidYemenPhone(String phone) {
    final trimmed = phone.trim();
    return RegExp(r'^(77|78|73|71)\d{7}$').hasMatch(trimmed);
  }
}
