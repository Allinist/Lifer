import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/db_write_helper.dart';
import 'package:uuid/uuid.dart';

final productActionsProvider = Provider<ProductActions>((ref) {
  return ProductActions(ref.watch(appDatabaseProvider));
});

class ProductActions {
  ProductActions(this._db)
      : _helper = DbWriteHelper(_db),
        _uuid = const Uuid();

  final AppDatabase _db;
  final DbWriteHelper _helper;
  final Uuid _uuid;

  Future<String> createProduct({
    required String name,
    required String alias,
    required String productType,
    required String categoryName,
    required String brand,
    required String unitSymbol,
    required String targetPrice,
    required String shelfLifeDays,
    required bool isPinnedHome,
    required String notes,
    String? logoUri,
    String? durablePurchasedAt,
    String consumablePriceMode = 'total',
    String? currencyCode,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw StateError('商品名称不能为空');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoryId = await _helper.ensureRootCategory(categoryName);
    final unitId = await _helper.ensureUnit(unitSymbol);
    await _ensureNoDuplicateName(
      categoryId: categoryId,
      productName: normalizedName,
    );

    final productId = _uuid.v4();
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            id: productId,
            categoryId: categoryId,
            name: normalizedName,
            alias: Value(alias.trim().isEmpty ? null : alias.trim()),
            productType: productType,
            unitId: Value(unitId),
            brand: Value(brand.trim().isEmpty ? null : brand.trim()),
            expectedPriceMinor: Value(_parseMoney(targetPrice)),
            currencyCode: Value((currencyCode ?? 'CNY').toUpperCase()),
            defaultShelfLifeDays: Value(_parseInt(shelfLifeDays)),
            isPinnedHome: Value(isPinnedHome),
            notes: Value(notes.trim().isEmpty ? null : notes.trim()),
            logoUri: Value(logoUri),
            metadataJson: Value(_buildMetadata(productType: productType, consumablePriceMode: consumablePriceMode)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    if (productType == 'durable' || productType == 'pricing_only') {
      final initialPrice = _parseMoney(targetPrice);
      final purchasedAt = _parseDate(durablePurchasedAt ?? '') ?? now;
      if (initialPrice != null && initialPrice > 0) {
        final priceId = _uuid.v4();
        await _db.into(_db.priceRecords).insert(
              PriceRecordsCompanion.insert(
                id: priceId,
                productId: productId,
                amountMinor: initialPrice,
                currencyCode: (currencyCode ?? 'CNY').toUpperCase(),
                quantity: const Value(null),
                unitId: Value(unitId),
                purchasedAt: purchasedAt,
                sourceType: const Value('initial_durable_price'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        if (productType == 'pricing_only') {
          return productId;
        }
        await _db.into(_db.durableUsagePeriods).insert(
              DurableUsagePeriodsCompanion.insert(
                id: _uuid.v4(),
                productId: productId,
                priceRecordId: Value(priceId),
                startAt: purchasedAt,
                purchasePriceMinor: Value(initialPrice),
                currencyCode: Value((currencyCode ?? 'CNY').toUpperCase()),
                averageDailyCostMinor: Value(_computeDailyCostMinor(purchasePriceMinor: initialPrice, startAt: purchasedAt)),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    }
    return productId;
  }

  Future<void> updateProduct({
    required String productId,
    required String name,
    required String alias,
    required String productType,
    required String categoryName,
    required String brand,
    required String unitSymbol,
    required String targetPrice,
    required String shelfLifeDays,
    required bool isPinnedHome,
    required String notes,
    String? logoUri,
    String? durablePurchasedAt,
    String consumablePriceMode = 'total',
    String? currencyCode,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw StateError('商品名称不能为空');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final categoryId = await _helper.ensureRootCategory(categoryName);
    final unitId = await _helper.ensureUnit(unitSymbol);
    await _ensureNoDuplicateName(
      categoryId: categoryId,
      productName: normalizedName,
      exceptProductId: productId,
    );

    await ((_db.update(_db.products))..where((tbl) => tbl.id.equals(productId))).write(
          ProductsCompanion(
            categoryId: Value(categoryId),
            name: Value(normalizedName),
            alias: Value(alias.trim().isEmpty ? null : alias.trim()),
            productType: Value(productType),
            unitId: Value(unitId),
            brand: Value(brand.trim().isEmpty ? null : brand.trim()),
            expectedPriceMinor: Value(_parseMoney(targetPrice)),
            currencyCode: Value((currencyCode ?? 'CNY').toUpperCase()),
            defaultShelfLifeDays: Value(_parseInt(shelfLifeDays)),
            isPinnedHome: Value(isPinnedHome),
            notes: Value(notes.trim().isEmpty ? null : notes.trim()),
            logoUri: Value(logoUri),
            metadataJson: Value(_buildMetadata(productType: productType, consumablePriceMode: consumablePriceMode)),
            updatedAt: Value(now),
          ),
        );
    if (productType == 'durable') {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final startAt = _parseDate(durablePurchasedAt ?? '') ?? nowMs;
      final existing = await ((_db.select(_db.durableUsagePeriods))
            ..where((tbl) => tbl.productId.equals(productId))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();
      if (existing == null) {
        await _db.into(_db.durableUsagePeriods).insert(
              DurableUsagePeriodsCompanion.insert(
                id: _uuid.v4(),
                productId: productId,
                startAt: startAt,
                purchasePriceMinor: Value(_parseMoney(targetPrice)),
                currencyCode: Value((currencyCode ?? 'CNY').toUpperCase()),
                averageDailyCostMinor: Value(_computeDailyCostMinor(purchasePriceMinor: _parseMoney(targetPrice), startAt: startAt)),
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );
      } else {
        await ((_db.update(_db.durableUsagePeriods))
              ..where((tbl) => tbl.id.equals(existing.id)))
            .write(
          DurableUsagePeriodsCompanion(
            startAt: Value(startAt),
            purchasePriceMinor: Value(_parseMoney(targetPrice)),
                currencyCode: Value((currencyCode ?? 'CNY').toUpperCase()),
                averageDailyCostMinor: Value(_computeDailyCostMinor(purchasePriceMinor: _parseMoney(targetPrice), startAt: startAt)),
            updatedAt: Value(nowMs),
          ),
        );
      }
    }
  }

  int? _parseMoney(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return null;
    return (value * 100).round();
  }

  int? _parseInt(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }
  int? _parseDate(String input) {
    final t = input.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t)?.millisecondsSinceEpoch;
  }

  int? _computeDailyCostMinor({
    required int? purchasePriceMinor,
    required int startAt,
    int? endAt,
  }) {
    if (purchasePriceMinor == null || purchasePriceMinor <= 0) return null;
    final end = endAt ?? DateTime.now().millisecondsSinceEpoch;
    final days = ((end - startAt) / Duration.millisecondsPerDay).ceil();
    final safeDays = days <= 0 ? 1 : days;
    return (purchasePriceMinor / safeDays).round();
  }

  String? _buildMetadata({
    required String productType,
    required String consumablePriceMode,
  }) {
    if (productType != 'consumable') return null;
    return jsonEncode({'consumablePriceMode': consumablePriceMode});
  }

  Future<void> _ensureNoDuplicateName({
    required String categoryId,
    required String productName,
    String? exceptProductId,
  }) async {
    final duplicate = await ((_db.select(_db.products))
          ..where((tbl) => tbl.categoryId.equals(categoryId) & tbl.name.equals(productName))
          ..limit(1))
        .getSingleOrNull();
    if (duplicate == null) return;
    if (exceptProductId != null && duplicate.id == exceptProductId) return;
    throw StateError('同分类下已存在同名商品：$productName');
  }
}



