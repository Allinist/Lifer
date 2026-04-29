import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/features/product/application/reminder_actions.dart';
import 'package:lifer/features/product/application/reminder_rule_list_providers.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class ReminderRuleListPage extends ConsumerWidget {
  const ReminderRuleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupedReminderRuleListProvider);
    return AppPageScaffold(
      title: '提醒规则',
      actions: [
        IconButton(
          onPressed: () => context.push('/reminder-rule/create'),
          icon: const Icon(Icons.add_rounded),
          tooltip: '新增规则',
        ),
      ],
      children: [
        TextField(
          onChanged: (value) =>
              ref.read(reminderRuleSearchQueryProvider.notifier).state = value,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: '搜索商品/阈值/规则',
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: '规则列表',
          subtitle: '查看并管理所有提醒规则',
          child: groups.values.every((list) => list.isEmpty)
              ? const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('暂无提醒规则'),
                )
              : Column(
                  children: groups.entries.expand((entry) {
                    final section = <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
                        ),
                      ),
                    ];
                    section.addAll(entry.value.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName),
                          subtitle: Text('${item.thresholdText}\n${item.scheduleText}'),
                          isThreeLine: true,
                          trailing: Switch(
                            value: item.enabled,
                            onChanged: (value) {
                              ref.read(reminderActionsProvider).setRuleEnabled(
                                    ruleId: item.ruleId,
                                    enabled: value,
                                  );
                              ref.invalidate(reminderRuleListProvider);
                            },
                          ),
                          onTap: () => context.push('/reminder-rule/edit/${item.ruleId}?productId=${item.productId}'),
                        )));
                    return section;
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
