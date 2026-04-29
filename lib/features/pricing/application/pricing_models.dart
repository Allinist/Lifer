class PricePointViewData {
  const PricePointViewData({
    required this.timestamp,
    required this.label,
    required this.amountMinor,
  });

  final int timestamp;
  final String label;
  final int amountMinor;
}

class DurableCostPointViewData {
  const DurableCostPointViewData({
    required this.startAt,
    required this.averageDailyCostMinor,
  });

  final int startAt;
  final int averageDailyCostMinor;
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

class SpendingBreakdownViewData {
  const SpendingBreakdownViewData({
    required this.label,
    required this.amountMinor,
    required this.ratio,
  });

  final String label;
  final int amountMinor;
  final double ratio;
}

enum PricingRange {
  all,
  last30Days,
  last90Days,
  custom;

  String get label => switch (this) {
        PricingRange.all => '全部',
        PricingRange.last30Days => '近 30 天',
        PricingRange.last90Days => '近 90 天',
        PricingRange.custom => '自定义',
      };
}

class RecentPriceRecordViewData {
  const RecentPriceRecordViewData({
    required this.recordId,
    required this.dateLabel,
    required this.priceLabel,
    required this.quantityLabel,
    required this.channelLabel,
  });

  final String recordId;
  final String dateLabel;
  final String priceLabel;
  final String quantityLabel;
  final String channelLabel;
}

class ChannelPriceViewData {
  const ChannelPriceViewData({
    required this.channelKey,
    required this.channelName,
    required this.recordCount,
    required this.lowestAmountMinor,
    required this.latestAmountMinor,
  });

  final String channelKey;
  final String channelName;
  final int recordCount;
  final int? lowestAmountMinor;
  final int? latestAmountMinor;
}

class PricingDateRange {
  const PricingDateRange({
    this.start,
    this.end,
  });

  final DateTime? start;
  final DateTime? end;

  PricingDateRange copyWith({
    DateTime? start,
    DateTime? end,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return PricingDateRange(
      start: clearStart ? null : (start ?? this.start),
      end: clearEnd ? null : (end ?? this.end),
    );
  }
}
