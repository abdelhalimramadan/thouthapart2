class PhoneHelper {
  /// Normalizes Egyptian phone numbers to the format +201xxxxxxxxx
  static String normalizeEgyptPhone(String input) {
    // Remove all non-digits
    String p = input.trim().replaceAll(RegExp(r'[^\d]'), '');

    // Handle full international format starting with 20
    if (p.startsWith('20') && p.length >= 12) {
      return '+$p';
    }
    
    // If it starts with 0, remove it to get the core number
    if (p.startsWith('0')) {
      p = p.substring(1);
    }

    // Now if it's a mobile number (10, 11, 12, 15...), it should be 10 digits long
    // Add +20 prefix
    return '+20$p';
  }
}
