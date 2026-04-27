import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsDataIoService {
  const SettingsDataIoService(this._db);

  final AppDatabase _db;

  Future<String> exportJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archiveFile = File(p.join(directory.path, 'lifer_export_$timestamp.json'));
    final latestFile = File(p.join(directory.path, 'lifer_export_latest.json'));

    final payload = jsonEncode(await _buildExportPayload());
    await archiveFile.writeAsString(payload);
    await latestFile.writeAsString(payload);

    return archiveFile.path;
  }

  Future<String> importJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final importFile = File(p.join(directory.path, 'lifer_import.json'));
    final fallbackFile = File(p.join(directory.path, 'lifer_export_latest.json'));
    final source = await importFile.exists() ? importFile : fallbackFile;

    if (!await source.exists()) {
      throw StateError('未找到可导入文件，请先放入 lifer_import.json 或先执行一次导出。');
    }

    final jsonMap = jsonDecode(await source.readAsString()) as Map<String, dynamic>;
    await _restoreFromPayload(jsonMap);
    return source.path;
  }

  Future<Map<String, dynamic>> _buildExportPayload() async {
    return {
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': (await _db.select(_db.categories).get()).map((e) => e.toJson()).toList(),
      'units': (await _db.select(_db.units).get()).map((e) => e.toJson()).toList(),
      'products': (await _db.select(_db.products).get()).map((e) => e.toJson()).toList(),
      'purchaseChannels': (await _db.select(_db.purchaseChannels).get()).map((e) => e.toJson()).toList(),
      'priceRecords': (await _db.select(_db.priceRecords).get()).map((e) => e.toJson()).toList(),
      'storageLocations': (await _db.select(_db.storageLocations).get()).map((e) => e.toJson()).toList(),
      'stockBatches': (await _db.select(_db.stockBatches).get()).map((e) => e.toJson()).toList(),
      'stockBatchLocations': (await _db.select(_db.stockBatchLocations).get()).map((e) => e.toJson()).toList(),
      'restockRecords': (await _db.select(_db.restockRecords).get()).map((e) => e.toJson()).toList(),
      'consumptionRecords': (await _db.select(_db.consumptionRecords).get()).map((e) => e.toJson()).toList(),
      'durableUsagePeriods': (await _db.select(_db.durableUsagePeriods).get()).map((e) => e.toJson()).toList(),
      'reminderRules': (await _db.select(_db.reminderRules).get()).map((e) => e.toJson()).toList(),
      'reminderEvents': (await _db.select(_db.reminderEvents).get()).map((e) => e.toJson()).toList(),
      'productNoteLinks': (await _db.select(_db.productNoteLinks).get()).map((e) => e.toJson()).toList(),
      'appSettings': (await _db.select(_db.appSettings).get()).map((e) => e.toJson()).toList(),
    };
  }

  Future<void> _restoreFromPayload(Map<String, dynamic> jsonMap) async {
    await _db.transaction(() async {
      await _clearAllTables();

      await _insertAll(
        _db.categories,
        _readList(jsonMap, 'categories').map(Category.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.units,
        _readList(jsonMap, 'units').map(Unit.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.products,
        _readList(jsonMap, 'products').map(Product.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.purchaseChannels,
        _readList(jsonMap, 'purchaseChannels')
            .map(PurchaseChannel.fromJson)
            .map((e) => e.toCompanion(true))
            .toList(),
      );
      await _insertAll(
        _db.priceRecords,
        _readList(jsonMap, 'priceRecords').map(PriceRecord.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.storageLocations,
        _readList(jsonMap, 'storageLocations')
            .map(StorageLocation.fromJson)
            .map((e) => e.toCompanion(true))
            .toList(),
      );
      await _insertAll(
        _db.stockBatches,
        _readList(jsonMap, 'stockBatches').map(StockBatche.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.stockBatchLocations,
        _readList(jsonMap, 'stockBatchLocations')
            .map(StockBatchLocation.fromJson)
            .map((e) => e.toCompanion(true))
            .toList(),
      );
      await _insertAll(
        _db.restockRecords,
        _readList(jsonMap, 'restockRecords').map(RestockRecord.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.consumptionRecords,
        _readList(jsonMap, 'consumptionRecords')
            .map(ConsumptionRecord.fromJson)
            .map((e) => e.toCompanion(true))
            .toList(),
      );
      await _insertAll(
        _db.durableUsagePeriods,
        _readList(jsonMap, 'durableUsagePeriods')
            .map(DurableUsagePeriod.fromJson)
            .map((e) => e.toCompanion(true))
            .toList(),
      );
      await _insertAll(
        _db.reminderRules,
        _readList(jsonMap, 'reminderRules').map(ReminderRule.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.reminderEvents,
        _readList(jsonMap, 'reminderEvents').map(ReminderEvent.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
      await _insertAll(
        _db.productNoteLinks,
        _readList(jsonMap, 'productNoteLinks')
            .map(ProductNoteLink.fromJson)
            .map((e) => e.toCompanion(true))
            .toList(),
      );
      await _insertAll(
        _db.appSettings,
        _readList(jsonMap, 'appSettings').map(AppSetting.fromJson).map((e) => e.toCompanion(true)).toList(),
      );
    });
  }

  List<Map<String, dynamic>> _readList(Map<String, dynamic> jsonMap, String key) {
    final raw = jsonMap[key];
    if (raw is! List) return const [];
    return raw.cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  Future<void> _clearAllTables() async {
    await _db.delete(_db.reminderEvents).go();
    await _db.delete(_db.reminderRules).go();
    await _db.delete(_db.durableUsagePeriods).go();
    await _db.delete(_db.consumptionRecords).go();
    await _db.delete(_db.restockRecords).go();
    await _db.delete(_db.stockBatchLocations).go();
    await _db.delete(_db.stockBatches).go();
    await _db.delete(_db.storageLocations).go();
    await _db.delete(_db.priceRecords).go();
    await _db.delete(_db.productNoteLinks).go();
    await _db.delete(_db.purchaseChannels).go();
    await _db.delete(_db.products).go();
    await _db.delete(_db.units).go();
    await _db.delete(_db.categories).go();
    await _db.delete(_db.appSettings).go();
  }

  Future<void> _insertAll<T extends Table, D>(TableInfo<T, D> table, List<Insertable<D>> rows) async {
    for (final row in rows) {
      await _db.into(table).insertOnConflictUpdate(row);
    }
  }
}
