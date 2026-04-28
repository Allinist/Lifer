import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/tables/app_tables.dart';

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

  Future<void> recordConsumptionAllocations({
    required List<ConsumptionRecordsCompanion> consumptionEntries,
    required Map<String, double> batchRemainingById,
  }) {
    return transaction(() async {
      for (final entry in consumptionEntries) {
        await into(consumptionRecords).insertOnConflictUpdate(entry);
      }
      for (final item in batchRemainingById.entries) {
        await (update(stockBatches)..where((tbl) => tbl.id.equals(item.key))).write(
          StockBatchesCompanion(
            remainingQuantity: Value(item.value),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
    });
  }

  Future<void> updateStockBatch({
    required String batchId,
    required StockBatchesCompanion batchEntry,
    String? sourcePriceRecordId,
    PriceRecordsCompanion? sourcePriceRecordEntry,
  }) {
    return transaction(() async {
      await (update(stockBatches)..where((tbl) => tbl.id.equals(batchId))).write(
        batchEntry.copyWith(
          sourcePriceRecordId: sourcePriceRecordId == null
              ? const Value.absent()
              : Value(sourcePriceRecordId.isEmpty ? null : sourcePriceRecordId),
        ),
      );
      if (sourcePriceRecordId != null &&
          sourcePriceRecordId.isNotEmpty &&
          sourcePriceRecordEntry != null) {
        await (update(priceRecords)..where((tbl) => tbl.id.equals(sourcePriceRecordId))).write(
          sourcePriceRecordEntry,
        );
      }
    });
  }

  Future<void> updateConsumptionRecord({
    required String consumptionId,
    required ConsumptionRecordsCompanion consumptionEntry,
    String? batchId,
    double? nextRemainingQuantity,
    String? previousBatchId,
    double? previousRemainingQuantity,
  }) {
    return transaction(() async {
      await (update(consumptionRecords)..where((tbl) => tbl.id.equals(consumptionId))).write(
        consumptionEntry,
      );
      if (previousBatchId != null &&
          previousBatchId.isNotEmpty &&
          previousRemainingQuantity != null) {
        await (update(stockBatches)..where((tbl) => tbl.id.equals(previousBatchId))).write(
          StockBatchesCompanion(
            remainingQuantity: Value(previousRemainingQuantity),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
      if (batchId != null && batchId.isNotEmpty && nextRemainingQuantity != null) {
        await (update(stockBatches)..where((tbl) => tbl.id.equals(batchId))).write(
          StockBatchesCompanion(
            remainingQuantity: Value(nextRemainingQuantity),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
    });
  }

  Future<void> replaceConsumptionWithAllocations({
    required String consumptionId,
    required ConsumptionRecordsCompanion updatedPrimaryEntry,
    required List<ConsumptionRecordsCompanion> extraEntries,
    required String? previousBatchId,
    required double? previousRemainingQuantity,
    required Map<String, double> batchRemainingById,
  }) {
    return transaction(() async {
      await (update(consumptionRecords)..where((tbl) => tbl.id.equals(consumptionId))).write(
        updatedPrimaryEntry,
      );
      if (extraEntries.isNotEmpty) {
        for (final entry in extraEntries) {
          await into(consumptionRecords).insertOnConflictUpdate(entry);
        }
      }
      if (previousBatchId != null &&
          previousBatchId.isNotEmpty &&
          previousRemainingQuantity != null &&
          !batchRemainingById.containsKey(previousBatchId)) {
        await (update(stockBatches)..where((tbl) => tbl.id.equals(previousBatchId))).write(
          StockBatchesCompanion(
            remainingQuantity: Value(previousRemainingQuantity),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
      for (final item in batchRemainingById.entries) {
        await (update(stockBatches)..where((tbl) => tbl.id.equals(item.key))).write(
          StockBatchesCompanion(
            remainingQuantity: Value(item.value),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }
    });
  }

  Future<void> archiveStockBatch(String batchId) {
    return (update(stockBatches)..where((tbl) => tbl.id.equals(batchId))).write(
      StockBatchesCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> deleteConsumptionRecord({
    required String consumptionId,
    String? batchId,
    double? restoredRemainingQuantity,
  }) {
    return transaction(() async {
      await (delete(consumptionRecords)..where((tbl) => tbl.id.equals(consumptionId))).go();
      if (batchId != null && batchId.isNotEmpty && restoredRemainingQuantity != null) {
        await (update(stockBatches)..where((tbl) => tbl.id.equals(batchId))).write(
          StockBatchesCompanion(
            remainingQuantity: Value(restoredRemainingQuantity),
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
