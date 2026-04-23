import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/product/application/product_actions.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _nameController = TextEditingController();
  final _aliasController = TextEditingController();
  final _categoryController = TextEditingController(text: '未分类');
  final _brandController = TextEditingController();
  final _unitController = TextEditingController(text: '件');
  final _targetPriceController = TextEditingController();
  final _shelfLifeController = TextEditingController();
  final _notesController = TextEditingController();

  String _productType = 'consumable';
  bool _isPinnedHome = true;

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _targetPriceController.dispose();
    _shelfLifeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(productActionsProvider).createProduct(
          name: _nameController.text,
          alias: _aliasController.text,
          productType: _productType,
          categoryName: _categoryController.text,
          brand: _brandController.text,
          unitSymbol: _unitController.text,
          targetPrice: _targetPriceController.text,
          shelfLifeDays: _shelfLifeController.text,
          isPinnedHome: _isPinnedHome,
          notes: _notesController.text,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: '新增商品',
      primaryAction: _save,
      children: [
        FormSection(
          title: '基础信息',
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '商品名称')),
            const SizedBox(height: 12),
            TextField(controller: _aliasController, decoration: const InputDecoration(labelText: '别名')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _productType,
              items: const [
                DropdownMenuItem(value: 'consumable', child: Text('消耗品')),
                DropdownMenuItem(value: 'durable', child: Text('常驻品')),
              ],
              onChanged: (value) => setState(() => _productType = value ?? 'consumable'),
              decoration: const InputDecoration(labelText: '商品类型'),
            ),
          ],
        ),
        FormSection(
          title: '归属与展示',
          children: [
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: '所属分类')),
            const SizedBox(height: 12),
            TextField(controller: _brandController, decoration: const InputDecoration(labelText: '品牌')),
            const SizedBox(height: 12),
            TextField(controller: _unitController, decoration: const InputDecoration(labelText: '默认单位')),
          ],
        ),
        FormSection(
          title: '策略信息',
          subtitle: '价格目标、保质期和首页固定状态',
          children: [
            TextField(controller: _targetPriceController, decoration: const InputDecoration(labelText: '目标价格')),
            const SizedBox(height: 12),
            TextField(controller: _shelfLifeController, decoration: const InputDecoration(labelText: '默认保质期（天）')),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isPinnedHome,
              onChanged: (value) => setState(() => _isPinnedHome = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('固定到首页'),
            ),
          ],
        ),
        FormSection(
          title: '备注',
          children: [
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '备注'),
            ),
          ],
        ),
      ],
    );
  }
}
