import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/pricing/application/pricing_actions.dart';
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
  late final TextEditingController _channelController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.recordDate);
    _priceController = TextEditingController(text: widget.price);
    _channelController = TextEditingController(text: widget.channel);
    _quantityController = TextEditingController(text: widget.quantity);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _priceController.dispose();
    _channelController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(pricingActionsProvider).updatePriceRecord(
          recordId: widget.recordId,
          recordDate: _dateController.text,
          price: _priceController.text,
          channelName: _channelController.text,
          quantityLabel: _quantityController.text,
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
              decoration: const InputDecoration(labelText: '数量与单位'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _channelController,
              decoration: const InputDecoration(labelText: '购买渠道'),
            ),
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
