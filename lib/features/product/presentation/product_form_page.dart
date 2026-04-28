import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/product/application/product_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

final productFormInitialDataProvider =
    FutureProvider.family<_ProductFormInitialData?, String>((ref, productId) async {
  final db = ref.watch(appDatabaseProvider);
  final product = await ((db.select(db.products))..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
  if (product == null) {
    return null;
  }

  final category = await ((db.select(db.categories))..where((tbl) => tbl.id.equals(product.categoryId)))
      .getSingleOrNull();
  final unit = product.unitId == null
      ? null
      : await ((db.select(db.units))..where((tbl) => tbl.id.equals(product.unitId!))).getSingleOrNull();

  return _ProductFormInitialData(
    product: product,
    categoryName: category?.name,
    unitSymbol: unit?.symbol,
  );
});

class _ProductFormInitialData {
  const _ProductFormInitialData({
    required this.product,
    required this.categoryName,
    required this.unitSymbol,
  });

  final Product product;
  final String? categoryName;
  final String? unitSymbol;
}

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({
    this.productId,
    this.initialProductType,
    super.key,
  });

  final String? productId;
  final String? initialProductType;

  bool get isEditing => productId != null && productId!.isNotEmpty;

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
  bool _didHydrate = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialProductType ?? '').trim().isNotEmpty) {
      _productType = widget.initialProductType!.trim();
    }
  }

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

  void _hydrate({
    required String? categoryName,
    required String? unitSymbol,
    required String name,
    required String? alias,
    required String productType,
    required String? brand,
    required int? targetPriceMinor,
    required int? shelfLifeDays,
    required bool isPinnedHome,
    required String? notes,
  }) {
    if (_didHydrate) return;
    _didHydrate = true;
    _nameController.text = name;
    _aliasController.text = alias ?? '';
    _brandController.text = brand ?? '';
    _targetPriceController.text =
        targetPriceMinor == null ? '' : (targetPriceMinor / 100).toStringAsFixed(2);
    _shelfLifeController.text = shelfLifeDays?.toString() ?? '';
    _notesController.text = notes ?? '';
    _productType = productType;
    _isPinnedHome = isPinnedHome;
    _selectedCategoryName = categoryName;
    _selectedUnitSymbol = unitSymbol;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final categoryName = ((_selectedCategoryName == '__custom__'
            ? _customCategoryController.text
            : _selectedCategoryName) ??
        _customCategoryController.text)
        .trim();
    final unitSymbol = (((_selectedUnitSymbol == '__custom__'
                ? _customUnitController.text
                : _selectedUnitSymbol) ??
            _customUnitController.text))
        .trim();

    if (name.isEmpty) {
      _showError('请填写商品名称');
      return;
    }
    if (categoryName.isEmpty) {
      _showError('请先选择或新建分类');
      return;
    }
    if (unitSymbol.isEmpty) {
      _showError('请先选择或新建单位');
      return;
    }

    final isEditing = widget.isEditing;
    setState(() => _isSaving = true);
    try {
      if (isEditing) {
        await ref.read(productActionsProvider).updateProduct(
              productId: widget.productId!,
              name: name,
              alias: _aliasController.text,
              productType: _productType,
              categoryName: categoryName,
              brand: _brandController.text,
              unitSymbol: unitSymbol,
              targetPrice: _targetPriceController.text,
              shelfLifeDays: _productType == 'consumable' ? _shelfLifeController.text : '',
              isPinnedHome: _isPinnedHome,
              notes: _notesController.text,
            );
      } else {
        final createdProductId = await ref.read(productActionsProvider).createProduct(
              name: name,
              alias: _aliasController.text,
              productType: _productType,
              categoryName: categoryName,
              brand: _brandController.text,
              unitSymbol: unitSymbol,
              targetPrice: _targetPriceController.text,
              shelfLifeDays: _productType == 'consumable' ? _shelfLifeController.text : '',
              isPinnedHome: _isPinnedHome,
              notes: _notesController.text,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('商品已创建')),
          );
          context.go('/product/$createdProductId');
        }
        return;
      }
    } catch (error) {
      _showError(error.toString().replaceFirst('Bad state: ', ''));
      setState(() => _isSaving = false);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品已更新')),
      );
      Navigator.of(context).pop();
    }
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(rootCategoriesProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider).valueOrNull ?? const [];
    final initialData =
        widget.isEditing ? ref.watch(productFormInitialDataProvider(widget.productId!)).valueOrNull : null;

    if (widget.isEditing && initialData != null && !_didHydrate) {
      _hydrate(
        categoryName: initialData.categoryName,
        unitSymbol: initialData.unitSymbol,
        name: initialData.product.name,
        alias: initialData.product.alias,
        productType: initialData.product.productType,
        brand: initialData.product.brand,
        targetPriceMinor: initialData.product.expectedPriceMinor,
        shelfLifeDays: initialData.product.defaultShelfLifeDays,
        isPinnedHome: initialData.product.isPinnedHome,
        notes: initialData.product.notes,
      );
    }

    final categoryValue = categories.any((item) => item.name == _selectedCategoryName)
        ? _selectedCategoryName
        : (_selectedCategoryName == '__custom__' ? '__custom__' : null);
    final unitValue = units.any((item) => item.symbol == _selectedUnitSymbol)
        ? _selectedUnitSymbol
        : (_selectedUnitSymbol == '__custom__' ? '__custom__' : null);

    return FormPageScaffold(
      title: widget.isEditing ? '编辑商品' : '新增商品',
      primaryAction: _save,
      isSubmitting: _isSaving,
      children: [
        FormSection(
          title: '基础信息',
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: '商品名称')),
            const SizedBox(height: 12),
            TextField(controller: _aliasController, decoration: const InputDecoration(labelText: '别名')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_productType),
              initialValue: _productType,
              items: const [
                DropdownMenuItem(value: 'consumable', child: Text('消耗品')),
                DropdownMenuItem(value: 'durable', child: Text('常驻品')),
                DropdownMenuItem(value: 'pricing_only', child: Text('计价品')),
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
          subtitle: _productType == 'consumable'
              ? '价格目标、保质期和首页固定状态'
              : '价格目标和首页固定状态',
          children: [
            TextField(
              controller: _targetPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(labelText: _productType == 'consumable' ? '目标价格' : '参考购入价格'),
            ),
            if (_productType == 'consumable') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _shelfLifeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '默认保质期（天）'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                '常驻品不设置保质期，可在库存页记录使用周期与日均开销。',
                style: TextStyle(color: Colors.black54),
              ),
            ],
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
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: '备注')),
          ],
        ),
      ],
    );
  }
}
