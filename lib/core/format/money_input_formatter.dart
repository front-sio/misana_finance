import 'package:flutter/services.dart';

/// Allows only digits and a single decimal point, with up to [decimalRange] digits after the point.
class MoneyInputFormatter extends TextInputFormatter {
  final int decimalRange;

  MoneyInputFormatter({this.decimalRange = 2}) : assert(decimalRange >= 0);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // Allow "0." when user starts typing decimal
    if (text == '.') {
      return const TextEditingValue(text: '0.', selection: TextSelection.collapsed(offset: 2));
    }

    // Only digits and at most one '.'
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) return oldValue;

    // Only one dot allowed
    if ('.'.allMatches(text).length > 1) return oldValue;

    // Enforce decimal range
    if (text.contains('.')) {
      final parts = text.split('.');
      final after = parts.length > 1 ? parts[1] : '';
      if (after.length > decimalRange) return oldValue;
    }

    return newValue;
  }
}