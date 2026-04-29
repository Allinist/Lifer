class Formatters {
  static String unitLabel({
    required String symbol,
    required String name,
  }) {
    final s = symbol.trim();
    final n = name.trim();
    if (s.isEmpty && n.isEmpty) return '--';
    if (s.isEmpty) return n;
    if (n.isEmpty || s == n) return s;
    return '$s · $n';
  }

  static String currencyFromMinor(int? amountMinor, {String? currencyCode}) {
    if (amountMinor == null) return '--';
    final code = (currencyCode ?? 'CNY').toUpperCase();
    final symbol = switch (code) {
      'USD' => '\$',
      'EUR' => '€',
      'JPY' => '¥',
      'GBP' => '£',
      'CHF' => 'CHF ',
      'CAD' => 'C\$',
      'KRW' => '₩',
      _ => '¥',
    };
    return '$symbol${(amountMinor / 100).toStringAsFixed(2)}';
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
