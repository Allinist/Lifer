import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/features/product/application/product_detail_providers.dart';
import 'package:lifer/features/product/application/reminder_actions.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({
    required this.productId,
    super.key,
  });

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId)).valueOrNull;
    final prices = ref.watch(productRecentPricesProvider(productId)).valueOrNull ?? const [];
    final batches = ref.watch(productBatchesProvider(productId)).valueOrNull ?? const [];
    final rules = ref.watch(productReminderRulesProvider(productId)).valueOrNull ?? const [];
    final events = ref.watch(productActiveReminderEventsProvider(productId)).valueOrNull ?? const [];
    final consumptions =
        ref.watch(productConsumptionRecordsProvider(productId)).valueOrNull ?? const [];
    final noteLinks = ref.watch(productNoteLinksProvider(productId)).valueOrNull ?? const [];
    final isDurable = detail?.productTypeLabel == '常驻品';

    return Scaffold(
      appBar: AppBar(title: const Text('商品详情')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pageInsets,
          children: [
            Text(
              '商品 ID: ${detail?.productId ?? productId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '基础信息',
              child: ListTile(
                title: Text(detail?.name ?? '未找到商品'),
                subtitle: Text(
                  '${detail?.productTypeLabel ?? '--'} · ${detail?.categoryLabel ?? '--'}',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '价格与库存',
              child: Column(
                children: [
                  ListTile(
                    title: Text(detail?.productTypeLabel == '计价品' ? '最近计价' : '最近一次购买价格'),
                    trailing: Text(detail?.latestPriceLabel ?? '--'),
                  ),
                  if (detail?.productTypeLabel == '消耗品') ...[
                    ListTile(
                      title: const Text('当前库存'),
                      trailing: Text(detail?.stockLabel ?? '--'),
                    ),
                    ListTile(
                      title: const Text('最近到期'),
                      trailing: Text(detail?.expiryLabel ?? '--'),
                    ),
                  ] else if (detail?.productTypeLabel == '常驻品') ...[
                    ListTile(
                      title: const Text('库存状态'),
                      trailing: const Text('按使用周期管理'),
                    ),
                  ] else ...[
                    ListTile(
                      title: const Text('库存状态'),
                      trailing: const Text('不追踪库存'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '快捷操作',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push('/product/edit/$productId'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('编辑'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/restock/create?productId=$productId'),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('补货'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/consume/create?productId=$productId'),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('消耗'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      final uri = Uri(
                        path: '/pricing/record/edit',
                        queryParameters: {
                          'productId': productId,
                        },
                      );
                      context.push(uri.toString());
                    },
                    icon: const Icon(Icons.sell_outlined),
                    label: const Text('记价'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/reminder-rule/create?productId=$productId'),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('提醒'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '最近价格记录',
              child: prices.isEmpty
                  ? const ListTile(
                      title: Text('暂无价格记录'),
                    )
                  : Column(
                      children: prices
                          .map(
                            (price) => ListTile(
                              onTap: () {
                                final uri = Uri(
                                  path: '/pricing/record/edit',
                                  queryParameters: {
                                    'id': price.recordId,
                                    'productId': productId,
                                    'date': price.dateLabel,
                                    'price': price.priceLabel,
                                    'channel': price.channelLabel,
                                    'quantity': price.quantityLabel,
                                  },
                                );
                                context.push(uri.toString());
                              },
                              contentPadding: EdgeInsets.zero,
                              title: Text(price.dateLabel),
                              subtitle: Text('${price.channelLabel} · ${price.quantityLabel}'),
                              trailing: Text(price.priceLabel),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '库存批次',
              child: batches.isEmpty
                  ? const ListTile(
                      title: Text('暂无库存批次'),
                    )
                  : Column(
                      children: batches
                          .map(
                            (batch) => ListTile(
                              onTap: () {
                                context.push('/inventory/batch/edit/${batch.id}');
                              },
                              contentPadding: EdgeInsets.zero,
                              title: Text(batch.batchLabel ?? '批次 ${batch.id.substring(0, 6)}'),
                              subtitle: Text(
                                '剩余 ${Formatters.quantity(batch.remainingQuantity)} / ${Formatters.quantity(batch.totalQuantity)}',
                              ),
                              trailing: Text(Formatters.fullDateFromMillis(batch.expiryDate)),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.section),
            if (!isDurable) ...[
              SectionCard(
                title: '待处理提醒事件',
                child: events.isEmpty
                    ? const ListTile(
                        title: Text('暂无待处理提醒'),
                      )
                    : Column(
                        children: events
                            .map(
                              (event) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(event.eventType),
                                subtitle: Text(
                                  '紧急度 ${event.urgencyScore} · 到期 ${Formatters.fullDateFromMillis(event.dueAt)}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () => _showPostponeOptions(context, ref, event.id),
                                      child: const Text('稍后提醒'),
                                    ),
                                    TextButton(
                                      onPressed: () => ref.read(reminderActionsProvider).resolveEvent(event.id),
                                      child: const Text('已处理'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.section),
              SectionCard(
                title: '提醒规则',
                child: rules.isEmpty
                    ? const ListTile(
                        title: Text('暂无提醒规则'),
                      )
                    : Column(
                        children: rules
                            .map(
                              (rule) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                onTap: () => context.push('/reminder-rule/edit/${rule.id}?productId=$productId'),
                                title: Text(_ruleTypeLabel(rule.ruleType)),
                                subtitle: Text(
                                  '${_thresholdTypeLabel(rule.thresholdType)} ${rule.thresholdValue ?? '--'}'
                                  '${rule.notifyTimeText == null || rule.notifyTimeText!.isEmpty ? '' : ' · 时间 ${rule.notifyTimeText}'}'
                                  '${rule.repeatIntervalHours == null ? '' : ' · 每 ${rule.repeatIntervalHours} 小时'}'
                                  ' · 优先级 ${rule.priority}',
                                ),
                                trailing: TextButton(
                                  onPressed: () => ref.read(reminderActionsProvider).setRuleEnabled(
                                        ruleId: rule.id,
                                        enabled: !rule.isEnabled,
                                      ),
                                  child: Text(rule.isEnabled ? '停用' : '启用'),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.section),
            ],
            SectionCard(
              title: '最近消耗记录',
              child: consumptions.isEmpty
                  ? const ListTile(
                      title: Text('暂无消耗记录'),
                    )
                  : Column(
                      children: consumptions
                          .map(
                            (record) => ListTile(
                              onTap: () {
                                final uri = Uri(
                                  path: '/consume/create',
                                  queryParameters: {
                                    'id': record.id,
                                    'productId': productId,
                                  },
                                );
                                context.push(uri.toString());
                              },
                              contentPadding: EdgeInsets.zero,
                              title: Text(Formatters.fullDateFromMillis(record.occurredAt)),
                              subtitle: Text('用途 ${record.usageType}'),
                              trailing: Text(Formatters.quantity(record.quantity)),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '笔记入口',
              child: noteLinks.isEmpty
                  ? const ListTile(
                      title: Text('暂无关联笔记'),
                    )
                  : Column(
                      children: noteLinks
                          .map(
                            (link) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(link.title),
                              subtitle: Text(link.obsidianPath ?? link.uri ?? '--'),
                              trailing: Text(link.linkType),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showPostponeOptions(BuildContext context, WidgetRef ref, String eventId) async {
  final hours = await showModalBottomSheet<int>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('1 小时后提醒'),
              onTap: () => Navigator.of(context).pop(1),
            ),
            ListTile(
              title: const Text('3 小时后提醒'),
              onTap: () => Navigator.of(context).pop(3),
            ),
            ListTile(
              title: const Text('今天晚些提醒'),
              onTap: () => Navigator.of(context).pop(8),
            ),
            ListTile(
              title: const Text('明天提醒'),
              onTap: () => Navigator.of(context).pop(24),
            ),
          ],
        ),
      );
    },
  );

  if (hours == null) return;
  await ref.read(reminderActionsProvider).postponeEvent(eventId: eventId, hours: hours);
}

String _ruleTypeLabel(String ruleType) {
  switch (ruleType) {
    case 'expiry':
      return '保质期提醒';
    case 'price_target':
      return '价格目标提醒';
    case 'restock':
    default:
      return '补货提醒';
  }
}

String _thresholdTypeLabel(String thresholdType) {
  switch (thresholdType) {
    case 'days_before_expiry':
      return '到期前';
    case 'price_minor':
      return '目标价格';
    case 'ratio':
      return '阈值比例';
    case 'quantity':
    default:
      return '阈值';
  }
}
