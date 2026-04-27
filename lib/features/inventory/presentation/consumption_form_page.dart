import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/inventory/application/inventory_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class ConsumptionFormPage extends ConsumerStatefulWidget {
  const ConsumptionFormPage({super.key});

  @override
  ConsumerState<ConsumptionFormPage> createState() => _ConsumptionFormPageState();
}

class _ConsumptionFormPageState extends ConsumerState<ConsumptionFormPage> {
  String? _selectedProductName;
  String? _selectedUnitSymbol;

  final _customProductController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _occurredAtController = TextEditingController();
  final _batchLabelController = TextEditingController();
  final _notesController = TextEditingController();

  String _usageType = 'normal';

  @override
  void dispose() {
    _customProductController.dispose();
    _quantityController.dispose();
    _customUnitController.dispose();
    _occurredAtController.dispose();
    _batchLabelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final productName = (_selectedProductName == '__custom__'
            ? _customProductController.text
            : _selectedProductName) ??
        _customProductController.text;
    final unitSymbol =
        (_selectedUnitSymbol == '__custom__' ? _customUnitController.text : _selectedUnitSymbol) ??
            _customUnitController.text;

    await ref.read(inventoryActionsProvider).createConsumption(
          productName: productName,
          quantity: _quantityController.text,
          unitSymbol: unitSymbol,
          occurredAt: _occurredAtController.text,
          batchLabel: _batchLabelController.text,
          usageType: _usageType,
          notes: _notesController.text,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider).valueOrNull ?? const [];

    return FormPageScaffold(
      title: '消耗',
      primaryAction: _save,
      children: [
        FormSection(
          title: '消耗信息',
          children: [
            DropdownButtonFormField<String>(
              value: products.any((item) => item.name == _selectedProductName)
                  ? _selectedProductName
                  : (_selectedProductName == '__custom__' ? '__custom__' : null),
              decoration: const InputDecoration(labelText: '商品'),
              items: [
                ...products.map(
                  (product) => DropdownMenuItem(
                    value: product.name,
                    child: Text(product.name),
                  ),
                ),
                const DropdownMenuItem(value: '__custom__', child: Text('新建商品')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProductName = value;
                });
              },
            ),
            if (_selectedProductName == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customProductController,
                decoration: const InputDecoration(labelText: '新商品名称'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: '消耗数量')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: units.any((item) => item.symbol == _selectedUnitSymbol)
                  ? _selectedUnitSymbol
                  : (_selectedUnitSymbol == '__custom__' ? '__custom__' : null),
              decoration: const InputDecoration(labelText: '单位'),
              items: [
                ...units.map(
                  (unit) => DropdownMenuItem(
                    value: unit.symbol,
                    child: Text('${unit.symbol} · ${unit.name}'),
                  ),
                ),
                const DropdownMenuItem(value: '__custom__', child: Text('新建单位')),
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
            const SizedBox(height: 12),
            TextField(
              controller: _occurredAtController,
              decoration: const InputDecoration(labelText: '消耗时间，例如 2026-04-23'),
            ),
          ],
        ),
        FormSection(
          title: '批次与用途',
          children: [
            TextField(controller: _batchLabelController, decoration: const InputDecoration(labelText: '批次')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _usageType,
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('正常消耗')),
                DropdownMenuItem(value: 'recipe', child: Text('菜谱使用')),
                DropdownMenuItem(value: 'waste', child: Text('浪费')),
              ],
              onChanged: (value) => setState(() => _usageType = value ?? 'normal'),
              decoration: const InputDecoration(labelText: '用途'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '备注'),
            ),
          ],
        ),
      ],
    );
  }
}
