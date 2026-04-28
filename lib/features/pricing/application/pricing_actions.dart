import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/db_write_helper.dart';
import 'package:uuid/uuid.dart';

final pricingActionsProvider = Provider<PricingActions>((ref) {
  return PricingActions(
    ref.watch(appDatabaseProvider),
    ref.watch(pricingDaoProvider),
  );
});

class PricingActions {
  PricingActions(this._db, this._pricingDao)
      : _uuid = const Uuid(),
        _helper = DbWriteHelper(_db);

  final AppDatabase _db;
  final PricingDao _pricingDao;
  final Uuid _uuid;
  final DbWriteHelper _helper;

  Future<void> savePriceRecord({
    required String? recordId,
    required String? productId,
    String? productName,
    required String recordDate,
    required String price,
    required String quantity,
    required String? unitSymbol,
    required String channelName,
  }) async {
    final resolvedProductId = (productId == null || productId.trim().isEmpty)
        ? await _ensurePricingProduct(productName)
        : productId.trim();
    final amountMinor = _parseMoney(price) ?? 0;
    final purchasedAt = _parseDate(recordDate) ?? DateTime.now().millisecondsSinceEpoch;
    final channelId = await _ensureChannel(channelName);
    final unitId = unitSymbol == null || unitSymbol.trim().isEmpty ? null : await _ensureUnit(unitSymbol);

    if (recordId == null || recordId.isEmpty) {
      await _pricingDao.upsertPriceRecord(
        PriceRecordsCompanion.insert(
          id: _uuid.v4(),
          productId: resolvedProductId,
          channelId: Value(channelId),
          amountMinor: amountMinor,
          currencyCode: 'CNY',
          quantity: Value(_parseQuantity(quantity)),
          unitId: Value(unitId),
          purchasedAt: purchasedAt,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return;
    }

    await _pricingDao.updatePriceRecord(
      recordId: recordId,
      amountMinor: amountMinor,
      purchasedAt: purchasedAt,
      quantity: _parseQuantity(quantity),
      channelId: channelId,
      unitId: unitId,
    );
  }

  Future<String> _ensurePricingProduct(String? productName) async {
    final name = productName?.trim() ?? '';
    if (name.isEmpty) {
      throw StateError('请选择关联商品或填写计价商品名称');
    }
    final existing = await ((_db.select(_db.products))
          ..where((tbl) => tbl.name.equals(name) & tbl.isArchived.equals(false))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return _helper.ensureProduct(
      productName: name,
      categoryName: '未分类',
      unitSymbol: '件',
      productType: 'pricing_only',
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
    final sanitized = input.trim().replaceAll(RegExp(r'[^0-9.\-]'), '');
    final value = double.tryParse(sanitized);
    if (value == null) return null;
    return (value * 100).round();
  }

  int? _parseDate(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.millisecondsSinceEpoch;
  }

  double? _parseQuantity(String input) {
    final text = input.trim();
    if (text.isEmpty || text == '--') return null;
    return double.tryParse(text);
  }
}
