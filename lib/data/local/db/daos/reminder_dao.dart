import 'package:drift/drift.dart';
import 'package:lifer/data/local/db/app_database.dart';

part 'reminder_dao.g.dart';

@DriftAccessor(tables: [ReminderRules, ReminderEvents, Products, StockBatches])
class ReminderDao extends DatabaseAccessor<AppDatabase> with _$ReminderDaoMixin {
  ReminderDao(super.db);

  Stream<List<ReminderEvent>> watchActiveReminderEvents() {
    return (select(reminderEvents)
          ..where((tbl) => tbl.isResolved.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.urgencyScore,
                  mode: OrderingMode.desc,
                ),
            (tbl) => OrderingTerm(expression: tbl.dueAt),
          ]))
        .watch();
  }

  Stream<List<ReminderRule>> watchProductRules(String productId) {
    return (select(reminderRules)
          ..where((tbl) => tbl.productId.equals(productId))
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.priority,
                  mode: OrderingMode.desc,
                ),
            (tbl) => OrderingTerm(expression: tbl.updatedAt),
          ]))
        .watch();
  }

  Future<void> upsertReminderRule(ReminderRulesCompanion entry) {
    return into(reminderRules).insertOnConflictUpdate(entry);
  }

  Future<void> replaceProductReminderEvents({
    required String productId,
    required List<ReminderEventsCompanion> entries,
  }) {
    return transaction(() async {
      await (delete(reminderEvents)..where((tbl) => tbl.productId.equals(productId)))
          .go();
      if (entries.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(reminderEvents, entries);
        });
      }
    });
  }

  Future<void> markEventResolved(String eventId) {
    return (update(reminderEvents)..where((tbl) => tbl.id.equals(eventId))).write(
      ReminderEventsCompanion(
        isResolved: const Value(true),
        resolvedAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
