import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/product/application/reminder_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class ReminderRuleFormPage extends ConsumerStatefulWidget {
  const ReminderRuleFormPage({
    this.initialProductId,
    super.key,
  });

  final String? initialProductId;

  @override
  ConsumerState<ReminderRuleFormPage> createState() => _ReminderRuleFormPageState();
}

class _ReminderRuleFormPageState extends ConsumerState<ReminderRuleFormPage> {
  final _customProductController = TextEditingController();
  final _thresholdValueController = TextEditingController();
  final _notifyTimeController = TextEditingController();
  final _repeatIntervalController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');

  String _ruleType = 'restock';
  String _thresholdType = 'quantity';
  bool _enabled = true;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
  }

  @override
  void dispose() {
    _customProductController.dispose();
    _thresholdValueController.dispose();
    _notifyTimeController.dispose();
    _repeatIntervalController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _save(List<Product> products) async {
    final isCustom = _selectedProductId == '__custom__';
    final selectedProduct = products.cast<Product?>().firstWhere(
          (item) => item?.id == _selectedProductId,
          orElse: () => null,
        );

    await ref.read(reminderActionsProvider).saveRule(
          productId: isCustom ? null : _selectedProductId,
          productName: isCustom ? _customProductController.text : (selectedProduct?.name ?? ''),
          ruleType: _ruleType,
          thresholdType: _thresholdType,
          thresholdValue: _thresholdValueController.text,
          notifyTime: _notifyTimeController.text,
          repeatIntervalHours: _repeatIntervalController.text,
          priority: _priorityController.text,
          enabled: _enabled,
        );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider).valueOrNull ?? const <Product>[];
    final validThresholds = _thresholdOptionsForRule(_ruleType);
    if (validThresholds.every((item) => item.$1 != _thresholdType)) {
      _thresholdType = validThresholds.first.$1;
    }

    final selectedValue = products.any((item) => item.id == _selectedProductId)
        ? _selectedProductId
        : (_selectedProductId == '__custom__' ? '__custom__' : null);

    return FormPageScaffold(
      title: '提醒规则',
      primaryAction: () => _save(products),
      children: [
        FormSection(
          title: '目标商品与规则类型',
          children: [
            DropdownButtonFormField<String>(
              value: selectedValue,
              decoration: const InputDecoration(labelText: '商品'),
              items: [
                ...products.map(
                  (product) => DropdownMenuItem(
                    value: product.id,
                    child: Text(product.name),
                  ),
                ),
                const DropdownMenuItem(value: '__custom__', child: Text('新建商品')),
              ],
              onChanged: (value) => setState(() => _selectedProductId = value),
            ),
            if (_selectedProductId == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customProductController,
                decoration: const InputDecoration(labelText: '新商品名称'),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _ruleType,
              items: const [
                DropdownMenuItem(value: 'restock', child: Text('补货提醒')),
                DropdownMenuItem(value: 'expiry', child: Text('保质期提醒')),
                DropdownMenuItem(value: 'price_target', child: Text('价格目标')),
              ],
              onChanged: (value) {
                setState(() {
                  _ruleType = value ?? 'restock';
                  _thresholdType = _thresholdOptionsForRule(_ruleType).first.$1;
                });
              },
              decoration: const InputDecoration(labelText: '提醒类型'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_ruleType),
              initialValue: _thresholdType,
              items: validThresholds
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.$1,
                      child: Text(item.$2),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _thresholdType = value ?? validThresholds.first.$1),
              decoration: const InputDecoration(labelText: '阈值类型'),
            ),
          ],
        ),
        FormSection(
          title: '触发设置',
          children: [
            TextField(
              controller: _thresholdValueController,
              decoration: InputDecoration(labelText: _thresholdLabelForType(_thresholdType)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notifyTimeController,
              decoration: const InputDecoration(labelText: '提醒时间，例如 09:00'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repeatIntervalController,
              decoration: const InputDecoration(labelText: '重复间隔（小时）'),
            ),
          ],
        ),
        FormSection(
          title: '优先级',
          children: [
            TextField(
              controller: _priorityController,
              decoration: const InputDecoration(labelText: '手动优先级'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('启用该规则'),
            ),
          ],
        ),
      ],
    );
  }
}

List<(String, String)> _thresholdOptionsForRule(String ruleType) {
  switch (ruleType) {
    case 'expiry':
      return const [
        ('days_before_expiry', '到期前天数'),
      ];
    case 'price_target':
      return const [
        ('price_minor', '目标价格'),
        ('ratio', '价格比例'),
      ];
    case 'restock':
    default:
      return const [
        ('quantity', '按数量'),
        ('ratio', '按比例'),
      ];
  }
}

String _thresholdLabelForType(String thresholdType) {
  switch (thresholdType) {
    case 'days_before_expiry':
      return '提前天数';
    case 'price_minor':
      return '目标价格';
    case 'ratio':
      return '阈值比例';
    case 'quantity':
    default:
      return '阈值';
  }
}
