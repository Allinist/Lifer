import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/app/theme/app_colors.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/features/home/application/home_models.dart';
import 'package:lifer/features/home/application/home_providers.dart';
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
      actions: [
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
              childAspectRatio: 0.94,
              children: pinnedProducts
                  .take(6)
                  .map(
                    (product) => _ProductCard(
                      productId: product.productId,
                      name: product.name,
                      metaTop: product.topLine,
                      metaBottom: product.bottomLine,
                      badge: '固定',
                      badgeColor: AppColors.secondary,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ReminderProductsSection extends StatelessWidget {
  const _ReminderProductsSection({
    required this.reminderEvents,
  });

  final List<ReminderCardData> reminderEvents;

  @override
  Widget build(BuildContext context) {
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
                      child: _ExpandableGroup(title: group.title, itemCount: group.itemCount),
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
  });

  final String title;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text('$itemCount 个商品'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.productId,
    required this.name,
    required this.metaTop,
    required this.metaBottom,
    required this.badge,
    required this.badgeColor,
  });

  final String productId;
  final String name;
  final String metaTop;
  final String metaBottom;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/product/$productId'),
      child: Ink(
        padding: const EdgeInsets.all(14),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                const Spacer(),
                _Badge(
                  label: badge,
                  color: badgeColor,
                ),
              ],
            ),
            const Spacer(),
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(metaTop, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(metaBottom, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.productId,
    required this.title,
    required this.subtitle,
    required this.urgencyLabel,
    required this.color,
  });

  final String productId;
  final String title;
  final String subtitle;
  final String urgencyLabel;
  final Color color;

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
            _Badge(label: urgencyLabel, color: color),
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
