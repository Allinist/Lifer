import 'package:flutter/material.dart';
import 'package:lifer/app/theme/app_colors.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: '价格',
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: '搜索商品、别名或分类',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const SectionCard(
          title: '商品价格分析',
          subtitle: '全部 / 时间范围 / 渠道对比',
          child: _ChartPlaceholder(
            title: '牛奶价格曲线',
            points: ['04/01 10.8', '04/08 11.2', '04/15 12.8', '04/22 11.6'],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const SectionCard(
          title: '统计摘要',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(label: '历史最低', value: '9.90'),
              _StatChip(label: '历史最高', value: '13.80'),
              _StatChip(label: '范围最低', value: '10.80'),
              _StatChip(label: '范围最高', value: '12.80'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const SectionCard(
          title: '支出分析',
          subtitle: '全部、分类集合、跨分类商品集合',
          child: _SpendingBreakdown(),
        ),
      ],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({
    required this.title,
    required this.points,
  });

  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x1A006A6A), Color(0x05006A6A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points
                  .map(
                    (point) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: 48 + (point.hashCode % 68).toDouble(),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              point.split(' ').first,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _SpendingBreakdown extends StatelessWidget {
  const _SpendingBreakdown();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;

    return Column(
      children: [
        for (final row in const [
          ('厨房食材', '328.50', 0.72),
          ('洗护清洁', '146.20', 0.41),
          ('宠物用品', '219.90', 0.58),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(row.$1, style: style)),
                    Text(row.$2, style: style),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: row.$3,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
