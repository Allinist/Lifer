import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/db_write_helper.dart';
import 'package:uuid/uuid.dart';

final productActionsProvider = Provider<ProductActions>((ref) {
  return ProductActions(ref.watch(appDatabaseProvider));
});

class ProductActions {
  ProductActions(this._db)
      : _helper = DbWriteHelper(_db),
        _uuid = const Uuid();

  final AppDatabase _db;
  final DbWriteHelper _helper;
  final Uuid _uuid;

  Future<String> createProduct({
    required String name,
    required String alias,
    required String productType,
    required String categoryName,
    required String brand,
    required String unitSymbol,
    required String targetPrice,
    required String shelfLifeDays,
    required bool isPinnedHome,
    required String notes,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw StateError('商品名称不能为空');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoryId = await _helper.ensureRootCategory(categoryName);
    final unitId = await _helper.ensureUnit(unitSymbol);
    await _ensureNoDuplicateName(
      categoryId: categoryId,
      productName: normalizedName,
    );

    final productId = _uuid.v4();
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: productId,
            categoryId: categoryId,
            name: normalizedName,
            alias: Value(alias.trim().isEmpty ? null : alias.trim()),
            productType: productType,
            unitId: Value(unitId),
            brand: Value(brand.trim().isEmpty ? null : brand.trim()),
            expectedPriceMinor: Value(_parseMoney(targetPrice)),
            defaultShelfLifeDays: Value(_parseInt(shelfLifeDays)),
            isPinnedHome: Value(isPinnedHome),
            notes: Value(notes.trim().isEmpty ? null : notes.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return productId;
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String alias,
    required String productType,
    required String categoryName,
    required String brand,
    required String unitSymbol,
    required String targetPrice,
    required String shelfLifeDays,
    required bool isPinnedHome,
    required String notes,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw StateError('商品名称不能为空');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoryId = await _helper.ensureRootCategory(categoryName);
    final unitId = await _helper.ensureUnit(unitSymbol);
    await _ensureNoDuplicateName(
      categoryId: categoryId,
      productName: normalizedName,
      exceptProductId: productId,
    );

    await ((_db.update(_db.products))..where((tbl) => tbl.id.equals(productId))).write(
          ProductsCompanion(
            categoryId: Value(categoryId),
            name: Value(normalizedName),
            alias: Value(alias.trim().isEmpty ? null : alias.trim()),
            productType: Value(productType),
            unitId: Value(unitId),
            brand: Value(brand.trim().isEmpty ? null : brand.trim()),
            expectedPriceMinor: Value(_parseMoney(targetPrice)),
            defaultShelfLifeDays: Value(_parseInt(shelfLifeDays)),
            isPinnedHome: Value(isPinnedHome),
            notes: Value(notes.trim().isEmpty ? null : notes.trim()),
            updatedAt: Value(now),
          ),
        );
  }

  int? _parseMoney(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return null;
    return (value * 100).round();
  }

  int? _parseInt(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  Future<void> _ensureNoDuplicateName({
    required String categoryId,
    required String productName,
    String? exceptProductId,
  }) async {
    final duplicate = await ((_db.select(_db.products))
          ..where((tbl) => tbl.categoryId.equals(categoryId) & tbl.name.equals(productName))
          ..limit(1))
        .getSingleOrNull();
    if (duplicate == null) return;
    if (exceptProductId != null && duplicate.id == exceptProductId) return;
    throw StateError('同分类下已存在同名商品：$productName');
  }
}
