import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/pricing/application/pricing_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class PriceRecordEditPage extends ConsumerStatefulWidget {
  const PriceRecordEditPage({
    required this.recordId,
    required this.recordDate,
    required this.price,
    required this.channel,
    required this.quantity,
    super.key,
  });

  final String recordId;
  final String recordDate;
  final String price;
  final String channel;
  final String quantity;

  @override
  ConsumerState<PriceRecordEditPage> createState() => _PriceRecordEditPageState();
}

class _PriceRecordEditPageState extends ConsumerState<PriceRecordEditPage> {
  late final TextEditingController _dateController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _customChannelController;
  late final TextEditingController _customUnitController;

  String? _selectedChannelName;
  String? _selectedUnitSymbol;

  @override
  void initState() {
    super.initState();
    final parsedQuantity = _parseQuantityLabel(widget.quantity);
    _dateController = TextEditingController(text: widget.recordDate);
    _priceController = TextEditingController(text: widget.price);
    _quantityController = TextEditingController(text: parsedQuantity.$1 ?? '');
    _customChannelController = TextEditingController();
    _customUnitController = TextEditingController();
    _selectedChannelName = widget.channel == '未设置渠道' ? null : widget.channel;
    _selectedUnitSymbol = parsedQuantity.$2;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _customChannelController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final channelName = _selectedChannelName == '__custom__'
        ? _customChannelController.text
        : (_selectedChannelName ?? '');
    final unitSymbol = _selectedUnitSymbol == '__custom__'
        ? _customUnitController.text
        : _selectedUnitSymbol;

    await ref.read(pricingActionsProvider).updatePriceRecord(
          recordId: widget.recordId,
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
    await ref.read(pricingActionsProvider).deletePriceRecord(widget.recordId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(channelsProvider).valueOrNull ?? const [];
    final units = ref.watch(unitsProvider).valueOrNull ?? const [];
    final selectedChannelValue = channels.any((item) => item.name == _selectedChannelName)
        ? _selectedChannelName
        : (_selectedChannelName == '__custom__' ? '__custom__' : null);
    final selectedUnitValue = units.any((item) => item.symbol == _selectedUnitSymbol)
        ? _selectedUnitSymbol
        : (_selectedUnitSymbol == '__custom__' ? '__custom__' : null);

    return FormPageScaffold(
      title: '编辑价格记录',
      primaryAction: _save,
      children: [
        FormSection(
          title: '价格信息',
          children: [
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
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('删除这条价格记录'),
            ),
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
