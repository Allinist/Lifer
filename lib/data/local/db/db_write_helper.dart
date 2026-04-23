import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:uuid/uuid.dart';

class DbWriteHelper {
  DbWriteHelper(this.db) : _uuid = const Uuid();

  final AppDatabase db;
  final Uuid _uuid;

  Future<String> ensureRootCategory(String rawName) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final name = rawName.trim().isEmpty ? '未分类' : rawName.trim();

    final existing = await (db.select(db.categories)
          ..where((tbl) => tbl.parentId.isNull() & tbl.name.equals(name))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    final id = _uuid.v4();
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: id,
            parentId: const Value(null),
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<String> ensureUnit(String rawSymbol) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final symbol = rawSymbol.trim().isEmpty ? '件' : rawSymbol.trim();

    final existing = await (db.select(db.units)
          ..where((tbl) => tbl.symbol.equals(symbol))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    final id = _uuid.v4();
    await db.into(db.units).insert(
          UnitsCompanion.insert(
            id: id,
            name: symbol,
            symbol: symbol,
            unitType: 'count',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<String> ensureProduct({
    required String productName,
    required String categoryName,
    required String unitSymbol,
    required String productType,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final name = productName.trim();
    final existing = await (db.select(db.products)
          ..where((tbl) => tbl.name.equals(name))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    final categoryId = await ensureRootCategory(categoryName);
    final unitId = await ensureUnit(unitSymbol);
    final id = _uuid.v4();

    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: id,
            categoryId: categoryId,
            name: name,
            productType: productType,
            unitId: Value(unitId),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }
}
