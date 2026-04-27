import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';

final rootCategoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogDaoProvider).getRootCategories();
});

final unitsProvider = FutureProvider<List<Unit>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.units)
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.symbol),
        ]))
      .get();
});

final activeProductsProvider = FutureProvider<List<Product>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.products)
        ..where((tbl) => tbl.isArchived.equals(false))
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.name),
        ]))
      .get();
});

final channelsProvider = FutureProvider<List<PurchaseChannel>>((ref) {
  return ref.watch(pricingDaoProvider).getChannels();
});
