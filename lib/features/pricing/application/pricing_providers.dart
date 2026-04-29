import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/pricing/application/pricing_models.dart';

final allProductsProvider = Provider<SelectableProducts>((ref) {
  return SelectableProducts(ref.watch(appDatabaseProvider));
});

final selectedPricingProductIdProvider = StateProvider<String?>((ref) => null);
final selectedPricingRangeProvider = StateProvider<PricingRange>((ref) => PricingRange.all);
final customPricingDateRangeProvider =
    StateProvider<PricingDateRange>((ref) => const PricingDateRange());
final selectedPricingChannelKeyProvider = StateProvider<String?>((ref) => null);

final selectedPricingProductProvider = FutureProvider<Product?>((ref) async {
  final productId = ref.watch(selectedPricingProductIdProvider);
  if (productId == null || productId.isEmpty) {
    return null;
  }

  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.products)..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
});

final selectedProductPriceRecordsProvider = StreamProvider<List<PriceRecord>>((ref) {
  final productId = ref.watch(selectedPricingProductIdProvider);
  if (productId == null || productId.isEmpty) {
    return const Stream.empty();
  }
  return ref.watch(pricingDaoProvider).watchProductPriceRecords(productId);
});

final selectedProductDurableUsageProvider = FutureProvider<List<DurableUsagePeriod>>((ref) async {
  final product = await ref.watch(selectedPricingProductProvider.future);
  if (product == null || product.productType != 'durable') return const <DurableUsagePeriod>[];
  final db = ref.watch(appDatabaseProvider);
  return ((db.select(db.durableUsagePeriods))
        ..where((tbl) => tbl.productId.equals(product.id))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.startAt, mode: OrderingMode.asc)]))
      .get();
});

final filteredPriceRecordsProvider = Provider<List<PriceRecord>>((ref) {
  final records =
      ref.watch(selectedProductPriceRecordsProvider).valueOrNull ?? const <PriceRecord>[];
  final range = ref.watch(selectedPricingRangeProvider);
  final selectedChannelKey = ref.watch(selectedPricingChannelKeyProvider);
  List<PriceRecord> scopedRecords = records;

  if (range == PricingRange.custom) {
    final customRange = ref.watch(customPricingDateRangeProvider);
    final startAt = customRange.start?.millisecondsSinceEpoch;
    final endAt = customRange.end?.millisecondsSinceEpoch;
    scopedRecords = records.where((record) {
      final afterStart = startAt == null || record.purchasedAt >= startAt;
      final beforeEnd = endAt == null || record.purchasedAt <= endAt;
      return afterStart && beforeEnd;
    }).toList();
  } else if (range != PricingRange.all) {
    final now = DateTime.now();
    final threshold = switch (range) {
      PricingRange.last30Days => now.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      PricingRange.last90Days => now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
      PricingRange.all => 0,
      PricingRange.custom => 0,
    };
    scopedRecords = records.where((record) => record.purchasedAt >= threshold).toList();
  }

  if (selectedChannelKey == null || selectedChannelKey.isEmpty) {
    return scopedRecords;
  }

  return scopedRecords.where((record) {
    final key = record.channelId ?? 'unassigned';
    return key == selectedChannelKey;
  }).toList();
});

final selectedProductPricePointsProvider = Provider<List<PricePointViewData>>((ref) {
  final product = ref.watch(selectedPricingProductProvider).valueOrNull;
  if (product?.productType == 'durable') {
    final periods = ref.watch(selectedProductDurableUsageProvider).valueOrNull ?? const <DurableUsagePeriod>[];
    final range = ref.watch(selectedPricingRangeProvider);
    final custom = ref.watch(customPricingDateRangeProvider);
    return _buildDurableCurvePoints(
      periods: periods,
      range: range,
      customRange: custom,
    );
  }
  final records = ref.watch(filteredPriceRecordsProvider);
  return records
      .take(12)
      .toList()
      .reversed
      .map(
        (record) => PricePointViewData(
          timestamp: record.purchasedAt,
          label: Formatters.shortDateFromMillis(record.purchasedAt),
          amountMinor: _priceValue(record, product),
        ),
      )
      .toList();
});

final selectedProductPriceStatsProvider = Provider<PriceStatsViewData>((ref) {
  final product = ref.watch(selectedPricingProductProvider).valueOrNull;
  if (product?.productType == 'durable') {
    final points = ref.watch(selectedProductPricePointsProvider);
    if (points.isEmpty) {
      return const PriceStatsViewData(
        recordCount: 0,
        latestAmountMinor: null,
        lowestAmountMinor: null,
        highestAmountMinor: null,
      );
    }
    final amounts = points.map((e) => e.amountMinor).toList();
    return PriceStatsViewData(
      recordCount: points.length,
      latestAmountMinor: points.last.amountMinor,
      lowestAmountMinor: amounts.reduce((a, b) => a < b ? a : b),
      highestAmountMinor: amounts.reduce((a, b) => a > b ? a : b),
    );
  }
  final records = ref.watch(filteredPriceRecordsProvider);
  if (records.isEmpty) {
    return const PriceStatsViewData(
      recordCount: 0,
      latestAmountMinor: null,
      lowestAmountMinor: null,
      highestAmountMinor: null,
    );
  }

  final amounts = records.map((record) => _priceValue(record, product)).toList();
  return PriceStatsViewData(
    recordCount: records.length,
    latestAmountMinor: _priceValue(records.first, product),
    lowestAmountMinor: amounts.reduce((a, b) => a < b ? a : b),
    highestAmountMinor: amounts.reduce((a, b) => a > b ? a : b),
  );
});

final recentPriceRecordItemsProvider = FutureProvider<List<RecentPriceRecordViewData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final records = ref.watch(filteredPriceRecordsProvider);
  if (records.isEmpty) return const <RecentPriceRecordViewData>[];

  final channelIds = records.map((record) => record.channelId).whereType<String>().toSet();
  final unitIds = records.map((record) => record.unitId).whereType<String>().toSet();

  final channelMap = <String, String>{};
  for (final channelId in channelIds) {
    final channel = await ((db.select(db.purchaseChannels))
          ..where((tbl) => tbl.id.equals(channelId)))
        .getSingleOrNull();
    if (channel != null) {
      channelMap[channelId] = channel.name;
    }
  }

  final unitMap = <String, String>{};
  for (final unitId in unitIds) {
    final unit = await ((db.select(db.units))..where((tbl) => tbl.id.equals(unitId))).getSingleOrNull();
    if (unit != null) {
      unitMap[unitId] = unit.symbol;
    }
  }

  final product = ref.watch(selectedPricingProductProvider).valueOrNull;
  return records.take(8).map((record) {
    final quantityLabel = record.quantity == null
        ? '--'
        : '${Formatters.quantity(record.quantity)} ${unitMap[record.unitId] ?? ''}'.trim();

    return RecentPriceRecordViewData(
      recordId: record.id,
      dateLabel: Formatters.fullDateFromMillis(record.purchasedAt),
      priceLabel: Formatters.currencyFromMinor(
        _priceValue(record, product),
        currencyCode: product?.currencyCode,
      ),
      quantityLabel: quantityLabel,
      channelLabel: channelMap[record.channelId] ?? '未设置渠道',
    );
  }).toList();
});

final channelPriceSummaryProvider = FutureProvider<List<ChannelPriceViewData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final productId = ref.watch(selectedPricingProductIdProvider);
  if (productId == null || productId.isEmpty) return const <ChannelPriceViewData>[];

  final records = ref.watch(filteredPriceRecordsProvider);
  if (records.isEmpty) return const <ChannelPriceViewData>[];

  final channelIds = records.map((record) => record.channelId).whereType<String>().toSet();
  final channelMap = <String, String>{};
  for (final channelId in channelIds) {
    final channel = await ((db.select(db.purchaseChannels))
          ..where((tbl) => tbl.id.equals(channelId)))
        .getSingleOrNull();
    if (channel != null) {
      channelMap[channelId] = channel.name;
    }
  }

  final grouped = <String, List<PriceRecord>>{};
  for (final record in records) {
    final key = record.channelId ?? 'unassigned';
    grouped.putIfAbsent(key, () => <PriceRecord>[]).add(record);
  }

  final product = ref.watch(selectedPricingProductProvider).valueOrNull;
  return grouped.entries.map((entry) {
    final amounts = entry.value.map((record) => _priceValue(record, product)).toList();
    return ChannelPriceViewData(
      channelKey: entry.key,
      channelName: entry.key == 'unassigned' ? '未设置渠道' : (channelMap[entry.key] ?? entry.key),
      recordCount: entry.value.length,
      lowestAmountMinor: amounts.reduce((a, b) => a < b ? a : b),
      latestAmountMinor: _priceValue(entry.value.first, product),
    );
  }).toList()
    ..sort((a, b) => a.channelName.compareTo(b.channelName));
});

final spendingBreakdownProvider = Provider<List<SpendingBreakdownViewData>>((ref) {
  final records = ref.watch(filteredPriceRecordsProvider);
  if (records.isEmpty) return const <SpendingBreakdownViewData>[];

  final grouped = <String, int>{};
  for (final record in records) {
    final date = DateTime.fromMillisecondsSinceEpoch(record.purchasedAt);
    final label = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final pv = _priceValue(record, ref.watch(selectedPricingProductProvider).valueOrNull);
    grouped.update(label, (value) => value + pv, ifAbsent: () => pv);
  }

  final total = grouped.values.fold<int>(0, (sum, amount) => sum + amount);
  final sorted = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  final recent = sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;

  return recent
      .map(
        (entry) => SpendingBreakdownViewData(
          label: entry.key,
          amountMinor: entry.value,
          ratio: total == 0 ? 0 : entry.value / total,
        ),
      )
      .toList()
      .reversed
      .toList();
});

class SelectableProducts {
  SelectableProducts(this._db);

  final AppDatabase _db;

  Future<List<Product>> load() async {
    return (_db.select(_db.products)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.name),
          ]))
        .get();
  }
}

String _consumablePriceMode(Product? product) {
  if (product == null || product.productType != 'consumable') return 'total';
  final raw = product.metadataJson;
  if (raw == null || raw.trim().isEmpty) return 'total';
  final json = jsonDecode(raw);
  if (json is Map<String, dynamic>) {
    return (json['consumablePriceMode'] as String?) ?? 'total';
  }
  return 'total';
}

int _priceValue(PriceRecord record, Product? product) {
  final mode = _consumablePriceMode(product);
  if (mode == 'unit' && record.unitPriceMinor != null) return record.unitPriceMinor!;
  return record.amountMinor;
}

int? _durableDailyCostMinor(DurableUsagePeriod p) {
  if (p.averageDailyCostMinor != null && p.averageDailyCostMinor! > 0) {
    return p.averageDailyCostMinor!;
  }
  final price = p.purchasePriceMinor;
  if (price == null || price <= 0) return null;
  final end = p.endAt ?? DateTime.now().millisecondsSinceEpoch;
  final days = ((end - p.startAt) / Duration.millisecondsPerDay).ceil();
  final safeDays = days <= 0 ? 1 : days;
  return (price / safeDays).round();
}

List<PricePointViewData> _buildDurableCurvePoints({
  required List<DurableUsagePeriod> periods,
  required PricingRange range,
  required PricingDateRange customRange,
}) {
  if (periods.isEmpty) return const <PricePointViewData>[];
  final now = DateTime.now().millisecondsSinceEpoch;
  final earliestStart = periods.map((e) => e.startAt).reduce((a, b) => a < b ? a : b);
  final rangeStart = switch (range) {
    PricingRange.last30Days => now - const Duration(days: 30).inMilliseconds,
    PricingRange.last90Days => now - const Duration(days: 90).inMilliseconds,
    PricingRange.custom => customRange.start?.millisecondsSinceEpoch ?? earliestStart,
    PricingRange.all => earliestStart,
  };
  final rangeEnd = switch (range) {
    PricingRange.custom => customRange.end?.millisecondsSinceEpoch ?? now,
    _ => now,
  };
  if (rangeEnd <= rangeStart) return const <PricePointViewData>[];

  const maxPoints = 16;
  final span = rangeEnd - rangeStart;
  final step = (span / (maxPoints - 1)).floor();
  final points = <PricePointViewData>[];
  for (var i = 0; i < maxPoints; i++) {
    final t = i == maxPoints - 1 ? rangeEnd : (rangeStart + step * i);
    final value = _durableDailyCostAt(periods: periods, timestamp: t);
    if (value == null) continue;
    points.add(
      PricePointViewData(
        timestamp: t,
        label: Formatters.shortDateFromMillis(t),
        amountMinor: value,
      ),
    );
  }
  return points;
}

int? _durableDailyCostAt({
  required List<DurableUsagePeriod> periods,
  required int timestamp,
}) {
  DurableUsagePeriod? current;
  for (final p in periods) {
    final ended = p.endAt != null && p.endAt! < timestamp;
    if (p.startAt > timestamp || ended) continue;
    if (current == null || p.startAt > current.startAt) {
      current = p;
    }
  }
  if (current == null) return null;
  final price = current.purchasePriceMinor;
  if (price == null || price <= 0) return null;
  final effectiveEnd = current.endAt == null
      ? timestamp
      : (timestamp < current.endAt! ? timestamp : current.endAt!);
  final days = ((effectiveEnd - current.startAt) / Duration.millisecondsPerDay).ceil();
  final safeDays = days <= 0 ? 1 : days;
  return (price / safeDays).round();
}


