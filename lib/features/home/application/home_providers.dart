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

    final latestBatch = await ((db.select(db.stockBatches))
          ..where((tbl) => tbl.productId.equals(product.id) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.expiryDate),
          ])
          ..limit(1))
        .getSingleOrNull();

    items.add(
      HomeProductCardData(
        productId: product.id,
        name: product.name,
        productType: product.productType,
        topLine: product.productType == 'consumable'
            ? '最近一次 ${Formatters.currencyFromMinor(latestPrice?.amountMinor)}'
            : '购买价格 ${Formatters.currencyFromMinor(latestPrice?.amountMinor)}',
        bottomLine: product.productType == 'consumable'
            ? '库存 ${Formatters.quantity(latestBatch?.remainingQuantity)} · 到期 ${Formatters.fullDateFromMillis(latestBatch?.expiryDate)}'
            : '购买时间 ${Formatters.fullDateFromMillis(latestPrice?.purchasedAt)}',
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
        subtitle: '紧急度 ${event.urgencyScore} · 到期/触发 ${Formatters.fullDateFromMillis(event.dueAt)}',
        urgencyScore: event.urgencyScore,
      ),
    );
  }

  return items;
});
