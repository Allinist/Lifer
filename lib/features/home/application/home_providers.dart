import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/home/application/home_models.dart';

final pinnedProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(catalogDaoProvider).watchPinnedProducts();
});

final activeReminderEventsProvider = StreamProvider<List<ReminderEvent>>((ref) {
  return ref.watch(reminderDaoProvider).watchActiveReminderEvents();
});

final homePinnedCardProvider = FutureProvider<List<HomeProductCardData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final products = await ref.watch(catalogDaoProvider).watchPinnedProducts().first;

  final items = <HomeProductCardData>[];
  for (final product in products) {
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

    final remainingQuantity = batches.fold<double>(0, (sum, batch) => sum + batch.remainingQuantity);
    int? nearestExpiry;
    for (final batch in batches) {
      final expiry = batch.expiryDate;
      if (expiry == null) continue;
      if (nearestExpiry == null || expiry < nearestExpiry) {
        nearestExpiry = expiry;
      }
    }

    items.add(
      HomeProductCardData(
        productId: product.id,
        name: product.name,
        productType: product.productType,
        topLine: product.productType == 'consumable'
            ? '最近价格 ${Formatters.currencyFromMinor(latestPrice?.amountMinor)}'
            : '购入价格 ${Formatters.currencyFromMinor(latestPrice?.amountMinor)}',
        bottomLine: product.productType == 'consumable'
            ? '库存 ${Formatters.quantity(remainingQuantity)} · 最近到期 ${Formatters.fullDateFromMillis(nearestExpiry)}'
            : '最近购入 ${Formatters.fullDateFromMillis(latestPrice?.purchasedAt)}',
      ),
    );
  }
  return items;
});

final homeReminderCardProvider = FutureProvider<List<ReminderCardData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final events = await ref.watch(reminderDaoProvider).watchActiveReminderEvents().first;
  final items = <ReminderCardData>[];

  for (final event in events) {
    final product = await ((db.select(db.products))..where((tbl) => tbl.id.equals(event.productId)))
        .getSingleOrNull();
    items.add(
      ReminderCardData(
        productId: event.productId,
        title: product?.name ?? event.eventType,
        subtitle: '紧急度 ${event.urgencyScore} · 触发时间 ${Formatters.fullDateFromMillis(event.dueAt)}',
        urgencyScore: event.urgencyScore,
      ),
    );
  }

  return items;
});

final homeOtherProductGroupsProvider = FutureProvider<List<OtherProductGroupData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final products = await ((db.select(db.products))
        ..where((tbl) => tbl.isArchived.equals(false) & tbl.isPinnedHome.equals(false))
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.productType),
          (tbl) => OrderingTerm(expression: tbl.name),
        ]))
      .get();

  if (products.isEmpty) {
    return const <OtherProductGroupData>[];
  }

  final categoryIds = products.map((product) => product.categoryId).toSet();
  final categoryMap = <String, String>{};
  for (final categoryId in categoryIds) {
    final category =
        await ((db.select(db.categories))..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();
    if (category != null) {
      categoryMap[categoryId] = category.name;
    }
  }

  final counts = <String, int>{};
  for (final product in products) {
    final typeLabel = product.productType == 'consumable' ? '消耗品' : '常驻品';
    final categoryLabel = categoryMap[product.categoryId] ?? '未分类';
    final key = '$typeLabel · $categoryLabel';
    counts.update(key, (value) => value + 1, ifAbsent: () => 1);
  }

  return counts.entries
      .map((entry) => OtherProductGroupData(title: entry.key, itemCount: entry.value))
      .toList()
    ..sort((a, b) => b.itemCount.compareTo(a.itemCount));
});
