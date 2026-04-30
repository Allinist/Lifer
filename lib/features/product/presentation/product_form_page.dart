import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:drift/drift.dart' show OrderingMode, OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/product/application/product_actions.dart';
import 'package:lifer/features/product/presentation/widgets/product_form_fields.dart';
import 'package:lifer/features/settings/application/settings_providers.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';

final productFormInitialDataProvider =
    FutureProvider.family<_ProductFormInitialData?, String>((ref, productId) async {
  final db = ref.watch(appDatabaseProvider);
  final product = await ((db.select(db.products))..where((tbl) => tbl.id.equals(productId))).getSingleOrNull();
  if (product == null) return null;
  final category = await ((db.select(db.categories))..where((tbl) => tbl.id.equals(product.categoryId))).getSingleOrNull();
  final unit = product.unitId == null ? null : await ((db.select(db.units))..where((tbl) => tbl.id.equals(product.unitId!))).getSingleOrNull();
  final usage = await ((db.select(db.durableUsagePeriods))
        ..where((tbl) => tbl.productId.equals(product.id))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc)])
        ..limit(1))
      .getSingleOrNull();
  return _ProductFormInitialData(
    product: product,
    categoryName: category?.name,
    unitSymbol: unit?.symbol,
    durablePurchasedAt: usage?.startAt,
  );
});

class _ProductFormInitialData {
  const _ProductFormInitialData({
    required this.product,
    required this.categoryName,
    required this.unitSymbol,
    required this.durablePurchasedAt,
  });
  final Product product;
  final String? categoryName;
  final String? unitSymbol;
  final int? durablePurchasedAt;
}

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({this.productId, this.initialProductType, super.key});
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
  final _durablePurchasedAtController = TextEditingController();

  String _productType = 'consumable';
  bool _isPinnedHome = true;
  String? _selectedCategoryName;
  String? _selectedUnitSymbol;
  String _logoUri = 'bag';
  String _consumablePriceMode = 'total';
  String _currencyCode = 'CNY';
  bool _didHydrate = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if ((widget.initialProductType ?? '').trim().isNotEmpty) _productType = widget.initialProductType!.trim();
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
    _durablePurchasedAtController.dispose();
    super.dispose();
  }

  void _hydrate(_ProductFormInitialData data) {
    if (_didHydrate) return;
    _didHydrate = true;
    _nameController.text = data.product.name;
    _aliasController.text = data.product.alias ?? '';
    _brandController.text = data.product.brand ?? '';
    _targetPriceController.text = data.product.expectedPriceMinor == null ? '' : (data.product.expectedPriceMinor! / 100).toStringAsFixed(2);
    _shelfLifeController.text = data.product.defaultShelfLifeDays?.toString() ?? '';
    _notesController.text = data.product.notes ?? '';
    _productType = data.product.productType;
    _isPinnedHome = data.product.isPinnedHome;
    _selectedCategoryName = data.categoryName;
    _selectedUnitSymbol = data.unitSymbol;
    _logoUri = data.product.logoUri ?? 'bag';
    final metadata = _parseMetadata(data.product.metadataJson);
    _consumablePriceMode = (metadata['consumablePriceMode'] as String?) ?? 'total';
    _currencyCode = (data.product.currencyCode ?? 'CNY').toUpperCase();
    final picked = data.durablePurchasedAt ?? data.product.createdAt;
    _durablePurchasedAtController.text =
        DateTime.fromMillisecondsSinceEpoch(picked).toIso8601String().split('T').first;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final categoryName = ((_selectedCategoryName == '__custom__' ? _customCategoryController.text : _selectedCategoryName) ?? _customCategoryController.text).trim();
    final unitSymbol = ((_selectedUnitSymbol == '__custom__' ? _customUnitController.text : _selectedUnitSymbol) ?? _customUnitController.text).trim();
    if (name.isEmpty) return _showError('请填写商品名称');
    if (categoryName.isEmpty) return _showError('请先选择或新建分类');
    if (unitSymbol.isEmpty) return _showError('请先选择或新建单位');

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
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
              logoUri: _logoUri,
              durablePurchasedAt: _durablePurchasedAtController.text,
              consumablePriceMode: _consumablePriceMode,
              currencyCode: _currencyCode,
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
              logoUri: _logoUri,
              durablePurchasedAt: _durablePurchasedAtController.text,
              consumablePriceMode: _consumablePriceMode,
              currencyCode: _currencyCode,
            );
        if (!mounted) return;
        final nextAction = await _showPostCreateActions(context);
        if (!mounted) return;
        switch (nextAction) {
          case 'restock': context.push('/restock/create?productId=$createdProductId'); return;
          case 'pricing': context.push('/pricing/record/edit?productId=$createdProductId'); return;
          case 'reminder': context.push('/reminder-rule/create?productId=$createdProductId'); return;
          default: context.push('/product/$createdProductId'); return;
        }
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Bad state: ', ''));
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isEditing ? '商品已更新' : '商品已创建')));
      if (widget.isEditing) Navigator.of(context).pop();
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(rootCategoriesProvider).valueOrNull ?? const <Category>[];
    final units = ref.watch(unitsProvider).valueOrNull ?? const <Unit>[];
    final appSettings = ref.watch(appSettingsStreamProvider).valueOrNull;
    if (!_didHydrate && !widget.isEditing) { _currencyCode = (appSettings?.currencyCode ?? 'CNY').toUpperCase(); }
    final initialData = widget.isEditing ? ref.watch(productFormInitialDataProvider(widget.productId!)).valueOrNull : null;
    if (widget.isEditing && initialData != null) _hydrate(initialData);

    return FormPageScaffold(
      title: widget.isEditing ? '编辑商品' : '新增商品',
      primaryAction: _save,
      isSubmitting: _isSaving,
      children: [
        ProductFormFields(
          categories: categories,
          units: units,
          nameController: _nameController,
          aliasController: _aliasController,
          customCategoryController: _customCategoryController,
          brandController: _brandController,
          customUnitController: _customUnitController,
          targetPriceController: _targetPriceController,
          shelfLifeController: _shelfLifeController,
          notesController: _notesController,
          durablePurchasedAtController: _durablePurchasedAtController,
          productType: _productType,
          isPinnedHome: _isPinnedHome,
          selectedCategoryName: _selectedCategoryName,
          selectedUnitSymbol: _selectedUnitSymbol,
          logoUri: _logoUri,
          onProductTypeChanged: (v) => setState(() => _productType = v),
          onPinnedChanged: (v) => setState(() => _isPinnedHome = v),
          onCategoryChanged: (v) => setState(() => _selectedCategoryName = v),
          onUnitChanged: (v) => setState(() => _selectedUnitSymbol = v),
          onLogoChanged: (v) => setState(() => _logoUri = v),
          consumablePriceMode: _consumablePriceMode,
          currencyCode: _currencyCode,
          onConsumablePriceModeChanged: (v) => setState(() => _consumablePriceMode = v),
          onCurrencyCodeChanged: (v) => setState(() => _currencyCode = v),
        ),
      ],
    );
  }
}

Future<String?> _showPostCreateActions(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('商品已创建，下一步要做什么？')),
          ListTile(leading: const Icon(Icons.add_shopping_cart_outlined), title: const Text('去补货'), onTap: () => Navigator.of(context).pop('restock')),
          ListTile(leading: const Icon(Icons.sell_outlined), title: const Text('去计价'), onTap: () => Navigator.of(context).pop('pricing')),
          ListTile(leading: const Icon(Icons.notifications_active_outlined), title: const Text('去设置提醒'), onTap: () => Navigator.of(context).pop('reminder')),
          ListTile(leading: const Icon(Icons.visibility_outlined), title: const Text('稍后，先看详情'), onTap: () => Navigator.of(context).pop('detail')),
        ],
      ),
    ),
  );
}

Map<String, dynamic> _parseMetadata(String? raw) {
  if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(raw);
  return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
}




