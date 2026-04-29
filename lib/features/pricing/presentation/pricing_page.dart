import 'package:flutter/material.dart';
import 'package:lifer/shared/widgets/app_dropdown_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/app/theme/app_colors.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/features/pricing/application/pricing_models.dart';
import 'package:lifer/features/pricing/application/pricing_providers.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/app_line_chart.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class PricingPage extends ConsumerStatefulWidget {
  const PricingPage({super.key});

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  final _productSearchController = TextEditingController();

  @override
  void dispose() {
    _productSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProduct = ref.watch(selectedPricingProductProvider).valueOrNull;
    final selectedRange = ref.watch(selectedPricingRangeProvider);
    final customRange = ref.watch(customPricingDateRangeProvider);
    final selectedChannelKey = ref.watch(selectedPricingChannelKeyProvider);
    final pricePoints = ref.watch(selectedProductPricePointsProvider);
    final priceStats = ref.watch(selectedProductPriceStatsProvider);
    final recentRecords =
        ref.watch(recentPriceRecordItemsProvider).valueOrNull ?? const <RecentPriceRecordViewData>[];
    final channelSummary =
        ref.watch(channelPriceSummaryProvider).valueOrNull ?? const <ChannelPriceViewData>[];
    final spendingBreakdown = ref.watch(spendingBreakdownProvider);

    return AppPageScaffold(
      title: '价格',
      onRefresh: () async {
        ref.invalidate(activeProductsProvider);
        ref.invalidate(selectedPricingProductProvider);
        ref.invalidate(selectedProductPriceRecordsProvider);
        ref.invalidate(selectedProductDurableUsageProvider);
        ref.invalidate(selectedProductPricePointsProvider);
        ref.invalidate(selectedProductPriceStatsProvider);
        ref.invalidate(recentPriceRecordItemsProvider);
        ref.invalidate(channelPriceSummaryProvider);
        ref.invalidate(spendingBreakdownProvider);
      },
      actions: [
        IconButton(
          onPressed: () {
            final productId = ref.read(selectedPricingProductIdProvider);
            final uri = Uri(
              path: '/pricing/record/edit',
              queryParameters: productId == null ? null : {'productId': productId},
            );
            context.push(uri.toString());
          },
          icon: const Icon(Icons.add_chart_rounded),
          tooltip: '记录价格',
        ),
        IconButton(
          onPressed: () => context.push('/pricing/channels'),
          icon: const Icon(Icons.storefront_outlined),
          tooltip: '渠道管理',
        ),
      ],
      children: [
        Builder(
          builder: (context) {
            final allProducts = ref.watch(activeProductsProvider).valueOrNull ?? const [];
            final query = _productSearchController.text.trim().toLowerCase();
            final products = query.isEmpty
                ? allProducts
                : allProducts
                    .where((p) => ('${p.name} ${p.alias ?? ''}').toLowerCase().contains(query))
                    .toList();
            final currentId = ref.watch(selectedPricingProductIdProvider);
            final selectedValue = products.any((item) => item.id == currentId) ? currentId : null;

            return Column(
              children: [
                TextField(
                  controller: _productSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '搜索商品',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                AppDropdownField<String>(






                  value: selectedValue,
                  decoration: const InputDecoration(labelText: '选择商品'),
                  items: products
                      .map(
                        (product) => DropdownMenuItem<String>(
                          value: product.id,
                          child: Text(product.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    ref.read(selectedPricingProductIdProvider.notifier).state = value;
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.item),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<PricingRange>(
            showSelectedIcon: false,
            segments: PricingRange.values
                .map((range) => ButtonSegment(value: range, label: Text(range.label)))
                .toList(),
            selected: {selectedRange},
            onSelectionChanged: (selection) {
              ref.read(selectedPricingRangeProvider.notifier).state = selection.first;
            },
          ),
        ),
        const SizedBox(height: AppSpacing.item),
        if (selectedRange == PricingRange.custom)
          _CustomDateRangePicker(range: customRange)
        else
          _QuickDateActions(selectedRange: selectedRange),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '价格曲线',
          subtitle: selectedProduct == null ? '先选择商品' : '${selectedProduct.name} · ${selectedRange.label}',
          child: _PriceLineChart(
            points: pricePoints,
            currencyCode: selectedProduct?.currencyCode,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '价格摘要',
          subtitle: '按当前时间范围统计',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(label: '记录数', value: '${priceStats.recordCount}'),
              _StatChip(
                label: '最近价格',
                value: _formatMinor(priceStats.latestAmountMinor, selectedProduct?.currencyCode),
              ),
              _StatChip(
                label: '范围最低',
                value: _formatMinor(priceStats.lowestAmountMinor, selectedProduct?.currencyCode),
              ),
              _StatChip(
                label: '范围最高',
                value: _formatMinor(priceStats.highestAmountMinor, selectedProduct?.currencyCode),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '渠道对比',
          subtitle: selectedChannelKey == null ? '点击渠道即可筛选' : '当前已按渠道筛选',
          child: _ChannelSummaryList(
            items: channelSummary,
            selectedChannelKey: selectedChannelKey,
            currencyCode: selectedProduct?.currencyCode,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '支出趋势',
          subtitle: '按月份汇总当前筛选范围内的价格记录',
          child: _SpendingBreakdown(
            items: spendingBreakdown,
            currencyCode: selectedProduct?.currencyCode,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '最近价格记录',
          subtitle: selectedProduct == null ? '先选择商品' : selectedProduct.name,
          child: selectedProduct == null
              ? const ListTile(
                  title: Text('请先选择商品'),
                  subtitle: Text('选择后可查看并编辑该商品最近价格记录。'),
                )
              : _RecentPriceRecordList(
                  productId: selectedProduct.id,
                  items: recentRecords,
                ),
        ),
      ],
    );
  }
}

class _CustomDateRangePicker extends ConsumerWidget {
  const _CustomDateRangePicker({
    required this.range,
  });

  final PricingDateRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: range.start ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    ref.read(customPricingDateRangeProvider.notifier).state =
                        range.copyWith(start: picked);
                  }
                },
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  range.start == null
                      ? '开始日期'
                      : Formatters.fullDateFromMillis(range.start!.millisecondsSinceEpoch),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: range.end ?? range.start ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final endOfDay = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      23,
                      59,
                      59,
                    );
                    ref.read(customPricingDateRangeProvider.notifier).state =
                        range.copyWith(end: endOfDay);
                  }
                },
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  range.end == null
                      ? '结束日期'
                      : Formatters.fullDateFromMillis(range.end!.millisecondsSinceEpoch),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(customPricingDateRangeProvider.notifier).state =
                    const PricingDateRange();
              },
              icon: const Icon(Icons.clear_rounded),
              tooltip: '清空日期',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _RangeHint(start: range.start, end: range.end),
      ],
    );
  }
}

class _QuickDateActions extends ConsumerWidget {
  const _QuickDateActions({
    required this.selectedRange,
  });

  final PricingRange selectedRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          label: const Text('清空渠道筛选'),
          onPressed: () {
            ref.read(selectedPricingChannelKeyProvider.notifier).state = null;
          },
        ),
        ActionChip(
          label: Text('当前范围 ${selectedRange.label}'),
          onPressed: null,
        ),
      ],
    );
  }
}

class _RecentPriceRecordList extends StatelessWidget {
  const _RecentPriceRecordList({
    required this.productId,
    required this.items,
  });

  final String productId;
  final List<RecentPriceRecordViewData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const ListTile(
        title: Text('暂无价格记录'),
        subtitle: Text('录入补货或价格后，这里会显示最近变动。'),
      );
    }

    return Column(
      children: items
          .map(
            (item) => ListTile(
              onTap: () {
                final uri = Uri(
                  path: '/pricing/record/edit',
                  queryParameters: {
                    'id': item.recordId,
                    'productId': productId,
                    'date': item.dateLabel,
                    'price': item.priceLabel,
                    'channel': item.channelLabel,
                    'quantity': item.quantityLabel,
                  },
                );
                context.push(uri.toString());
              },
              contentPadding: EdgeInsets.zero,
              title: Text(item.dateLabel),
              subtitle: Text('${item.channelLabel} · ${item.quantityLabel}'),
              trailing: Text(
                item.priceLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ChannelSummaryList extends StatelessWidget {
  const _ChannelSummaryList({
    required this.items,
    required this.selectedChannelKey,
    required this.currencyCode,
  });

  final List<ChannelPriceViewData> items;
  final String? selectedChannelKey;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const ListTile(
        title: Text('暂无渠道数据'),
        subtitle: Text('录入不同渠道的价格后，这里会自动汇总。'),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Consumer(
              builder: (context, ref, child) {
                final selected = selectedChannelKey == item.channelKey;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.secondary.withOpacity(0.08) : Colors.transparent,

                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    onTap: () {
                      ref.read(selectedPricingChannelKeyProvider.notifier).state =
                          selected ? null : item.channelKey;
                    },
                    title: Text(item.channelName),
                    subtitle: Text(
                      '记录 ${item.recordCount} 次 · 最低 ${_formatMinor(item.lowestAmountMinor, currencyCode)}',
                    ),
                    trailing: Text(
                      _formatMinor(item.latestAmountMinor, currencyCode),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }
}

class _RangeHint extends StatelessWidget {
  const _RangeHint({
    required this.start,
    required this.end,
  });

  final DateTime? start;
  final DateTime? end;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '开始 ${start == null ? '--' : Formatters.fullDateFromMillis(start!.millisecondsSinceEpoch)}',
          ),
        ),
        Expanded(
          child: Text(
            '结束 ${end == null ? '--' : Formatters.fullDateFromMillis(end!.millisecondsSinceEpoch)}',
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  const _PriceLineChart({
    required this.points,
    required this.currencyCode,
  });

  final List<PricePointViewData> points;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text('暂无可绘制的价格数据'),
        ),
      );
    }

    return AppLineChart(
      points: [
        for (var i = 0; i < points.length; i++)
          AppLinePoint(
            x: i.toDouble(),
            y: points[i].amountMinor / 100,
            label: points[i].label,
            tooltip:
                '${Formatters.fullDateFromMillis(points[i].timestamp)}\n${Formatters.currencyFromMinor(points[i].amountMinor, currencyCode: currencyCode)}',
          ),
      ],
      color: Theme.of(context).colorScheme.secondary,
      showBottomLabelAt: (index, length) => _xAxisMarkerIndexes(length).contains(index),
    );
  }
}

Set<int> _xAxisMarkerIndexes(int length) {
  if (length <= 1) return {0};
  if (length <= 4) return {for (var i = 0; i < length; i++) i};
  return {
    0,
    (length * 0.25).round().clamp(0, length - 1),
    (length * 0.5).round().clamp(0, length - 1),
    (length * 0.75).round().clamp(0, length - 1),
    length - 1,
  };
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SpendingBreakdown extends StatelessWidget {
  const _SpendingBreakdown({
    required this.items,
    required this.currencyCode,
  });

  final List<SpendingBreakdownViewData> items;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;

    if (items.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('暂无支出趋势'),
        subtitle: Text('选择商品并录入价格记录后，这里会按月份自动汇总。'),
      );
    }

    return Column(
      children: [
        for (final row in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(row.label, style: style)),
                    Text(_formatMinor(row.amountMinor, currencyCode), style: style),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: row.ratio.clamp(0, 1),
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

String _formatMinor(int? amountMinor, String? currencyCode) {
  return Formatters.currencyFromMinor(amountMinor, currencyCode: currencyCode);
}



