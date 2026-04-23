import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(
  tables: [
    Products,
    Units,
    StockBatches,
    StockBatchLocations,
    StorageLocations,
    RestockRecords,
    ConsumptionRecords,
    DurableUsagePeriods,
  ],
)
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  Stream<List<StockBatch>> watchActiveBatchesForProduct(String productId) {
    return (select(stockBatches)
          ..where(
            (tbl) =>
                tbl.productId.equals(productId) &
                tbl.isArchived.equals(false) &
                tbl.remainingQuantity.isBiggerThanValue(0),
          )
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.expiryDate),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ]))
        .watch();
  }

  Stream<List<ConsumptionRecord>> watchConsumptionRecords(String productId) {
    return (select(consumptionRecords)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.occurredAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Stream<List<DurableUsagePeriod>> watchDurableUsagePeriods(String productId) {
    return (select(durableUsagePeriods)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.startAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<void> createRestockBundle({
    required PriceRecordsCompanion priceEntry,
    required StockBatchesCompanion batchEntry,
    required RestockRecordsCompanion restockEntry,
  }) {
    return transaction(() async {
      await into(priceRecords).insertOnConflictUpdate(priceEntry);
      await into(stockBatches).insertOnConflictUpdate(batchEntry);
      await into(restockRecords).insertOnConflictUpdate(restockEntry);
    });
  }

  Future<void> recordConsumption({
    required ConsumptionRecordsCompanion consumptionEntry,
    String? batchId,
    required double nextRemainingQuantity,
  }) {
    return transaction(() async {
      await into(consumptionRecords).insertOnConflictUpdate(consumptionEntry);
      if (batchId != null && batchId.isNotEmpty) {
        await (update(stockBatches)..where((tbl) => tbl.id.equals(batchId))).write(
          StockBatchesCompanion(
            remainingQuantity: Value(nextRemainingQuantity),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
    });
  }

  Future<void> upsertUsagePeriod(DurableUsagePeriodsCompanion entry) {
    return into(durableUsagePeriods).insertOnConflictUpdate(entry);
  }
}
