import 'package:flutter/services.dart';

class OneDecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    // Allow empty, digits, optional one dot and one decimal
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d{0,3}(?:\.\d?)?$').hasMatch(text)) {
      return oldValue;
    }
    // prevent leading dot
    if (text == '.') return oldValue;
    return newValue;
  }
}
