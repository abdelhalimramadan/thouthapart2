class PhoneHelper {
  /// Normalizes Egyptian phone numbers to the format +201xxxxxxxxx
  static String normalizeEgyptPhone(String input) {
    // Remove all non-digits
    final p = input.trim().replaceAll(RegExp(r'[^\d]'), '');

    // If starts with 20... -> add +
    if (p.startsWith('20')) {
      return '+$p';
    }

    // Default to adding +2 (e.g., 012... becomes +2012...)
    return '+2$p';
  }
}
