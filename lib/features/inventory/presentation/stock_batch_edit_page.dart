import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/features/inventory/application/inventory_actions.dart';
import 'package:lifer/features/shared/application/form_options_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

final stockBatchProvider = FutureProvider.family<StockBatche?, String>((ref, batchId) async {
  final db = ref.watch(appDatabaseProvider);
  return ((db.select(db.stockBatches))..where((tbl) => tbl.id.equals(batchId))).getSingleOrNull();
});

final batchSourcePriceRecordsProvider =
    FutureProvider.family<List<PriceRecord>, String>((ref, productId) async {
  final db = ref.watch(appDatabaseProvider);
  return ((db.select(db.priceRecords))
        ..where((tbl) => tbl.productId.equals(productId))
        ..orderBy([(tbl) => OrderingTerm(expression: tbl.purchasedAt, mode: OrderingMode.desc)]))
      .get();
});

class StockBatchEditPage extends ConsumerStatefulWidget {
  const StockBatchEditPage({
    required this.batchId,
    super.key,
  });

  final String batchId;

  @override
  ConsumerState<StockBatchEditPage> createState() => _StockBatchEditPageState();
}

class _StockBatchEditPageState extends ConsumerState<StockBatchEditPage> {
  final _quantityController = TextEditingController();
  final _remainingQuantityController = TextEditingController();
  final _purchasedAtController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _batchLabelController = TextEditingController();
  final _locationController = TextEditingController();
  final _customUnitController = TextEditingController();
  String? _selectedUnitSymbol;
  String? _selectedSourcePriceRecordId;
  bool _didHydrate = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _remainingQuantityController.dispose();
    _purchasedAtController.dispose();
    _expiryDateController.dispose();
    _batchLabelController.dispose();
    _locationController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  void _hydrate(StockBatche batch, List<Unit> units) {
    if (_didHydrate) return;
    _didHydrate = true;
    _quantityController.text = batch.totalQuantity.toString();
    _remainingQuantityController.text = batch.remainingQuantity.toString();
    _purchasedAtController.text = _dateText(batch.purchasedAt);
    _expiryDateController.text = _dateText(batch.expiryDate);
    _batchLabelController.text = batch.batchLabel ?? '';
    _locationController.text = batch.storageNotes ?? '';
    _selectedSourcePriceRecordId = batch.sourcePriceRecordId;
    final matchedUnit = units.cast<dynamic>().firstWhere(
          (item) => item.id == batch.unitId,
          orElse: () => null,
        );
    _selectedUnitSymbol = matchedUnit?.symbol as String?;
  }

  Future<void> _save() async {
    final unitSymbol = (_selectedUnitSymbol == '__custom__'
            ? _customUnitController.text
            : _selectedUnitSymbol) ??
        _customUnitController.text;
    await ref.read(inventoryActionsProvider).updateStockBatch(
          batchId: widget.batchId,
          quantity: _quantityController.text,
          remainingQuantity: _remainingQuantityController.text,
          unitSymbol: unitSymbol,
          purchasedAt: _purchasedAtController.text,
          expiryDate: _expiryDateController.text,
          sourcePriceRecordId: _selectedSourcePriceRecordId,
          batchLabel: _batchLabelController.text,
          locationName: _locationController.text,
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _archive() async {
    await ref.read(inventoryActionsProvider).archiveStockBatch(widget.batchId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = ref.watch(stockBatchProvider(widget.batchId)).valueOrNull;
    final units = ref.watch(unitsProvider).valueOrNull ?? const [];
    final sourcePriceRecords = batch == null
        ? const <PriceRecord>[]
        : (ref.watch(batchSourcePriceRecordsProvider(batch.productId)).valueOrNull ?? const <PriceRecord>[]);
    if (batch != null) {
      _hydrate(batch, units);
    }
    final unitValue = units.any((item) => item.symbol == _selectedUnitSymbol)
        ? _selectedUnitSymbol
        : (_selectedUnitSymbol == '__custom__' ? '__custom__' : null);

    return FormPageScaffold(
      title: '编辑库存批次',
      primaryAction: _save,
      children: [
        FormSection(
          title: '数量信息',
          children: [
            TextField(controller: _quantityController, decoration: const InputDecoration(labelText: '总数量')),
            const SizedBox(height: 12),
            TextField(
              controller: _remainingQuantityController,
              decoration: const InputDecoration(labelText: '剩余数量'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: unitValue,
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
              onChanged: (value) => setState(() => _selectedUnitSymbol = value),
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
          title: '批次信息',
          children: [
            TextField(
              controller: _batchLabelController,
              decoration: const InputDecoration(labelText: '批次名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purchasedAtController,
              decoration: const InputDecoration(labelText: '购买时间，例如 2026-04-23'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expiryDateController,
              decoration: const InputDecoration(labelText: '到期时间，例如 2026-05-01'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: '存放位置 / 备注'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: sourcePriceRecords.any((item) => item.id == _selectedSourcePriceRecordId)
                  ? _selectedSourcePriceRecordId
                  : null,
              decoration: const InputDecoration(labelText: '来源价格记录'),
              items: [
                const DropdownMenuItem(value: '', child: Text('不关联')),
                ...sourcePriceRecords.map(
                  (record) => DropdownMenuItem(
                    value: record.id,
                    child: Text('${_dateText(record.purchasedAt)} · ¥${(record.amountMinor / 100).toStringAsFixed(2)}'),
                  ),
                ),
              ],
              onChanged: (value) => setState(
                () => _selectedSourcePriceRecordId = (value == null || value.isEmpty) ? null : value,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _archive,
              icon: const Icon(Icons.archive_outlined),
              label: const Text('归档这个批次'),
            ),
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
