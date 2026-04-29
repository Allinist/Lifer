import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/app/theme/app_colors.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/features/home/application/home_models.dart';
import 'package:lifer/features/home/application/home_providers.dart';
import 'package:lifer/features/product/application/reminder_actions.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedCards = ref.watch(homePinnedCardProvider).valueOrNull ?? const <HomeProductCardData>[];
    final reminderCards =
        ref.watch(homeReminderCardProvider).valueOrNull ?? const <ReminderCardData>[];
    final otherGroups =
        ref.watch(homeOtherProductGroupsProvider).valueOrNull ?? const <OtherProductGroupData>[];

    return AppPageScaffold(
      title: 'Lifer',
      onRefresh: () async {
        ref.invalidate(homePinnedCardProvider);
        ref.invalidate(homeReminderCardProvider);
        ref.invalidate(homeOtherProductGroupsProvider);
      },
      actions: [
        IconButton(
          onPressed: () => _showCreateActions(context),
          icon: const Icon(Icons.add_rounded),
          tooltip: '新增',
        ),
        IconButton(
          onPressed: () => context.go('/inventory'),
          icon: const Icon(Icons.search_rounded),
        ),
      ],
      children: [
        _PinnedProductsSection(pinnedProducts: pinnedCards),
        const SizedBox(height: AppSpacing.section),
        _ReminderProductsSection(reminderEvents: reminderCards),
        const SizedBox(height: AppSpacing.section),
        _OtherProductsSection(groups: otherGroups),
      ],
    );
  }
}

Future<void> _showCreateActions(BuildContext context) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('新增'),
              onTap: () => Navigator.of(context).pop('create'),
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_outlined),
              title: const Text('补货'),
              onTap: () => Navigator.of(context).pop('restock'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_shopping_cart_outlined),
              title: const Text('消耗'),
              onTap: () => Navigator.of(context).pop('consume'),
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: const Text('计价'),
              onTap: () => Navigator.of(context).pop('pricing'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('提醒'),
              onTap: () => Navigator.of(context).pop('reminder'),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted || action == null) return;
  switch (action) {
    case 'create':
      context.push('/product/create');
      return;
    case 'restock':
      context.push('/restock/create');
      return;
    case 'consume':
      context.push('/consume/create');
      return;
    case 'pricing':
      context.push('/pricing/record/edit');
      return;
    case 'reminder':
      context.push('/reminder-rule/create');
      return;
  }
}

class _PinnedProductsSection extends StatelessWidget {
  const _PinnedProductsSection({
    required this.pinnedProducts,
  });

  final List<HomeProductCardData> pinnedProducts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '固定商品',
      subtitle: '首页优先展示你钉住的重点商品',
      child: pinnedProducts.isEmpty
          ? const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('暂无固定商品'),
              subtitle: Text('给商品开启首页固定后，这里会显示真实价格和库存。'),
            )
          : GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.gridGap,
              crossAxisSpacing: AppSpacing.gridGap,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.65,
              children: pinnedProducts
                  .take(6)
                  .map(
                    (product) => _ProductCard(
                      productId: product.productId,
                      name: product.name,
                      productType: product.productType,
                      logoUri: product.logoUri,
                      brandText: product.brandText,
                      priceText: product.priceText,
                      stockText: product.stockText,
                      expiryText: product.expiryText,
                      dailyCostText: product.dailyCostText,
                      stockLevel: product.stockLevel,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ReminderProductsSection extends ConsumerWidget {
  const _ReminderProductsSection({
    required this.reminderEvents,
  });

  final List<ReminderCardData> reminderEvents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: '提醒商品',
      subtitle: '按紧急程度排序',
      child: reminderEvents.isEmpty
          ? const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('暂无提醒事件'),
              subtitle: Text('激活提醒规则后，这里会自动显示待处理商品。'),
            )
          : Column(
              children: reminderEvents
                  .take(5)
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReminderTile(
                        productId: event.productId,
                        title: event.title,
                        subtitle: event.subtitle,
                        urgencyLabel: '提醒',
                        color: event.urgencyScore >= 80
                            ? AppColors.danger
                            : event.urgencyScore >= 50
                                ? AppColors.warning
                                : AppColors.success,
                        onPostpone: () => _showHomePostponeOptions(context, ref, event.eventId),
                        onResolve: () => ref.read(reminderActionsProvider).resolveEvent(event.eventId),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _OtherProductsSection extends StatelessWidget {
  const _OtherProductsSection({
    required this.groups,
  });

  final List<OtherProductGroupData> groups;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '其他商品',
      subtitle: '按商品类型和分类自动聚合',
      child: groups.isEmpty
          ? const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('暂无其他商品'),
              subtitle: Text('录入未固定的商品后，这里会按分组自动汇总。'),
            )
          : Column(
              children: groups
                  .take(8)
                  .map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExpandableGroup(
                    title: group.title,
                    itemCount: group.itemCount,
                    items: group.items,
                  ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ExpandableGroup extends StatelessWidget {
  const _ExpandableGroup({
    required this.title,
    required this.itemCount,
    required this.items,
  });

  final String title;
  final int itemCount;
  final List<OtherProductItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
          title: Text(title),
          subtitle: Text('$itemCount 个商品'),
          children: [
            for (final item in items)
              ListTile(
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(item.name),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/product/${item.productId}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.productId,
    required this.name,
    required this.productType,
    required this.logoUri,
    required this.brandText,
    required this.priceText,
    required this.stockText,
    required this.expiryText,
    required this.dailyCostText,
    required this.stockLevel,
  });

  final String productId;
  final String name;
  final String productType;
  final String? logoUri;
  final String brandText;
  final String priceText;
  final String stockText;
  final String expiryText;
  final String dailyCostText;
  final int stockLevel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/product/$productId'),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outline, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_iconFromLogo(logoUri), size: 16),
                ),
                const Spacer(),
                _Badge(
                  label: priceText,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            if (productType == 'consumable')
              Row(
                children: [
                  Expanded(
                    child: Text(expiryText, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Text(
                    stockText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: stockLevel == 2
                              ? AppColors.danger
                              : (stockLevel == 1 ? AppColors.warning : AppColors.success),
                        ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dailyCostText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    brandText.isEmpty ? '--' : brandText,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFromLogo(String? logoUri) {
  switch (logoUri) {
    case 'home':
      return Icons.home_outlined;
    case 'kitchen':
      return Icons.kitchen_outlined;
    case 'health':
      return Icons.health_and_safety_outlined;
    case 'car':
      return Icons.directions_car_outlined;
    default:
      return Icons.shopping_bag_outlined;
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.urgencyLabel,
    required this.color,
    required this.onPostpone,
    required this.onResolve,
  });

  final String productId;
  final String title;
  final String subtitle;
  final String urgencyLabel;
  final Color color;
  final VoidCallback onPostpone;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/product/$productId'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.notifications_active_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                _Badge(label: urgencyLabel, color: color),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onPostpone,
                  child: const Text('稍后'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onResolve,
                  child: const Text('处理'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

Future<void> _showHomePostponeOptions(BuildContext context, WidgetRef ref, String eventId) async {
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
