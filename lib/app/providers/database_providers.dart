import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/daos/catalog_dao.dart';
import 'package:lifer/data/local/db/daos/inventory_dao.dart';
import 'package:lifer/data/local/db/daos/pricing_dao.dart';
import 'package:lifer/data/local/db/daos/reminder_dao.dart';
import 'package:lifer/data/local/db/daos/settings_dao.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final catalogDaoProvider = Provider<CatalogDao>((ref) {
  return ref.watch(appDatabaseProvider).catalogDao;
});

final pricingDaoProvider = Provider<PricingDao>((ref) {
  return ref.watch(appDatabaseProvider).pricingDao;
});

final inventoryDaoProvider = Provider<InventoryDao>((ref) {
  return ref.watch(appDatabaseProvider).inventoryDao;
});

final reminderDaoProvider = Provider<ReminderDao>((ref) {
  return ref.watch(appDatabaseProvider).reminderDao;
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
});
