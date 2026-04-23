import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/inventory/application/inventory_models.dart';

final inventoryProductsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.products)
        ..where((tbl) => tbl.isArchived.equals(false))
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
        ]))
      .watch();
});

final selectedInventoryProductIdProvider = StateProvider<String?>((ref) => null);

final selectedInventoryBatchesProvider = StreamProvider<List<StockBatch>>((ref) {
  final productId = ref.watch(selectedInventoryProductIdProvider);
  if (productId == null || productId.isEmpty) {
    return const Stream.empty();
  }
  return ref.watch(inventoryDaoProvider).watchActiveBatchesForProduct(productId);
});

final selectedInventoryUsageProvider = StreamProvider<List<DurableUsagePeriod>>((ref) {
  final productId = ref.watch(selectedInventoryProductIdProvider);
  if (productId == null || productId.isEmpty) {
    return const Stream.empty();
  }
  return ref.watch(inventoryDaoProvider).watchDurableUsagePeriods(productId);
});

final selectedInventoryBatchCardsProvider = Provider<List<InventoryBatchViewData>>((ref) {
  final batches = ref.watch(selectedInventoryBatchesProvider).valueOrNull ?? const <StockBatch>[];
  return batches
      .map(
        (batch) => InventoryBatchViewData(
          title: batch.batchLabel ?? '批次 ${batch.id.substring(0, 6)}',
          summary:
              '剩余 ${Formatters.quantity(batch.remainingQuantity)} / ${Formatters.quantity(batch.totalQuantity)} · 到期 ${Formatters.fullDateFromMillis(batch.expiryDate)}',
          metric: '购买 ${Formatters.fullDateFromMillis(batch.purchasedAt)}',
        ),
      )
      .toList();
});

final selectedInventoryUsageCardsProvider = Provider<List<DurableUsageViewData>>((ref) {
  final periods = ref.watch(selectedInventoryUsageProvider).valueOrNull ?? const <DurableUsagePeriod>[];
  return periods
      .map(
        (period) => DurableUsageViewData(
          title: '使用周期',
          summary:
              '开始 ${Formatters.fullDateFromMillis(period.startAt)} · 结束 ${Formatters.fullDateFromMillis(period.endAt)}',
          metric: '日均 ${Formatters.currencyFromMinor(period.averageDailyCostMinor)}',
        ),
      )
      .toList();
});
