import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';

part 'catalog_dao.g.dart';

@DriftAccessor(tables: [Categories, Products, Units])
class CatalogDao extends DatabaseAccessor<AppDatabase> with _$CatalogDaoMixin {
  CatalogDao(super.db);

  Future<List<Category>> getRootCategories() {
    return (select(categories)
          ..where((tbl) => tbl.parentId.isNull() & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.sortOrder),
            (tbl) => OrderingTerm(expression: tbl.name),
          ]))
        .get();
  }

  Stream<List<Product>> watchPinnedProducts() {
    return (select(products)
          ..where((tbl) => tbl.isPinnedHome.equals(true) & tbl.isArchived.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.homeSortOrder),
            (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> upsertProduct(ProductsCompanion entry) {
    return into(products).insertOnConflictUpdate(entry);
  }
}
