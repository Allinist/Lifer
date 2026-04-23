import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/core/constants/app_spacing.dart';
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
          ],
        ),
      ),
    );
  }
}
