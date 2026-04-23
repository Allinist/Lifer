import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/app/theme/app_colors.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Lifer',
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search_rounded),
        ),
      ],
      children: const [
        _HeroSummary(),
        SizedBox(height: AppSpacing.section),
        _PinnedProductsSection(),
        SizedBox(height: AppSpacing.section),
        _ReminderProductsSection(),
        SizedBox(height: AppSpacing.section),
        _OtherProductsSection(),
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '把价格、库存和提醒放进同一张生活仪表盘',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '今天有 3 个补货提醒，2 个商品接近保质期，固定商品里有 1 个价格回落。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.88),
                ),
          ),
        ],
      ),
    );
  }
}

class _PinnedProductsSection extends StatelessWidget {
  const _PinnedProductsSection();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '指定固定商品',
      subtitle: '一行两个，始终展示你最关心的商品',
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.gridGap,
        crossAxisSpacing: AppSpacing.gridGap,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.94,
        children: const [
          _ProductCard(
            name: '牛奶',
            metaTop: '最近一次 12.80',
            metaBottom: '库存 2 盒 · 3 天后到期',
            badge: '固定',
            badgeColor: AppColors.secondary,
          ),
          _ProductCard(
            name: '纸巾',
            metaTop: '最近一次 24.50',
            metaBottom: '库存 6 包 · 预计 16 天',
            badge: '固定',
            badgeColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _ReminderProductsSection extends StatelessWidget {
  const _ReminderProductsSection();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '提醒商品',
      subtitle: '按紧急程度排序',
      trailing: TextButton(
        onPressed: () {},
        child: const Text('查看全部'),
      ),
      child: Column(
        children: const [
          _ReminderTile(
            title: '鸡蛋',
            subtitle: '库存只剩 2 枚，建议今晚补货',
            urgencyLabel: '库存低',
            color: AppColors.warning,
          ),
          SizedBox(height: 12),
          _ReminderTile(
            title: '菠菜',
            subtitle: '距离到期还有 1 天',
            urgencyLabel: '快到期',
            color: AppColors.danger,
          ),
          SizedBox(height: 12),
          _ReminderTile(
            title: '洗衣液',
            subtitle: '价格低于目标价 8%',
            urgencyLabel: '价格回落',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _OtherProductsSection extends StatelessWidget {
  const _OtherProductsSection();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '其他物品',
      subtitle: '默认折叠，可按消耗品和常驻品继续展开',
      child: Column(
        children: const [
          _ExpandableGroup(title: '消耗品 · 厨房食材', itemCount: 12),
          SizedBox(height: 12),
          _ExpandableGroup(title: '消耗品 · 洗护清洁', itemCount: 8),
          SizedBox(height: 12),
          _ExpandableGroup(title: '常驻品 · 家电耗材', itemCount: 6),
        ],
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
        trailing: const Icon(Icons.expand_more_rounded),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.name,
    required this.metaTop,
    required this.metaBottom,
    required this.badge,
    required this.badgeColor,
  });

  final String name;
  final String metaTop;
  final String metaBottom;
  final String badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/product/demo-$name'),
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
    required this.title,
    required this.subtitle,
    required this.urgencyLabel,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String urgencyLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
