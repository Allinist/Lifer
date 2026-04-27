import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/tables/app_tables.dart';

part 'pricing_dao.g.dart';

@DriftAccessor(tables: [Products, PriceRecords, PurchaseChannels])
class PricingDao extends DatabaseAccessor<AppDatabase> with _$PricingDaoMixin {
  PricingDao(super.db);

  Stream<List<PriceRecord>> watchProductPriceRecords(String productId) {
    return (select(priceRecords)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.purchasedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<List<PriceRecord>> getPriceRecordsInRange({
    required String productId,
    required int startAt,
    required int endAt,
  }) {
    return (select(priceRecords)
          ..where(
            (tbl) =>
                tbl.productId.equals(productId) &
                tbl.purchasedAt.isBiggerOrEqualValue(startAt) &
                tbl.purchasedAt.isSmallerOrEqualValue(endAt),
          )
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.purchasedAt),
          ]))
        .get();
  }

  Future<void> upsertPriceRecord(PriceRecordsCompanion entry) {
    return into(priceRecords).insertOnConflictUpdate(entry);
  }

  Future<void> updatePriceRecord({
    required String recordId,
    required int amountMinor,
    required int purchasedAt,
    double? quantity,
    String? channelId,
    String? unitId,
  }) {
    return (update(priceRecords)..where((tbl) => tbl.id.equals(recordId))).write(
      PriceRecordsCompanion(
        amountMinor: Value(amountMinor),
        purchasedAt: Value(purchasedAt),
        quantity: Value(quantity),
        channelId: Value(channelId),
        unitId: Value(unitId),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<PurchaseChannel>> getChannels() {
    return (select(purchaseChannels)
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.name),
          ]))
        .get();
  }
}
