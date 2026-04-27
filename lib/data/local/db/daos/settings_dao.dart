import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/tables/app_tables.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings, ProductNoteLinks])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<AppSetting?> watchSettings() {
    return (select(appSettings)..where((tbl) => tbl.id.equals(1))).watchSingleOrNull();
  }

  Future<void> upsertSettings(AppSettingsCompanion entry) {
    return into(appSettings).insertOnConflictUpdate(entry);
  }

  Stream<List<ProductNoteLink>> watchProductNoteLinks(String productId) {
    return (select(productNoteLinks)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }
}
