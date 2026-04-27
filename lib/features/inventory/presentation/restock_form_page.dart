import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/inventory/application/inventory_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class RestockFormPage extends ConsumerStatefulWidget {
  const RestockFormPage({super.key});

  @override
  ConsumerState<RestockFormPage> createState() => _RestockFormPageState();
}

class _RestockFormPageState extends ConsumerState<RestockFormPage> {
  String? _selectedProductName;
  String? _selectedUnitSymbol;
  String? _selectedChannelName;

  final _customProductController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _priceController = TextEditingController();
  final _customChannelController = TextEditingController();
  final _purchasedAtController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _customProductController.dispose();
    _quantityController.dispose();
    _customUnitController.dispose();
    _priceController.dispose();
    _customChannelController.dispose();
    _purchasedAtController.dispose();
    _expiryDateController.dispose();
    _locationController.dispose();
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
    final channelName = (_selectedChannelName == '__custom__'
            ? _customChannelController.text
            : _selectedChannelName) ??
        _customChannelController.text;

    await ref.read(inventoryActionsProvider).createRestock(
          productName: productName,
          quantity: _quantityController.text,
          unitSymbol: unitSymbol,
          totalPrice: _priceController.text,
          channelName: channelName,
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
    final products = ref.watch(activeProductsProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider).valueOrNull ?? const [];
    final channels = ref.watch(channelsProvider).valueOrNull ?? const [];

    return FormPageScaffold(
      title: '补货',
      primaryAction: _save,
      children: [
        FormSection(
          title: '商品与数量',
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
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: '数量')),
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
          ],
        ),
        FormSection(
          title: '价格与渠道',
          children: [
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: '总价')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: channels.any((item) => item.name == _selectedChannelName)
                  ? _selectedChannelName
                  : (_selectedChannelName == '__custom__' ? '__custom__' : null),
              decoration: const InputDecoration(labelText: '购买渠道'),
              items: [
                ...channels.map(
                  (channel) => DropdownMenuItem(
                    value: channel.name,
                    child: Text(channel.name),
                  ),
                ),
                const DropdownMenuItem(value: '__custom__', child: Text('新建渠道')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedChannelName = value;
                });
              },
            ),
            if (_selectedChannelName == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customChannelController,
                decoration: const InputDecoration(labelText: '新渠道名称'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _purchasedAtController,
              decoration: const InputDecoration(labelText: '购买时间，例如 2026-04-23'),
            ),
          ],
        ),
        FormSection(
          title: '批次信息',
          children: [
            TextField(
              controller: _expiryDateController,
              decoration: const InputDecoration(labelText: '保质期，例如 2026-05-01'),
            ),
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
