import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/product/application/product_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
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
  final _customCategoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _shelfLifeController = TextEditingController();
  final _notesController = TextEditingController();

  String _productType = 'consumable';
  bool _isPinnedHome = true;
  String? _selectedCategoryName;
  String? _selectedUnitSymbol;

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _customCategoryController.dispose();
    _brandController.dispose();
    _customUnitController.dispose();
    _targetPriceController.dispose();
    _shelfLifeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final categoryName = (_selectedCategoryName == '__custom__'
            ? _customCategoryController.text
            : _selectedCategoryName) ??
        _customCategoryController.text;
    final unitSymbol =
        (_selectedUnitSymbol == '__custom__' ? _customUnitController.text : _selectedUnitSymbol) ??
            _customUnitController.text;

    await ref.read(productActionsProvider).createProduct(
          name: _nameController.text,
          alias: _aliasController.text,
          productType: _productType,
          categoryName: categoryName,
          brand: _brandController.text,
          unitSymbol: unitSymbol,
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
    final categories = ref.watch(rootCategoriesProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider).valueOrNull ?? const [];
    final categoryValue = categories.any((item) => item.name == _selectedCategoryName)
        ? _selectedCategoryName
        : (_selectedCategoryName == '__custom__' ? '__custom__' : null);
    final unitValue = units.any((item) => item.symbol == _selectedUnitSymbol)
        ? _selectedUnitSymbol
        : (_selectedUnitSymbol == '__custom__' ? '__custom__' : null);

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
            DropdownButtonFormField<String>(
              value: categoryValue,
              decoration: const InputDecoration(labelText: '所属分类'),
              items: [
                ...categories.map(
                  (category) => DropdownMenuItem(
                    value: category.name,
                    child: Text(category.name),
                  ),
                ),
                const DropdownMenuItem(
                  value: '__custom__',
                  child: Text('新建分类'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryName = value;
                });
              },
            ),
            if (_selectedCategoryName == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCategoryController,
                decoration: const InputDecoration(labelText: '新分类名称'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(controller: _brandController, decoration: const InputDecoration(labelText: '品牌')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: unitValue,
              decoration: const InputDecoration(labelText: '默认单位'),
              items: [
                ...units.map(
                  (unit) => DropdownMenuItem(
                    value: unit.symbol,
                    child: Text('${unit.symbol} · ${unit.name}'),
                  ),
                ),
                const DropdownMenuItem(
                  value: '__custom__',
                  child: Text('新建单位'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedUnitSymbol = value;
                });
              },
            ),
            if (_selectedUnitSymbol == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customUnitController,
                decoration: const InputDecoration(labelText: '新单位符号'),
              ),
            ],
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
