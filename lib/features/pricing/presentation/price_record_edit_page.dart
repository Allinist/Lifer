import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/pricing/application/pricing_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class PriceRecordEditPage extends ConsumerStatefulWidget {
  const PriceRecordEditPage({
    this.recordId,
    this.productId,
    required this.recordDate,
    required this.price,
    required this.channel,
    required this.quantity,
    super.key,
  });

  final String? recordId;
  final String? productId;
  final String recordDate;
  final String price;
  final String channel;
  final String quantity;

  bool get isEditing => recordId != null && recordId!.isNotEmpty;

  @override
  ConsumerState<PriceRecordEditPage> createState() => _PriceRecordEditPageState();
}

class _PriceRecordEditPageState extends ConsumerState<PriceRecordEditPage> {
  late final TextEditingController _dateController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _customChannelController;
  late final TextEditingController _customUnitController;
  late final TextEditingController _customProductController;

  String? _selectedChannelName;
  String? _selectedUnitSymbol;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    final parsedQuantity = _parseQuantityLabel(widget.quantity);
    _dateController = TextEditingController(text: widget.recordDate);
    _priceController = TextEditingController(text: widget.price);
    _quantityController = TextEditingController(text: parsedQuantity.$1 ?? '');
    _customChannelController = TextEditingController();
    _customUnitController = TextEditingController();
    _customProductController = TextEditingController();
    _selectedChannelName = widget.channel == '未设置渠道' ? null : widget.channel;
    _selectedUnitSymbol = parsedQuantity.$2;
    _selectedProductId = (widget.productId == null || widget.productId!.isEmpty) ? null : widget.productId;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _customChannelController.dispose();
    _customUnitController.dispose();
    _customProductController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final channelName = _selectedChannelName == '__custom__'
        ? _customChannelController.text
        : (_selectedChannelName ?? '');
    final unitSymbol = _selectedUnitSymbol == '__custom__'
        ? _customUnitController.text
        : _selectedUnitSymbol;
    final selectedProductId = _selectedProductId == '__custom__' ? null : _selectedProductId;
    final customProductName =
        _selectedProductId == '__custom__' ? _customProductController.text.trim() : null;

    await ref.read(pricingActionsProvider).savePriceRecord(
          recordId: widget.recordId,
          productId: selectedProductId,
          productName: customProductName,
          recordDate: _dateController.text,
          price: _priceController.text,
          quantity: _quantityController.text,
          unitSymbol: unitSymbol,
          channelName: channelName,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final recordId = widget.recordId;
    if (recordId == null || recordId.isEmpty) return;
    await ref.read(pricingActionsProvider).deletePriceRecord(recordId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider).valueOrNull ?? const [];
    final channels = ref.watch(channelsProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider).valueOrNull ?? const [];
    final selectedProductValue = products.any((item) => item.id == _selectedProductId)
        ? _selectedProductId
        : (_selectedProductId == '__custom__' ? '__custom__' : null);
    final selectedChannelValue = channels.any((item) => item.name == _selectedChannelName)
        ? _selectedChannelName
        : (_selectedChannelName == '__custom__' ? '__custom__' : null);
    final selectedUnitValue = units.any((item) => item.symbol == _selectedUnitSymbol)
        ? _selectedUnitSymbol
        : (_selectedUnitSymbol == '__custom__' ? '__custom__' : null);

    return FormPageScaffold(
      title: widget.isEditing ? '编辑价格记录' : '新增价格记录',
      primaryAction: _save,
      children: [
        FormSection(
          title: '价格信息',
          children: [
            DropdownButtonFormField<String>(
              value: selectedProductValue,
              decoration: const InputDecoration(labelText: '关联商品'),
              items: [
                ...products.map(
                  (product) => DropdownMenuItem(
                    value: product.id,
                    child: Text(product.name),
                  ),
                ),
                const DropdownMenuItem(value: '__custom__', child: Text('新建计价商品')),
              ],
              onChanged: (value) => setState(() => _selectedProductId = value),
            ),
            if (_selectedProductId == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customProductController,
                decoration: const InputDecoration(labelText: '计价商品名称'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: '购买日期'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: '价格'),
            ),
          ],
        ),
        FormSection(
          title: '购买信息',
          children: [
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: '数量'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedUnitValue,
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
            DropdownButtonFormField<String>(
              value: selectedChannelValue,
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
            if (widget.isEditing) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除这条价格记录'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

(String?, String?) _parseQuantityLabel(String input) {
  final text = input.trim();
  if (text.isEmpty || text == '--') return (null, null);
  final parts = text.split(RegExp(r'\s+'));
  final quantity = parts.isEmpty ? null : parts.first;
  final unit = parts.length > 1 ? parts.sublist(1).join(' ') : null;
  return (quantity, unit);
}
