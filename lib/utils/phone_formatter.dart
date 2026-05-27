import 'package:flutter/services.dart';

class CustomPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;

    // Handle backspace or empty
    if (text.isEmpty) return newValue;

    // Always ensure it starts with +92
    if (!text.startsWith('+92')) {
      // If user typed 0 or 92 or 3, try to fix it
      String digits = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith('92')) {
        digits = digits.substring(2);
      } else if (digits.startsWith('0')) {
        digits = digits.substring(1);
      }
      text = '+92 $digits';
    }

    // Strip everything to digits to reformat correctly (excluding the +92 prefix)
    String prefix = "+92 ";
    String rest = text.length > prefix.length ? text.substring(prefix.length) : "";
    String digits = rest.replaceAll(RegExp(r'[^0-9]'), '');

    String formatted = prefix;

    if (digits.isNotEmpty) {
      // Add first 3 digits
      if (digits.length <= 3) {
        formatted += digits;
      } else {
        formatted += "${digits.substring(0, 3)} ";
        // Add remaining digits (up to 7 more)
        String remaining = digits.substring(3);
        if (remaining.length > 7) {
          remaining = remaining.substring(0, 7);
        }
        formatted += remaining;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
