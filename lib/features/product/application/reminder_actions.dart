import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/db_write_helper.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

final reminderActionsProvider = Provider<ReminderActions>((ref) {
  return ReminderActions(ref.watch(appDatabaseProvider));
});

class ReminderActions {
  ReminderActions(this._db)
      : _helper = DbWriteHelper(_db),
        _uuid = const Uuid();

  final AppDatabase _db;
  final DbWriteHelper _helper;
  final Uuid _uuid;

  Future<void> saveRule({
    String? ruleId,
    String? productId,
    required String productName,
    required String ruleType,
    required String thresholdType,
    required String thresholdValue,
    required String notifyTime,
    required String repeatIntervalHours,
    required String priority,
    required bool enabled,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final resolvedProductId = productId != null && productId.isNotEmpty
        ? productId
        : await _helper.ensureProduct(
            productName: productName,
            categoryName: '未分类',
            unitSymbol: '件',
            productType: 'consumable',
          );

    await _db.reminderDao.upsertReminderRule(
      ReminderRulesCompanion.insert(
        id: ruleId ?? _uuid.v4(),
        productId: resolvedProductId,
        ruleType: ruleType,
        thresholdType: thresholdType,
        thresholdValue: Value(double.tryParse(thresholdValue.trim())),
        notifyTimeText: Value(notifyTime.trim().isEmpty ? null : notifyTime.trim()),
        repeatMode: repeatIntervalHours.trim().isEmpty ? 'once' : 'interval',
        repeatIntervalHours: Value(int.tryParse(repeatIntervalHours.trim())),
        isEnabled: Value(enabled),
        priority: Value(int.tryParse(priority.trim()) ?? 0),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _rebuildReminderEventsForProduct(resolvedProductId);
  }

  Future<void> resolveEvent(String eventId) {
    return _db.reminderDao.markEventResolved(eventId);
  }

  Future<void> postponeEvent({
    required String eventId,
    int hours = 24,
  }) {
    return _db.reminderDao.postponeEvent(
      eventId: eventId,
      delay: Duration(hours: hours),
    );
  }

  Future<void> setRuleEnabled({
    required String ruleId,
    required bool enabled,
  }) async {
    await (_db.update(_db.reminderRules)..where((tbl) => tbl.id.equals(ruleId))).write(
      ReminderRulesCompanion(
        isEnabled: Value(enabled),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    final rule = await ((_db.select(_db.reminderRules))..where((tbl) => tbl.id.equals(ruleId))).getSingleOrNull();
    if (rule != null) {
      await _rebuildReminderEventsForProduct(rule.productId);
    }
  }

  Future<void> _rebuildReminderEventsForProduct(String productId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rules = await ((_db.select(_db.reminderRules))
          ..where((tbl) => tbl.productId.equals(productId) & tbl.isEnabled.equals(true)))
        .get();
    if (rules.isEmpty) {
      await _db.reminderDao.replaceProductReminderEvents(productId: productId, entries: const []);
      return;
    }
    final product = await ((_db.select(_db.products))..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
    final batches = await ((_db.select(_db.stockBatches))
          ..where((tbl) => tbl.productId.equals(productId) & tbl.isArchived.equals(false)))
        .get();
    final total = batches.fold<double>(0, (sum, b) => sum + b.totalQuantity);
    final remain = batches.fold<double>(0, (sum, b) => sum + b.remainingQuantity);
    final ratio = total > 0 ? (remain / total) : 0.0;
    int? nearestExpiry;
    for (final b in batches) {
      final e = b.expiryDate;
      if (e == null) continue;
      if (nearestExpiry == null || e < nearestExpiry) nearestExpiry = e;
    }
    final daysToExpiry = nearestExpiry == null ? null : ((nearestExpiry - now) / Duration.millisecondsPerDay).floor();
    final entries = <ReminderEventsCompanion>[];
    for (final rule in rules) {
      var triggered = false;
      var urgency = (40 + rule.priority * 5).clamp(10, 95);
      if (rule.ruleType == 'restock') {
        if (rule.thresholdType == 'quantity') {
          final t = rule.thresholdValue;
          if (t != null) triggered = remain <= t;
        } else if (rule.thresholdType == 'ratio') {
          final t = rule.thresholdValue;
          if (t != null) triggered = ratio <= t;
        }
        if (triggered && remain <= 0) urgency = 95;
      } else if (rule.ruleType == 'expiry') {
        final t = rule.thresholdValue;
        if (rule.thresholdType == 'days_before_expiry' && t != null && daysToExpiry != null) {
          triggered = daysToExpiry <= t;
          if (daysToExpiry <= 0) urgency = 95;
        }
      }
      if (!triggered) continue;
      entries.add(
        ReminderEventsCompanion.insert(
          id: _uuid.v4(),
          ruleId: rule.id,
          productId: productId,
          eventType: rule.ruleType,
          urgencyScore: urgency,
          dueAt: Value(now),
          snapshotJson: Value(jsonEncode({
            'productName': product?.name,
            'remainingQuantity': remain,
            'totalQuantity': total,
            'ratio': ratio,
            'daysToExpiry': daysToExpiry,
            'thresholdType': rule.thresholdType,
            'thresholdValue': rule.thresholdValue,
          })),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await _db.reminderDao.replaceProductReminderEvents(productId: productId, entries: entries);
  }
}
