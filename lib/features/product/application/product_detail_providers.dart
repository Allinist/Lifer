import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/features/product/application/product_detail_models.dart';

final productDetailProvider =
    FutureProvider.family<ProductDetailViewData?, String>((ref, productId) async {
  final db = ref.watch(appDatabaseProvider);

  final product = await ((db.select(db.products))..where((tbl) => tbl.id.equals(productId)))
      .getSingleOrNull();
  if (product == null) {
    return null;
  }

  final category = await ((db.select(db.categories))
        ..where((tbl) => tbl.id.equals(product.categoryId)))
      .getSingleOrNull();

  final latestPrice = await ((db.select(db.priceRecords))
        ..where((tbl) => tbl.productId.equals(product.id))
        ..orderBy([
          (tbl) => OrderingTerm(
                expression: tbl.purchasedAt,
                mode: OrderingMode.desc,
              ),
        ])
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
    if (nearestExpiry == null || expiry < nearestExpiry) {
      nearestExpiry = expiry;
    }
  }

  return ProductDetailViewData(
    productId: product.id,
    name: product.name,
    productTypeLabel: product.productType == 'consumable' ? '消耗品' : '常驻品',
    categoryLabel: category?.name ?? '未分类',
    latestPriceLabel: Formatters.currencyFromMinor(latestPrice?.amountMinor),
    stockLabel: Formatters.quantity(totalRemaining),
    expiryLabel: Formatters.fullDateFromMillis(nearestExpiry),
  );
});
