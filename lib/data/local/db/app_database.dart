import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/catalog_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/pricing_dao.dart';
import 'daos/reminder_dao.dart';
import 'daos/settings_dao.dart';
import 'tables/app_tables.dart';

export 'daos/catalog_dao.dart';
export 'daos/inventory_dao.dart';
export 'daos/pricing_dao.dart';
export 'daos/reminder_dao.dart';
export 'daos/settings_dao.dart';

part 'app_database.g.dart';

typedef StockBatch = StockBatche;

@DriftDatabase(
  tables: [
    Categories,
    Units,
    Products,
    PurchaseChannels,
    PriceRecords,
    StorageLocations,
    StockBatches,
    StockBatchLocations,
    RestockRecords,
    ConsumptionRecords,
    DurableUsagePeriods,
    ReminderRules,
    ReminderEvents,
    ProductNoteLinks,
    AppSettings,
  ],
  daos: [
    CatalogDao,
    PricingDao,
    InventoryDao,
    ReminderDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'lifer.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
