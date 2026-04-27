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
  final records = ref.watch(filteredPriceRecordsProvider);
  return records
      .take(6)
      .toList()
      .reversed
      .map(
        (record) => PricePointViewData(
          label: Formatters.shortDateFromMillis(record.purchasedAt),
          amountMinor: record.amountMinor,
        ),
      )
      .toList();
});

final selectedProductPriceStatsProvider = Provider<PriceStatsViewData>((ref) {
  final records = ref.watch(filteredPriceRecordsProvider);
  if (records.isEmpty) {
    return const PriceStatsViewData(
      recordCount: 0,
      latestAmountMinor: null,
      lowestAmountMinor: null,
      highestAmountMinor: null,
    );
  }

  final amounts = records.map((record) => record.amountMinor).toList();
  return PriceStatsViewData(
    recordCount: records.length,
    latestAmountMinor: records.first.amountMinor,
    lowestAmountMinor: amounts.reduce((a, b) => a < b ? a : b),
    highestAmountMinor: amounts.reduce((a, b) => a > b ? a : b),
  );
});

final recentPriceRecordItemsProvider =
    FutureProvider<List<RecentPriceRecordViewData>>((ref) async {
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
    final unit = await ((db.select(db.units))..where((tbl) => tbl.id.equals(unitId)))
        .getSingleOrNull();
    if (unit != null) {
      unitMap[unitId] = unit.symbol;
    }
  }

  return records.take(8).map((record) {
    final quantityLabel = record.quantity == null
        ? '--'
        : '${Formatters.quantity(record.quantity)} ${unitMap[record.unitId] ?? ''}'.trim();

    return RecentPriceRecordViewData(
      recordId: record.id,
      dateLabel: Formatters.fullDateFromMillis(record.purchasedAt),
      priceLabel: Formatters.currencyFromMinor(record.amountMinor),
      quantityLabel: quantityLabel,
      channelLabel: channelMap[record.channelId] ?? '未设置渠道',
    );
  }).toList();
});

final channelPriceSummaryProvider = FutureProvider<List<ChannelPriceViewData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final productId = ref.watch(selectedPricingProductIdProvider);
  if (productId == null || productId.isEmpty) return const <ChannelPriceViewData>[];

  final range = ref.watch(selectedPricingRangeProvider);
  final customRange = ref.watch(customPricingDateRangeProvider);
  final records =
      ref.watch(selectedProductPriceRecordsProvider).valueOrNull ?? const <PriceRecord>[];

  final scopedRecords = records.where((record) {
    if (range == PricingRange.all) return true;
    if (range == PricingRange.custom) {
      final startAt = customRange.start?.millisecondsSinceEpoch;
      final endAt = customRange.end?.millisecondsSinceEpoch;
      final afterStart = startAt == null || record.purchasedAt >= startAt;
      final beforeEnd = endAt == null || record.purchasedAt <= endAt;
      return afterStart && beforeEnd;
    }

    final threshold = switch (range) {
      PricingRange.last30Days => DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      PricingRange.last90Days => DateTime.now()
          .subtract(const Duration(days: 90))
          .millisecondsSinceEpoch,
      PricingRange.all => 0,
      PricingRange.custom => 0,
    };
    return record.purchasedAt >= threshold;
  }).toList();

  if (scopedRecords.isEmpty) return const <ChannelPriceViewData>[];

  final channelIds = scopedRecords.map((record) => record.channelId).whereType<String>().toSet();
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
  for (final record in scopedRecords) {
    final key = record.channelId ?? 'unassigned';
    grouped.putIfAbsent(key, () => <PriceRecord>[]).add(record);
  }

  return grouped.entries.map((entry) {
    final amounts = entry.value.map((record) => record.amountMinor).toList();
    return ChannelPriceViewData(
      channelKey: entry.key,
      channelName: entry.key == 'unassigned'
          ? '未设置渠道'
          : (channelMap[entry.key] ?? entry.key),
      recordCount: entry.value.length,
      lowestAmountMinor: amounts.isEmpty ? null : amounts.reduce((a, b) => a < b ? a : b),
      latestAmountMinor: entry.value.first.amountMinor,
    );
  }).toList()
    ..sort((a, b) => a.channelName.compareTo(b.channelName));
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
