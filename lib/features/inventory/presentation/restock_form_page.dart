import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/inventory/application/inventory_actions.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class RestockFormPage extends ConsumerStatefulWidget {
  const RestockFormPage({super.key});

  @override
  ConsumerState<RestockFormPage> createState() => _RestockFormPageState();
}

class _RestockFormPageState extends ConsumerState<RestockFormPage> {
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: '件');
  final _priceController = TextEditingController();
  final _channelController = TextEditingController();
  final _purchasedAtController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _channelController.dispose();
    _purchasedAtController.dispose();
    _expiryDateController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(inventoryActionsProvider).createRestock(
          productName: _productController.text,
          quantity: _quantityController.text,
          unitSymbol: _unitController.text,
          totalPrice: _priceController.text,
          channelName: _channelController.text,
          purchasedAt: _purchasedAtController.text,
          expiryDate: _expiryDateController.text,
          locationName: _locationController.text,
          notes: _notesController.text,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: '补货',
      primaryAction: _save,
      children: [
        FormSection(
          title: '商品与数量',
          children: [
            TextField(controller: _productController, decoration: const InputDecoration(labelText: '商品')),
            const SizedBox(height: 12),
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: '数量')),
            const SizedBox(height: 12),
            TextField(controller: _unitController, decoration: const InputDecoration(labelText: '单位')),
          ],
        ),
        FormSection(
          title: '价格与渠道',
          children: [
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: '总价')),
            const SizedBox(height: 12),
            TextField(controller: _channelController, decoration: const InputDecoration(labelText: '购买渠道')),
            const SizedBox(height: 12),
            TextField(controller: _purchasedAtController, decoration: const InputDecoration(labelText: '购买时间，例 2026-04-23')),
          ],
        ),
        FormSection(
          title: '批次信息',
          children: [
            TextField(controller: _expiryDateController, decoration: const InputDecoration(labelText: '保质期，例 2026-05-01')),
            const SizedBox(height: 12),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: '存放位置')),
            const SizedBox(height: 12),
            TextField(controller: _notesController, decoration: const InputDecoration(labelText: '批次备注')),
          ],
        ),
      ],
    );
  }
}
