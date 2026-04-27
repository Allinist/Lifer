import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';

final pricingActionsProvider = Provider<PricingActions>((ref) {
  return PricingActions(
    ref.watch(appDatabaseProvider),
    ref.watch(pricingDaoProvider),
  );
});

class PricingActions {
  PricingActions(this._db, this._pricingDao);

  final AppDatabase _db;
  final PricingDao _pricingDao;

  Future<void> updatePriceRecord({
    required String recordId,
    required String recordDate,
    required String price,
    required String channelName,
    required String quantityLabel,
  }) async {
    final amountMinor = _parseMoney(price) ?? 0;
    final purchasedAt = _parseDate(recordDate) ?? DateTime.now().millisecondsSinceEpoch;
    final parsedQuantity = _parseQuantityAndUnit(quantityLabel);
    final channelId = await _ensureChannel(channelName);
    final unitId = parsedQuantity.$2 == null ? null : await _ensureUnit(parsedQuantity.$2!);

    await _pricingDao.updatePriceRecord(
      recordId: recordId,
      amountMinor: amountMinor,
      purchasedAt: purchasedAt,
      quantity: parsedQuantity.$1,
      channelId: channelId,
      unitId: unitId,
    );
  }

  Future<void> deletePriceRecord(String recordId) {
    return (_db.delete(_db.priceRecords)..where((tbl) => tbl.id.equals(recordId))).go();
  }

  Future<void> createOrUpdateChannel({
    String? channelId,
    required String name,
    required String channelType,
    required String url,
    required String address,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = channelId == null || channelId.isEmpty
        ? null
        : await ((_db.select(_db.purchaseChannels))
              ..where((tbl) => tbl.id.equals(channelId)))
            .getSingleOrNull();

    final resolvedId = existing?.id ?? 'channel_${now}_${name.hashCode}';

    await _db.into(_db.purchaseChannels).insertOnConflictUpdate(
          PurchaseChannelsCompanion(
            id: Value(resolvedId),
            name: Value(name.trim()),
            channelType: Value(channelType.trim().isEmpty ? 'offline' : channelType.trim()),
            url: Value(url.trim().isEmpty ? null : url.trim()),
            address: Value(address.trim().isEmpty ? null : address.trim()),
            createdAt: existing == null ? Value(now) : const Value.absent(),
            updatedAt: Value(now),
          ),
        );
  }

  Future<String?> _ensureChannel(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty || name == '未设置渠道') return null;

    final existing = await ((_db.select(_db.purchaseChannels))
          ..where((tbl) => tbl.name.equals(name))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      return existing.id;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'channel_${now}_${name.hashCode}';
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

  Future<String?> _ensureUnit(String rawSymbol) async {
    final symbol = rawSymbol.trim();
    if (symbol.isEmpty) return null;

    final existing = await ((_db.select(_db.units))
          ..where((tbl) => tbl.symbol.equals(symbol))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      return existing.id;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'unit_${now}_${symbol.hashCode}';
    await _db.into(_db.units).insert(
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

  int? _parseMoney(String input) {
    final value = double.tryParse(input.trim());
    if (value == null) return null;
    return (value * 100).round();
  }

  int? _parseDate(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.millisecondsSinceEpoch;
  }

  (double?, String?) _parseQuantityAndUnit(String input) {
    final text = input.trim();
    if (text.isEmpty || text == '--') return (null, null);
    final parts = text.split(RegExp(r'\s+'));
    final quantity = double.tryParse(parts.first);
    final unit = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    return (quantity, unit);
  }
}
