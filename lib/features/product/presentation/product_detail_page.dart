import 'package:flutter/material.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    required this.productId,
    super.key,
  });

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品详情')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pageInsets,
          children: [
            Text(
              '商品 ID: $productId',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '基础信息',
              child: ListTile(
                title: Text('牛奶'),
                subtitle: Text('消耗品 · 厨房食材 / 乳制品'),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionCard(
              title: '价格与库存',
              child: Column(
                children: [
                  ListTile(
                    title: Text('最近一次购买价格'),
                    trailing: Text('12.80'),
                  ),
                  ListTile(
                    title: Text('当前库存'),
                    trailing: Text('2 盒'),
                  ),
                  ListTile(
                    title: Text('最近到期'),
                    trailing: Text('3 天后'),
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
                    onPressed: null,
                    icon: Icon(Icons.add_shopping_cart_rounded),
                    label: Text('补货'),
                  ),
                  FilledButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.remove_circle_outline_rounded),
                    label: Text('消耗'),
                  ),
                  FilledButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.notifications_active_outlined),
                    label: Text('提醒'),
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
