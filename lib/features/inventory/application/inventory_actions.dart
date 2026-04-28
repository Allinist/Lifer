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
    String? productId,
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
    final resolvedProductId = productId != null && productId.isNotEmpty
        ? productId
        : await _helper.ensureProduct(
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
        productId: resolvedProductId,
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
        productId: resolvedProductId,
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
        productId: resolvedProductId,
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
    String? productId,
    required String productName,
    required String quantity,
    required String unitSymbol,
    required String occurredAt,
    String? selectedBatchId,
    required String batchLabel,
    required String usageType,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final resolvedProductId = productId != null && productId.isNotEmpty
        ? productId
        : await _helper.ensureProduct(
            productName: productName,
            categoryName: '未分类',
            unitSymbol: unitSymbol,
            productType: 'consumable',
          );
    final unitId = await _helper.ensureUnit(unitSymbol);
    final totalQty = _parseDouble(quantity);
    var remainingQty = totalQty;
    final effectiveOccurredAt = _parseDate(occurredAt) ?? now;

    final fifoBatches = await ((_db.select(_db.stockBatches))
          ..where((tbl) => tbl.productId.equals(resolvedProductId) & tbl.remainingQuantity.isBiggerThanValue(0))
          ..orderBy([
            (tbl) => OrderingTerm(expression: tbl.expiryDate),
            (tbl) => OrderingTerm(expression: tbl.createdAt),
          ]))
        .get();

    final normalizedSelectedBatchId = selectedBatchId?.trim();
    StockBatch? selectedBatch;
    if (normalizedSelectedBatchId != null && normalizedSelectedBatchId.isNotEmpty) {
      for (final item in fifoBatches) {
        if (item.id == normalizedSelectedBatchId) {
          selectedBatch = item;
          break;
        }
      }
    }

    final orderedBatches = <StockBatch>[
      if (selectedBatch != null) selectedBatch,
      ...fifoBatches.where((b) => selectedBatch == null || b.id != selectedBatch.id),
    ];

    final entries = <ConsumptionRecordsCompanion>[];
    final nextRemainingByBatchId = <String, double>{};

    for (final batch in orderedBatches) {
      if (remainingQty <= 0) break;
      final alloc = remainingQty > batch.remainingQuantity ? batch.remainingQuantity : remainingQty;
      if (alloc <= 0) continue;
      remainingQty -= alloc;
      nextRemainingByBatchId[batch.id] = (batch.remainingQuantity - alloc).clamp(0, batch.totalQuantity).toDouble();
      entries.add(
        ConsumptionRecordsCompanion.insert(
          id: _uuid.v4(),
          productId: resolvedProductId,
          batchId: Value(batch.id),
          quantity: alloc,
          unitId: unitId,
          occurredAt: effectiveOccurredAt,
          usageType: usageType,
          notes: Value(_joinNotes(batchLabel, notes)),
          createdAt: now,
        ),
      );
    }

    if (entries.isEmpty || remainingQty > 0) {
      entries.add(
        ConsumptionRecordsCompanion.insert(
          id: _uuid.v4(),
          productId: resolvedProductId,
          batchId: const Value(null),
          quantity: remainingQty > 0 ? remainingQty : totalQty,
          unitId: unitId,
          occurredAt: effectiveOccurredAt,
          usageType: usageType,
          notes: Value(_joinNotes(batchLabel, notes)),
          createdAt: now,
        ),
      );
    }

    await _db.inventoryDao.recordConsumptionAllocations(
      consumptionEntries: entries,
      batchRemainingById: nextRemainingByBatchId,
    );
  }

  Future<void> updateStockBatch({
    required String batchId,
    required String quantity,
    required String remainingQuantity,
    required String unitSymbol,
    required String purchasedAt,
    required String expiryDate,
    String? sourcePriceRecordId,
    required String batchLabel,
    required String locationName,
  }) async {
    final unitId = await _helper.ensureUnit(unitSymbol);
    final parsedQuantity = _parseDouble(quantity);
    final parsedPurchasedAt = _parseDate(purchasedAt);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.inventoryDao.updateStockBatch(
      batchId: batchId,
      batchEntry: StockBatchesCompanion(
        totalQuantity: Value(parsedQuantity),
        remainingQuantity: Value(_parseDouble(remainingQuantity)),
        unitId: Value(unitId),
        purchasedAt: Value(parsedPurchasedAt),
        expiryDate: Value(_parseDate(expiryDate)),
        batchLabel: Value(batchLabel.trim().isEmpty ? null : batchLabel.trim()),
        storageNotes: Value(locationName.trim().isEmpty ? null : locationName.trim()),
        updatedAt: Value(now),
      ),
      sourcePriceRecordId: sourcePriceRecordId?.trim(),
      sourcePriceRecordEntry: sourcePriceRecordId == null || sourcePriceRecordId.trim().isEmpty
          ? null
          : PriceRecordsCompanion(
              quantity: Value(parsedQuantity),
              unitId: Value(unitId),
              purchasedAt: Value(parsedPurchasedAt ?? now),
              updatedAt: Value(now),
            ),
    );
  }

  Future<void> updateConsumption({
    required String consumptionId,
    required String productId,
    required String quantity,
    required String unitSymbol,
    required String occurredAt,
    String? selectedBatchId,
    bool reallocateAcrossBatches = false,
    required String batchLabel,
    required String usageType,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final original = await ((_db.select(_db.consumptionRecords))
          ..where((tbl) => tbl.id.equals(consumptionId)))
        .getSingleOrNull();
    if (original == null) return;

    final unitId = await _helper.ensureUnit(unitSymbol);
    final qty = _parseDouble(quantity);

    final normalizedSelectedBatchId = selectedBatchId?.trim();
    final targetBatchId = (normalizedSelectedBatchId == null || normalizedSelectedBatchId.isEmpty)
        ? original.batchId
        : normalizedSelectedBatchId;

    double? previousRemainingQuantity;
    double? nextRemainingQuantity;
    if (original.batchId != null && original.batchId!.isNotEmpty) {
      final batch = await ((_db.select(_db.stockBatches))
            ..where((tbl) => tbl.id.equals(original.batchId!)))
          .getSingleOrNull();
      if (batch != null) {
        previousRemainingQuantity = (batch.remainingQuantity + original.quantity)
            .clamp(0, batch.totalQuantity)
            .toDouble();
        nextRemainingQuantity = (previousRemainingQuantity - qty)
            .clamp(0, batch.totalQuantity)
            .toDouble();
      }
    }

    if (targetBatchId != null && targetBatchId.isNotEmpty) {
      final targetBatch = await ((_db.select(_db.stockBatches))
            ..where((tbl) => tbl.id.equals(targetBatchId)))
          .getSingleOrNull();
      if (targetBatch != null && targetBatch.productId == productId) {
        final baseRemaining = targetBatch.id == original.batchId
            ? (previousRemainingQuantity ?? targetBatch.remainingQuantity)
            : targetBatch.remainingQuantity;
        nextRemainingQuantity = (baseRemaining - qty).clamp(0, targetBatch.totalQuantity).toDouble();
      }
    }

    if (reallocateAcrossBatches) {
      var remainingToAllocate = qty;
      final effectiveOccurredAt = _parseDate(occurredAt) ?? now;
      final fifoBatches = await ((_db.select(_db.stockBatches))
            ..where((tbl) => tbl.productId.equals(productId) & tbl.remainingQuantity.isBiggerThanValue(0))
            ..orderBy([
              (tbl) => OrderingTerm(expression: tbl.expiryDate),
              (tbl) => OrderingTerm(expression: tbl.createdAt),
            ]))
          .get();

      final adjustedRemainingById = <String, double>{};
      if (original.batchId != null && original.batchId!.isNotEmpty && previousRemainingQuantity != null) {
        adjustedRemainingById[original.batchId!] = previousRemainingQuantity;
      }

      StockBatch? selectedBatch;
      if (targetBatchId != null && targetBatchId.isNotEmpty) {
        for (final item in fifoBatches) {
          if (item.id == targetBatchId) {
            selectedBatch = item;
            break;
          }
        }
      }
      final orderedBatches = <StockBatch>[
        if (selectedBatch != null) selectedBatch,
        ...fifoBatches.where((b) => selectedBatch == null || b.id != selectedBatch.id),
      ];

      final allocations = <MapEntry<String?, double>>[];
      for (final batch in orderedBatches) {
        if (remainingToAllocate <= 0) break;
        final baseRemaining = adjustedRemainingById.containsKey(batch.id)
            ? adjustedRemainingById[batch.id]!
            : batch.remainingQuantity;
        final alloc = remainingToAllocate > baseRemaining ? baseRemaining : remainingToAllocate;
        if (alloc <= 0) continue;
        remainingToAllocate -= alloc;
        adjustedRemainingById[batch.id] = (baseRemaining - alloc).clamp(0, batch.totalQuantity).toDouble();
        allocations.add(MapEntry(batch.id, alloc));
      }

      if (remainingToAllocate > 0) {
        allocations.add(MapEntry(null, remainingToAllocate));
      }
      if (allocations.isEmpty) {
        allocations.add(MapEntry(null, qty));
      }

      final first = allocations.first;
      final updatedPrimary = ConsumptionRecordsCompanion(
        productId: Value(productId),
        batchId: Value(first.key),
        quantity: Value(first.value),
        unitId: Value(unitId),
        occurredAt: Value(effectiveOccurredAt),
        usageType: Value(usageType),
        notes: Value(_joinNotes(batchLabel, notes)),
      );
      final extras = <ConsumptionRecordsCompanion>[
        for (final alloc in allocations.skip(1))
          ConsumptionRecordsCompanion.insert(
            id: _uuid.v4(),
            productId: productId,
            batchId: Value(alloc.key),
            quantity: alloc.value,
            unitId: unitId,
            occurredAt: effectiveOccurredAt,
            usageType: usageType,
            notes: Value(_joinNotes(batchLabel, notes)),
            createdAt: now,
          ),
      ];

      await _db.inventoryDao.replaceConsumptionWithAllocations(
        consumptionId: consumptionId,
        updatedPrimaryEntry: updatedPrimary,
        extraEntries: extras,
        previousBatchId: original.batchId,
        previousRemainingQuantity: previousRemainingQuantity,
        batchRemainingById: adjustedRemainingById,
      );
      return;
    }

    await _db.inventoryDao.updateConsumptionRecord(
      consumptionId: consumptionId,
      consumptionEntry: ConsumptionRecordsCompanion(
        productId: Value(productId),
        batchId: Value(targetBatchId),
        quantity: Value(qty),
        unitId: Value(unitId),
        occurredAt: Value(_parseDate(occurredAt) ?? now),
        usageType: Value(usageType),
        notes: Value(_joinNotes(batchLabel, notes)),
      ),
      batchId: targetBatchId,
      nextRemainingQuantity: nextRemainingQuantity,
      previousBatchId: original.batchId,
      previousRemainingQuantity: previousRemainingQuantity,
    );
  }

  Future<void> archiveStockBatch(String batchId) {
    return _db.inventoryDao.archiveStockBatch(batchId);
  }

  Future<void> deleteConsumption(String consumptionId) async {
    final record = await ((_db.select(_db.consumptionRecords))
          ..where((tbl) => tbl.id.equals(consumptionId)))
        .getSingleOrNull();
    if (record == null) return;

    double? restoredRemainingQuantity;
    if (record.batchId != null && record.batchId!.isNotEmpty) {
      final batch =
          await ((_db.select(_db.stockBatches))..where((tbl) => tbl.id.equals(record.batchId!)))
              .getSingleOrNull();
      if (batch != null) {
        restoredRemainingQuantity =
            (batch.remainingQuantity + record.quantity).clamp(0, batch.totalQuantity).toDouble();
      }
    }

    await _db.inventoryDao.deleteConsumptionRecord(
      consumptionId: consumptionId,
      batchId: record.batchId,
      restoredRemainingQuantity: restoredRemainingQuantity,
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
