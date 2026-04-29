import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/core/utils/formatters.dart';

class ReminderRuleListItem {
  const ReminderRuleListItem({
    required this.ruleId,
    required this.productId,
    required this.productName,
    required this.ruleType,
    required this.thresholdText,
    required this.scheduleText,
    required this.enabled,
    required this.priority,
  });

  final String ruleId;
  final String productId;
  final String productName;
  final String ruleType;
  final String thresholdText;
  final String scheduleText;
  final bool enabled;
  final int priority;
}

final reminderRuleListProvider = FutureProvider<List<ReminderRuleListItem>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.reminderRules).join([
    leftOuterJoin(db.products, db.products.id.equalsExp(db.reminderRules.productId)),
  ])
    ..orderBy([
      OrderingTerm(expression: db.reminderRules.isEnabled, mode: OrderingMode.desc),
      OrderingTerm(expression: db.reminderRules.priority, mode: OrderingMode.desc),
      OrderingTerm(expression: db.reminderRules.updatedAt, mode: OrderingMode.desc),
    ]);

  final rows = await query.get();
  return rows.map((row) {
    final rule = row.readTable(db.reminderRules);
    final product = row.readTableOrNull(db.products);
    return ReminderRuleListItem(
      ruleId: rule.id,
      productId: rule.productId,
      productName: product?.name ?? '未知商品',
      ruleType: rule.ruleType,
      thresholdText: _thresholdText(rule.thresholdType, rule.thresholdValue),
      scheduleText: _scheduleText(rule.notifyTimeText, rule.repeatIntervalHours),
      enabled: rule.isEnabled,
      priority: rule.priority,
    );
  }).toList();
});

final reminderRuleSearchQueryProvider = StateProvider<String>((ref) => '');

final groupedReminderRuleListProvider = Provider<Map<String, List<ReminderRuleListItem>>>((ref) {
  final items = ref.watch(reminderRuleListProvider).valueOrNull ?? const <ReminderRuleListItem>[];
  final query = ref.watch(reminderRuleSearchQueryProvider).trim().toLowerCase();
  final filtered = query.isEmpty
      ? items
      : items
          .where((e) =>
              e.productName.toLowerCase().contains(query) ||
              e.thresholdText.toLowerCase().contains(query) ||
              e.scheduleText.toLowerCase().contains(query))
          .toList();

  final enabled = <ReminderRuleListItem>[];
  final disabled = <ReminderRuleListItem>[];
  for (final item in filtered) {
    (item.enabled ? enabled : disabled).add(item);
  }
  return {
    '启用中 (${enabled.length})': enabled,
    '已停用 (${disabled.length})': disabled,
  };
});

String _thresholdText(String type, double? value) {
  if (value == null) return type;
  if (type == 'expiry_days') return '到期前 ${value.toStringAsFixed(0)} 天';
  if (type == 'stock_below') return '库存低于 ${value.toStringAsFixed(0)}';
  return '$type ${value.toStringAsFixed(0)}';
}

String _scheduleText(String? notifyTime, int? repeatHours) {
  final timeText = (notifyTime == null || notifyTime.isEmpty) ? '--:--' : notifyTime;
  if (repeatHours == null || repeatHours <= 0) return '时间 $timeText · 单次';
  return '时间 $timeText · 每 $repeatHours 小时';
}
