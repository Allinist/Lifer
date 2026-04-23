class Formatters {
  static String currencyFromMinor(int? amountMinor) {
    if (amountMinor == null) return '--';
    return (amountMinor / 100).toStringAsFixed(2);
  }

  static String shortDateFromMillis(int? millis) {
    if (millis == null) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

  static String fullDateFromMillis(int? millis) {
    if (millis == null) return '--';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String quantity(num? value) {
    if (value == null) return '--';
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}
