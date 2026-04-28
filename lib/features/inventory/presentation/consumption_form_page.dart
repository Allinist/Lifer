import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/inventory/application/inventory_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

final consumptionRecordProvider =
    FutureProvider.family<ConsumptionRecord?, String>((ref, consumptionId) async {
  final db = ref.watch(appDatabaseProvider);
  return ((db.select(db.consumptionRecords))..where((tbl) => tbl.id.equals(consumptionId)))
        .getSingleOrNull();
});

final productBatchesProvider = FutureProvider.family<List<StockBatche>, String>((ref, productId) async {
  final db = ref.watch(appDatabaseProvider);
  return ((db.select(db.stockBatches))
        ..where((tbl) => tbl.productId.equals(productId) & tbl.isArchived.equals(false))
        ..orderBy([
          (tbl) => OrderingTerm(expression: tbl.expiryDate),
          (tbl) => OrderingTerm(expression: tbl.createdAt),
        ]))
      .get();
});

class ConsumptionFormPage extends ConsumerStatefulWidget {
  const ConsumptionFormPage({
    this.initialProductId,
    this.initialBatchLabel,
    this.consumptionId,
    super.key,
  });

  final String? initialProductId;
  final String? initialBatchLabel;
  final String? consumptionId;

  bool get isEditing => consumptionId != null && consumptionId!.isNotEmpty;

  @override
  ConsumerState<ConsumptionFormPage> createState() => _ConsumptionFormPageState();
}

class _ConsumptionFormPageState extends ConsumerState<ConsumptionFormPage> {
  String? _selectedProductId;
  String? _selectedUnitSymbol;
  String? _selectedBatchId;

  final _customProductController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _occurredAtController = TextEditingController();
  final _batchLabelController = TextEditingController();
  final _notesController = TextEditingController();

  String _usageType = 'normal';
  bool _didHydrate = false;
  bool _reallocateAcrossBatches = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
    _batchLabelController.text = widget.initialBatchLabel ?? '';
  }

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

  void _hydrate(ConsumptionRecord record, List<Product> products, List<Unit> units) {
    if (_didHydrate) return;
    _didHydrate = true;
    _selectedProductId = record.productId;
    _selectedBatchId = record.batchId;
    _quantityController.text = record.quantity.toString();
    _occurredAtController.text = _dateText(record.occurredAt);
    _usageType = record.usageType;
    final unit = units.cast<dynamic>().firstWhere(
          (item) => item.id == record.unitId,
          orElse: () => null,
        );
    _selectedUnitSymbol = unit?.symbol as String?;
    final notes = record.notes ?? '';
    final lines = notes.split('\n');
    String? batchLine;
    for (final line in lines) {
      if (line.startsWith('批次: ')) {
        batchLine = line;
        break;
      }
    }
    _batchLabelController.text = batchLine == null ? _batchLabelController.text : batchLine.replaceFirst('批次: ', '');
    _notesController.text = lines.where((line) => !line.startsWith('批次: ')).join('\n');
  }

  Future<void> _save() async {
    final productName = (_selectedProductId == '__custom__'
            ? _customProductController.text
            : null) ??
        _customProductController.text;
    final unitSymbol =
        (_selectedUnitSymbol == '__custom__' ? _customUnitController.text : _selectedUnitSymbol) ??
            _customUnitController.text;

    if (widget.isEditing) {
      await ref.read(inventoryActionsProvider).updateConsumption(
            consumptionId: widget.consumptionId!,
            productId: _selectedProductId ?? '',
            quantity: _quantityController.text,
            unitSymbol: unitSymbol,
            occurredAt: _occurredAtController.text,
            selectedBatchId: _selectedBatchId,
            reallocateAcrossBatches: _reallocateAcrossBatches,
            batchLabel: _batchLabelController.text,
            usageType: _usageType,
            notes: _notesController.text,
          );
    } else {
      await ref.read(inventoryActionsProvider).createConsumption(
            productId: _selectedProductId == '__custom__' ? null : _selectedProductId,
            productName: productName,
            quantity: _quantityController.text,
            unitSymbol: unitSymbol,
            occurredAt: _occurredAtController.text,
            selectedBatchId: _selectedBatchId,
            batchLabel: _batchLabelController.text,
            usageType: _usageType,
            notes: _notesController.text,
          );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final consumptionId = widget.consumptionId;
    if (consumptionId == null || consumptionId.isEmpty) return;
    await ref.read(inventoryActionsProvider).deleteConsumption(consumptionId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider).valueOrNull ?? const <Product>[];
    final units = ref.watch(unitsProvider).valueOrNull ?? const <Unit>[];
    final existing =
        widget.isEditing ? ref.watch(consumptionRecordProvider(widget.consumptionId!)).valueOrNull : null;
    final batches = (_selectedProductId == null || _selectedProductId == '__custom__')
        ? const <StockBatche>[]
        : (ref.watch(productBatchesProvider(_selectedProductId!)).valueOrNull ?? const <StockBatche>[]);
    if (existing != null) {
      _hydrate(existing, products, units);
    }

    final selectedProduct = products.cast<dynamic>().firstWhere(
          (item) => item.id == _selectedProductId,
          orElse: () => null,
        );
    if (selectedProduct != null && _selectedUnitSymbol == null) {
      final defaultUnit = units.cast<dynamic>().firstWhere(
            (item) => item.id == selectedProduct.unitId,
            orElse: () => null,
          );
      if (defaultUnit != null) {
        _selectedUnitSymbol = defaultUnit.symbol as String;
      }
    }

    return FormPageScaffold(
      title: widget.isEditing ? '编辑消耗记录' : '消耗',
      primaryAction: _save,
      children: [
        FormSection(
          title: '消耗信息',
          children: [
            DropdownButtonFormField<String>(
              value: products.any((item) => item.id == _selectedProductId)
                  ? _selectedProductId
                  : (_selectedProductId == '__custom__' ? '__custom__' : null),
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
              onChanged: (value) {
                setState(() {
                  _selectedProductId = value;
                });
              },
            ),
            if (_selectedProductId == '__custom__') ...[
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
            if (batches.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: batches.any((item) => item.id == _selectedBatchId) ? _selectedBatchId : null,
                decoration: const InputDecoration(labelText: '真实批次（可切换）'),
                items: batches.map((batch) {
                  final label = (batch.batchLabel == null || batch.batchLabel!.trim().isEmpty)
                      ? batch.id.substring(0, 6)
                      : batch.batchLabel!.trim();
                  return DropdownMenuItem(
                    value: batch.id,
                    child: Text('$label · 剩余 ${batch.remainingQuantity}/${batch.totalQuantity}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedBatchId = value),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_usageType),
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
            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('按批次重分摊'),
                subtitle: const Text('保存时按“所选批次优先 + FIFO”重算分配'),
                value: _reallocateAcrossBatches,
                onChanged: (value) => setState(() => _reallocateAcrossBatches = value),
              ),
            ],
            if (widget.isEditing) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除这条消耗记录'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

String _dateText(int? millis) {
  if (millis == null) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
