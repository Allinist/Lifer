import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/product/application/product_detail_models.dart';

final productDetailProvider = StreamProvider.family<ProductDetailViewData?, String>((ref, productId) async* {
  final db = ref.watch(appDatabaseProvider);
  final productStream = (db.select(db.products)..where((tbl) => tbl.id.equals(productId))).watchSingleOrNull();
  await for (final product in productStream) {
    if (product == null) {
      yield null;
      continue;
    }
    final category = await ((db.select(db.categories))..where((tbl) => tbl.id.equals(product.categoryId))).getSingleOrNull();
    final latestPrice = await ((db.select(db.priceRecords))
          ..where((tbl) => tbl.productId.equals(product.id))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.purchasedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
    final batches = await ((db.select(db.stockBatches))
          ..where((tbl) => tbl.productId.equals(product.id) & tbl.isArchived.equals(false)))
        .get();
    final totalRemaining = batches.fold<double>(0, (sum, batch) => sum + batch.remainingQuantity);
    int? nearestExpiry;
    for (final batch in batches) {
      final expiry = batch.expiryDate;
      if (expiry == null) continue;
      if (nearestExpiry == null || expiry < nearestExpiry) nearestExpiry = expiry;
    }
    yield ProductDetailViewData(
      productId: product.id,
      name: product.name,
      productTypeLabel: product.productType == 'consumable'
          ? '消耗品'
          : (product.productType == 'pricing_only' ? '计价品' : '常驻品'),
      categoryLabel: category?.name ?? '未分类',
      latestPriceLabel: Formatters.currencyFromMinor(latestPrice?.amountMinor, currencyCode: product.currencyCode),
      stockLabel: Formatters.quantity(totalRemaining),
      expiryLabel: nearestExpiry == null ? '无' : Formatters.fullDateFromMillis(nearestExpiry),
    );
  }
});

final productProvider = StreamProvider.family<Product?, String>((ref, productId) {
  final db = ref.watch(appDatabaseProvider);
  return ((db.select(db.products))..where((tbl) => tbl.id.equals(productId))).watchSingleOrNull();
});

final productRecentPricesProvider = StreamProvider.family<List<ProductRecentPriceViewData>, String>((ref, productId) async* {
  final db = ref.watch(appDatabaseProvider);
  final recordsStream = (db.select(db.priceRecords)
        ..where((tbl) => tbl.productId.equals(productId))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.purchasedAt, mode: OrderingMode.desc)])
        ..limit(5))
      .watch();
  await for (final records in recordsStream) {
    final product = await ((db.select(db.products))..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
    final channelIds = records.map((item) => item.channelId).whereType<String>().toSet();
    final unitIds = records.map((item) => item.unitId).whereType<String>().toSet();
    final channelMap = <String, String>{};
    final unitMap = <String, String>{};
    for (final channelId in channelIds) {
      final channel = await ((db.select(db.purchaseChannels))..where((tbl) => tbl.id.equals(channelId))).getSingleOrNull();
      if (channel != null) channelMap[channelId] = channel.name;
    }
    for (final unitId in unitIds) {
      final unit = await ((db.select(db.units))..where((tbl) => tbl.id.equals(unitId))).getSingleOrNull();
      if (unit != null) unitMap[unitId] = unit.symbol;
    }
    yield records
        .map(
          (record) => ProductRecentPriceViewData(
            recordId: record.id,
            dateLabel: Formatters.fullDateFromMillis(record.purchasedAt),
            priceLabel: Formatters.currencyFromMinor(record.amountMinor, currencyCode: product?.currencyCode),
            quantityLabel: record.quantity == null ? '--' : '${Formatters.quantity(record.quantity)} ${unitMap[record.unitId] ?? ''}'.trim(),
            channelLabel: channelMap[record.channelId] ?? '未设置渠道',
          ),
        )
        .toList();
  }
});

final productBatchesProvider = StreamProvider.family<List<StockBatch>, String>((ref, productId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.stockBatches)
        ..where((tbl) => tbl.productId.equals(productId) & tbl.isArchived.equals(false))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.expiryDate)])
        ..limit(5))
      .watch();
});

final productReminderRulesProvider = StreamProvider.family<List<ReminderRule>, String>((ref, productId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.reminderRules)
        ..where((tbl) => tbl.productId.equals(productId))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.priority, mode: OrderingMode.desc)])
        ..limit(5))
      .watch();
});

final productActiveReminderEventsProvider = StreamProvider.family<List<ReminderEvent>, String>((ref, productId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.reminderEvents)
        ..where((tbl) => tbl.productId.equals(productId) & tbl.isResolved.equals(false))
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.urgencyScore, mode: OrderingMode.desc),
          (tbl) => OrderingTerm(expression: tbl.dueAt),
        ])
        ..limit(5))
      .watch();
});

final productConsumptionRecordsProvider = StreamProvider.family<List<ConsumptionRecord>, String>((ref, productId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.consumptionRecords)
        ..where((tbl) => tbl.productId.equals(productId))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.occurredAt, mode: OrderingMode.desc)])
        ..limit(5))
      .watch();
});

final productNoteLinksProvider = StreamProvider.family<List<ProductNoteLink>, String>((ref, productId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.productNoteLinks)
        ..where((tbl) => tbl.productId.equals(productId))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc)])
        ..limit(5))
      .watch();
});

