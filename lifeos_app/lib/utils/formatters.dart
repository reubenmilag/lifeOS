import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }
}
