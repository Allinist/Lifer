import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';

class ProductNoteLinkViewData {
  const ProductNoteLinkViewData({
    required this.id,
    required this.productId,
    required this.productName,
    required this.title,
    required this.pathLabel,
    required this.notes,
  });

  final String id;
  final String productId;
  final String productName;
  final String title;
  final String pathLabel;
  final String? notes;
}

final notesSearchQueryProvider = StateProvider<String>((ref) => '');

final allProductNoteLinksProvider = FutureProvider<List<ProductNoteLinkViewData>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final links = await (db.select(db.productNoteLinks)
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
        ]))
      .get();

  final productIds = links.map((link) => link.productId).toSet();
  final productMap = <String, Product>{};
  for (final productId in productIds) {
    final product =
        await ((db.select(db.products))..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
    if (product != null) {
      productMap[productId] = product;
    }
  }

  return links
      .map(
        (link) => ProductNoteLinkViewData(
          id: link.id,
          productId: link.productId,
          productName: productMap[link.productId]?.name ?? '未知商品',
          title: link.title,
          pathLabel: link.obsidianPath ?? link.uri ?? '--',
          notes: link.notes,
        ),
      )
      .toList();
});

final filteredProductNoteLinksProvider = Provider<List<ProductNoteLinkViewData>>((ref) {
  final query = ref.watch(notesSearchQueryProvider).trim().toLowerCase();
  final items = ref.watch(allProductNoteLinksProvider).valueOrNull ?? const <ProductNoteLinkViewData>[];
  if (query.isEmpty) return items;

  return items.where((item) {
    final haystack = '${item.productName} ${item.title} ${item.pathLabel} ${item.notes ?? ''}'.toLowerCase();
    return haystack.contains(query);
  }).toList();
});

final notesObsidianSettingsProvider = FutureProvider<AppSetting?>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.appSettings)..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
});
