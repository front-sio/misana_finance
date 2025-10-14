import 'package:flutter/services.dart';

/// Allows only numbers with optional decimal point and up to [decimalRange] digits after the point.
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange >= 0);

  final _digitsOnly = RegExp(r'^\d+$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // Allow single dot like "0."
    if (text == '.') {
      return TextEditingValue(
        text: '0.',
        selection: const TextSelection.collapsed(offset: 2),
      );
    }

    // Validate allowed chars
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }

    // Enforce one dot
    final dots = '.'.allMatches(text).length;
    if (dots > 1) return oldValue;

    // Enforce decimal range
    if (text.contains('.')) {
      final parts = text.split('.');
      final after = parts.length > 1 ? parts[1] : '';
      if (after.length > decimalRange) return oldValue;
    }

    // Block leading zeros like 00 (but allow 0.x)
    if (!_digitsOnly.hasMatch(text) && text.startsWith('00')) return oldValue;

    return newValue;
  }
}