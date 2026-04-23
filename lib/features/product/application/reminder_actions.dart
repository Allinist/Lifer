import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/data/local/db/db_write_helper.dart';
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
    final productId = await _helper.ensureProduct(
      productName: productName,
      categoryName: '未分类',
      unitSymbol: '件',
      productType: 'consumable',
    );

    await _db.reminderDao.upsertReminderRule(
      ReminderRulesCompanion.insert(
        id: _uuid.v4(),
        productId: productId,
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
  }
}
