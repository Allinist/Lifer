import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/db_write_helper.dart';
import 'package:uuid/uuid.dart';

final inventoryActionsProvider = Provider<InventoryActions>((ref) {
  return InventoryActions(ref.watch(appDatabaseProvider));
});

class InventoryActions {
  InventoryActions(this._db)
      : _helper = DbWriteHelper(_db),
        _uuid = const Uuid();

  final AppDatabase _db;
  final DbWriteHelper _helper;
  final Uuid _uuid;

  Future<void> createRestock({
    required String productName,
    required String quantity,
    required String unitSymbol,
    required String totalPrice,
    required String channelName,
    required String purchasedAt,
    required String expiryDate,
    required String locationName,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final productId = await _helper.ensureProduct(
      productName: productName,
      categoryName: '未分类',
      unitSymbol: unitSymbol,
      productType: 'consumable',
    );
    final unitId = await _helper.ensureUnit(unitSymbol);
    final channelId = await _ensureChannel(channelName);
    final priceId = _uuid.v4();
    final batchId = _uuid.v4();

    await _db.inventoryDao.createRestockBundle(
      priceEntry: PriceRecordsCompanion.insert(
        id: priceId,
        productId: productId,
        channelId: Value(channelId),
        amountMinor: _parseMoney(totalPrice) ?? 0,
        currencyCode: 'CNY',
        quantity: Value(_parseDouble(quantity)),
        unitId: Value(unitId),
        purchasedAt: _parseDate(purchasedAt) ?? now,
        createdAt: now,
        updatedAt: now,
      ),
      batchEntry: StockBatchesCompanion.insert(
        id: batchId,
        productId: productId,
        sourcePriceRecordId: Value(priceId),
        channelId: Value(channelId),
        totalQuantity: _parseDouble(quantity),
        remainingQuantity: _parseDouble(quantity),
        unitId: unitId,
        purchasedAt: Value(_parseDate(purchasedAt)),
        expiryDate: Value(_parseDate(expiryDate)),
        storageNotes: Value(locationName.trim().isEmpty ? null : locationName.trim()),
        batchLabel: Value(null),
        createdAt: now,
        updatedAt: now,
      ),
      restockEntry: RestockRecordsCompanion.insert(
        id: _uuid.v4(),
        productId: productId,
        batchId: Value(batchId),
        priceRecordId: Value(priceId),
        quantity: _parseDouble(quantity),
        unitId: unitId,
        occurredAt: _parseDate(purchasedAt) ?? now,
        notes: Value(notes.trim().isEmpty ? null : notes.trim()),
        createdAt: now,
      ),
    );
  }

  Future<void> createConsumption({
    required String productName,
    required String quantity,
    required String unitSymbol,
    required String occurredAt,
    required String batchLabel,
    required String usageType,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final productId = await _helper.ensureProduct(
      productName: productName,
      categoryName: '未分类',
      unitSymbol: unitSymbol,
      productType: 'consumable',
    );
    final unitId = await _helper.ensureUnit(unitSymbol);
    final qty = _parseDouble(quantity);

    final batch = await ((_db.select(_db.stockBatches))
          ..where((tbl) => tbl.productId.equals(productId) & tbl.remainingQuantity.isBiggerThanValue(0))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.expiryDate),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();

    await _db.inventoryDao.recordConsumption(
      consumptionEntry: ConsumptionRecordsCompanion.insert(
        id: _uuid.v4(),
        productId: productId,
        batchId: Value(batch?.id),
        quantity: qty,
        unitId: unitId,
        occurredAt: _parseDate(occurredAt) ?? now,
        usageType: usageType,
        notes: Value(_joinNotes(batchLabel, notes)),
        createdAt: now,
      ),
      batchId: batch?.id,
      nextRemainingQuantity: batch == null
          ? 0
          : (batch.remainingQuantity - qty).clamp(0, batch.remainingQuantity).toDouble(),
    );
  }

  Future<String?> _ensureChannel(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return null;

    final existing = await ((_db.select(_db.purchaseChannels))
          ..where((tbl) => tbl.name.equals(name))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      return existing.id;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    await _db.into(_db.purchaseChannels).insert(
          PurchaseChannelsCompanion.insert(
            id: id,
            name: name,
            channelType: 'offline',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  String? _joinNotes(String batchLabel, String notes) {
    final parts = <String>[];
    if (batchLabel.trim().isNotEmpty) {
      parts.add('批次: ${batchLabel.trim()}');
    }
    if (notes.trim().isNotEmpty) {
      parts.add(notes.trim());
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  int? _parseMoney(String input) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    return (value * 100).round();
  }

  double _parseDouble(String input) {
    return double.tryParse(input.trim()) ?? 0;
  }

  int? _parseDate(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.millisecondsSinceEpoch;
  }
}
