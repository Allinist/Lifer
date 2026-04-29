import 'package:flutter/material.dart';
import 'package:lifer/shared/widgets/app_dropdown_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/app/theme/app_colors.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/inventory/application/inventory_models.dart';
import 'package:lifer/features/inventory/application/inventory_providers.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProducts = ref.watch(filteredInventoryProductsProvider);
    final batches = ref.watch(selectedInventoryBatchCardsProvider);
    final usagePeriods = ref.watch(selectedInventoryUsageCardsProvider);
    final segment = ref.watch(inventorySegmentProvider);

    return AppPageScaffold(
      title: '库存',
      onRefresh: () async {
        ref.invalidate(inventoryProductsProvider);
        ref.invalidate(selectedInventoryBatchesProvider);
        ref.invalidate(selectedInventoryUsageProvider);
      },
      actions: [
        IconButton(
          onPressed: () {
            final productId = ref.read(selectedInventoryProductIdProvider);
            final uri = Uri(
              path: '/restock/create',
              queryParameters: productId == null ? null : {'productId': productId},
            );
            context.push(uri.toString());
          },
          icon: const Icon(Icons.add_shopping_cart_outlined),
          tooltip: '记录补货',
        ),
        IconButton(
          onPressed: () {
            final productId = ref.read(selectedInventoryProductIdProvider);
            final uri = Uri(
              path: '/consume/create',
              queryParameters: productId == null ? null : {'productId': productId},
            );
            context.push(uri.toString());
          },
          icon: const Icon(Icons.remove_shopping_cart_outlined),
          tooltip: '记录消耗',
        ),
        IconButton(
          onPressed: () => context.push('/reminder-rules'),
          icon: const Icon(Icons.notifications_active_outlined),
          tooltip: '提醒规则',
        ),
      ],
      children: [
        _SearchAndSegment(products: filteredProducts),
        const SizedBox(height: AppSpacing.section),
        if (segment == InventorySegment.consumable)
          _ConsumableSection(batches: batches)
        else
          _DurableSection(usagePeriods: usagePeriods),
      ],
    );
  }
}

class _SearchAndSegment extends ConsumerWidget {
  const _SearchAndSegment({
    required this.products,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId = ref.watch(selectedInventoryProductIdProvider);
    final selectedValue = products.any((product) => product.id == currentId) ? currentId : null;

    return Column(
      children: [
        TextField(
          onChanged: (value) {
            ref.read(inventorySearchQueryProvider.notifier).state = value;
          },
          decoration: const InputDecoration(
            hintText: '搜索商品、位置或渠道',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<InventorySegment>(
            showSelectedIcon: false,
            segments: InventorySegment.values
                .map((segment) => ButtonSegment(value: segment, label: Text(segment.label)))
                .toList(),
            selected: {ref.watch(inventorySegmentProvider)},
            onSelectionChanged: (selection) {
              ref.read(inventorySegmentProvider.notifier).state = selection.first;
              ref.read(selectedInventoryProductIdProvider.notifier).state = null;
            },
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
            ref.read(selectedInventoryProductIdProvider.notifier).state = value;
          },
        ),
      ],
    );
  }
}

class _ConsumableSection extends StatelessWidget {
  const _ConsumableSection({
    required this.batches,
  });

  final List<InventoryBatchViewData> batches;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '消耗品',
      subtitle: '库存、批次、保质期、存放位置',
      child: batches.isEmpty
          ? const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('暂无批次数据'),
              subtitle: Text('选择消耗品商品并录入补货后，这里会显示真实库存批次。'),
            )
          : Column(
              children: batches
                  .map(
                    (batch) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InventoryTile(
                        productId: batch.productId,
                        title: batch.title,
                        summary: batch.summary,
                        metric: batch.metric,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _DurableSection extends StatelessWidget {
  const _DurableSection({
    required this.usagePeriods,
  });

  final List<DurableUsageViewData> usagePeriods;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '常驻品',
      subtitle: '使用周期和平均日开销',
      child: usagePeriods.isEmpty
          ? const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('暂无使用周期'),
              subtitle: Text('选择常驻品商品并录入使用周期后，这里会显示真实数据。'),
            )
          : Column(
              children: usagePeriods
                  .map(
                    (period) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InventoryTile(
                        productId: period.productId,
                        title: period.title,
                        summary: period.summary,
                        metric: period.metric,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.productId,
    required this.title,
    required this.summary,
    required this.metric,
  });

  final String productId;
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
            onPressed: () => context.push('/product/$productId'),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }
}



