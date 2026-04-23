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

final selectedProductPricePointsProvider = Provider<List<PricePointViewData>>((ref) {
  final records = ref.watch(selectedProductPriceRecordsProvider).valueOrNull ?? const <PriceRecord>[];
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
  final records = ref.watch(selectedProductPriceRecordsProvider).valueOrNull ?? const <PriceRecord>[];
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
