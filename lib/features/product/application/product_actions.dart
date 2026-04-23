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

  Future<void> createProduct({
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
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoryId = await _helper.ensureRootCategory(categoryName);
    final unitId = await _helper.ensureUnit(unitSymbol);

    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            name: name.trim(),
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
}
