import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/features/product/application/product_detail_providers.dart';
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
    final consumptions =
        ref.watch(productConsumptionRecordsProvider(productId)).valueOrNull ?? const [];
    final noteLinks = ref.watch(productNoteLinksProvider(productId)).valueOrNull ?? const [];

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
                    title: const Text('最近一次购买价格'),
                    trailing: Text(detail?.latestPriceLabel ?? '--'),
                  ),
                  ListTile(
                    title: const Text('当前库存'),
                    trailing: Text(detail?.stockLabel ?? '--'),
                  ),
                  ListTile(
                    title: const Text('最近到期'),
                    trailing: Text(detail?.expiryLabel ?? '--'),
                  ),
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
                    onPressed: () => context.push('/restock/create'),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('补货'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/consume/create'),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('消耗'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push('/reminder-rule/create'),
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
                              contentPadding: EdgeInsets.zero,
                              title: Text(Formatters.fullDateFromMillis(price.purchasedAt)),
                              subtitle: Text('币种 ${price.currencyCode}'),
                              trailing: Text(Formatters.currencyFromMinor(price.amountMinor)),
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
                              title: Text('${rule.ruleType} / ${rule.thresholdType}'),
                              subtitle: Text(
                                '阈值 ${rule.thresholdValue ?? '--'} · 优先级 ${rule.priority}',
                              ),
                              trailing: Text(rule.isEnabled ? '启用' : '停用'),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.section),
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
