import 'package:flutter/material.dart';
import 'package:lifer/app/theme/app_colors.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: '库存',
      children: const [
        _SearchAndSegment(),
        SizedBox(height: AppSpacing.section),
        _ConsumableSection(),
        SizedBox(height: AppSpacing.section),
        _DurableSection(),
      ],
    );
  }
}

class _SearchAndSegment extends StatelessWidget {
  const _SearchAndSegment();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: '搜索商品、位置或渠道',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'consumable', label: Text('消耗品')),
              ButtonSegment(value: 'durable', label: Text('常驻品')),
            ],
            selected: const {'consumable'},
            onSelectionChanged: (_) {},
          ),
        ),
      ],
    );
  }
}

class _ConsumableSection extends StatelessWidget {
  const _ConsumableSection();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: '消耗品',
      subtitle: '库存、批次、保质期、存放位置',
      child: Column(
        children: [
          _InventoryTile(
            title: '牛奶',
            summary: '库存 2 盒 · 最近到期 3 天后 · 冰箱冷藏层',
            metric: '预计可用 4 天',
          ),
          SizedBox(height: 12),
          _InventoryTile(
            title: '鸡蛋',
            summary: '库存 12 枚 · 最近到期 6 天后 · 厨房常温篮',
            metric: '补货阈值 20%',
          ),
        ],
      ),
    );
  }
}

class _DurableSection extends StatelessWidget {
  const _DurableSection();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: '常驻品',
      subtitle: '使用周期和平均日开销',
      child: Column(
        children: [
          _InventoryTile(
            title: '净水滤芯',
            summary: '开始使用 2026-03-18 · 平均日开销 1.8',
            metric: '建议 15 天后更换',
          ),
          SizedBox(height: 12),
          _InventoryTile(
            title: '电动牙刷头',
            summary: '开始使用 2026-04-01 · 平均日开销 0.7',
            metric: '当前周期第 22 天',
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.title,
    required this.summary,
    required this.metric,
  });

  final String title;
  final String summary;
  final String metric;

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
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(summary, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  metric,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }
}
