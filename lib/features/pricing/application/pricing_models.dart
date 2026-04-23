class PricePointViewData {
  const PricePointViewData({
    required this.label,
    required this.amountMinor,
  });

  final String label;
  final int amountMinor;
}

class PriceStatsViewData {
  const PriceStatsViewData({
    required this.recordCount,
    required this.latestAmountMinor,
    required this.lowestAmountMinor,
    required this.highestAmountMinor,
  });

  final int recordCount;
  final int? latestAmountMinor;
  final int? lowestAmountMinor;
  final int? highestAmountMinor;
}
