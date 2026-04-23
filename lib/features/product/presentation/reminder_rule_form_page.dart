import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/features/product/application/reminder_actions.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class ReminderRuleFormPage extends ConsumerStatefulWidget {
  const ReminderRuleFormPage({super.key});

  @override
  ConsumerState<ReminderRuleFormPage> createState() => _ReminderRuleFormPageState();
}

class _ReminderRuleFormPageState extends ConsumerState<ReminderRuleFormPage> {
  final _productController = TextEditingController();
  final _thresholdValueController = TextEditingController();
  final _notifyTimeController = TextEditingController();
  final _repeatIntervalController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');

  String _ruleType = 'restock';
  String _thresholdType = 'quantity';
  bool _enabled = true;

  @override
  void dispose() {
    _productController.dispose();
    _thresholdValueController.dispose();
    _notifyTimeController.dispose();
    _repeatIntervalController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(reminderActionsProvider).saveRule(
          productName: _productController.text,
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
    return FormPageScaffold(
      title: '提醒规则',
      primaryAction: _save,
      children: [
        FormSection(
          title: '目标商品与规则类型',
          children: [
            TextField(controller: _productController, decoration: const InputDecoration(labelText: '商品')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _ruleType,
              items: const [
                DropdownMenuItem(value: 'restock', child: Text('补货提醒')),
                DropdownMenuItem(value: 'expiry', child: Text('保质期提醒')),
                DropdownMenuItem(value: 'price_target', child: Text('价格目标')),
              ],
              onChanged: (value) => setState(() => _ruleType = value ?? 'restock'),
              decoration: const InputDecoration(labelText: '提醒类型'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _thresholdType,
              items: const [
                DropdownMenuItem(value: 'quantity', child: Text('按数量')),
                DropdownMenuItem(value: 'ratio', child: Text('按比例')),
                DropdownMenuItem(value: 'days_before_expiry', child: Text('到期前天数')),
              ],
              onChanged: (value) => setState(() => _thresholdType = value ?? 'quantity'),
              decoration: const InputDecoration(labelText: '阈值类型'),
            ),
          ],
        ),
        FormSection(
          title: '触发设置',
          children: [
            TextField(controller: _thresholdValueController, decoration: const InputDecoration(labelText: '阈值')),
            const SizedBox(height: 12),
            TextField(controller: _notifyTimeController, decoration: const InputDecoration(labelText: '提醒时间，例如 09:00')),
            const SizedBox(height: 12),
            TextField(controller: _repeatIntervalController, decoration: const InputDecoration(labelText: '重复间隔（小时）')),
          ],
        ),
        FormSection(
          title: '优先级',
          children: [
            TextField(controller: _priorityController, decoration: const InputDecoration(labelText: '手动优先级')),
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
