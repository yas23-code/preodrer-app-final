import 'package:intl/intl.dart';

String formatCurrency(
  double amount, {
  String currency = 'INR',
  String locale = 'en_IN',
}) {
  return NumberFormat.simpleCurrency(
    name: currency,
    locale: locale,
  ).format(amount);
}

String formatDate(DateTime date, {String locale = 'en_IN'}) {
  return DateFormat.yMMMd(locale).format(date);
}

