import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digits
    String newText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    
    // Handle decimal point
    if (newText.contains('.')) {
      List<String> parts = newText.split('.');
      String integerPart = parts[0];
      String decimalPart = parts.length > 1 ? parts[1] : '';
      
      // Limit decimal places to 2
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      
      if (integerPart.isEmpty) integerPart = '0';
      
      double value = double.tryParse(integerPart) ?? 0;
      String formattedInteger = _formatter.format(value).trim();
      
      newText = '$formattedInteger.$decimalPart';
    } else {
      double value = double.tryParse(newText) ?? 0;
      newText = _formatter.format(value).trim();
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
