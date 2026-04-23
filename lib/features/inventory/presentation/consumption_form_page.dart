import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/inventory/application/inventory_actions.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class ConsumptionFormPage extends ConsumerStatefulWidget {
  const ConsumptionFormPage({super.key});

  @override
  ConsumerState<ConsumptionFormPage> createState() => _ConsumptionFormPageState();
}

class _ConsumptionFormPageState extends ConsumerState<ConsumptionFormPage> {
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: '件');
  final _occurredAtController = TextEditingController();
  final _batchLabelController = TextEditingController();
  final _notesController = TextEditingController();

  String _usageType = 'normal';

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _occurredAtController.dispose();
    _batchLabelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(inventoryActionsProvider).createConsumption(
          productName: _productController.text,
          quantity: _quantityController.text,
          unitSymbol: _unitController.text,
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
    return FormPageScaffold(
      title: '消耗',
      primaryAction: _save,
      children: [
        FormSection(
          title: '消耗信息',
          children: [
            TextField(controller: _productController, decoration: const InputDecoration(labelText: '商品')),
            const SizedBox(height: 12),
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: '消耗数量')),
            const SizedBox(height: 12),
            TextField(controller: _unitController, decoration: const InputDecoration(labelText: '单位')),
            const SizedBox(height: 12),
            TextField(controller: _occurredAtController, decoration: const InputDecoration(labelText: '消耗时间，例 2026-04-23')),
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
