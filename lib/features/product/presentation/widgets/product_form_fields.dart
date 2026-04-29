import 'package:flutter/material.dart';
import 'package:lifer/core/utils/formatters.dart';
import 'package:lifer/data/local/db/app_database.dart';
import 'package:lifer/shared/widgets/app_dropdown_field.dart';
import 'package:lifer/shared/widgets/form_section.dart';
import 'package:lifer/shared/widgets/date_input_field.dart';

class ProductFormFields extends StatelessWidget {
  const ProductFormFields({
    super.key,
    required this.categories,
    required this.units,
    required this.nameController,
    required this.aliasController,
    required this.customCategoryController,
    required this.brandController,
    required this.customUnitController,
    required this.targetPriceController,
    required this.shelfLifeController,
    required this.notesController,
    required this.durablePurchasedAtController,
    required this.productType,
    required this.isPinnedHome,
    required this.selectedCategoryName,
    required this.selectedUnitSymbol,
    required this.logoUri,
    required this.onProductTypeChanged,
    required this.onPinnedChanged,
    required this.onCategoryChanged,
    required this.onUnitChanged,
    required this.onLogoChanged,
    required this.consumablePriceMode,
    required this.onConsumablePriceModeChanged,
    required this.currencyCode,
    required this.onCurrencyCodeChanged,
  });

  final List<Category> categories;
  final List<Unit> units;
  final TextEditingController nameController;
  final TextEditingController aliasController;
  final TextEditingController customCategoryController;
  final TextEditingController brandController;
  final TextEditingController customUnitController;
  final TextEditingController targetPriceController;
  final TextEditingController shelfLifeController;
  final TextEditingController notesController;
  final TextEditingController durablePurchasedAtController;
  final String productType;
  final bool isPinnedHome;
  final String? selectedCategoryName;
  final String? selectedUnitSymbol;
  final String logoUri;
  final ValueChanged<String> onProductTypeChanged;
  final ValueChanged<bool> onPinnedChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onUnitChanged;
  final ValueChanged<String> onLogoChanged;
  final String consumablePriceMode;
  final ValueChanged<String> onConsumablePriceModeChanged;
  final String currencyCode;
  final ValueChanged<String> onCurrencyCodeChanged;

  @override
  Widget build(BuildContext context) {
    final categoryValue = categories.any((item) => item.name == selectedCategoryName)
        ? selectedCategoryName
        : (selectedCategoryName == '__custom__' ? '__custom__' : null);
    final unitValue = units.any((item) => item.symbol == selectedUnitSymbol)
        ? selectedUnitSymbol
        : (selectedUnitSymbol == '__custom__' ? '__custom__' : null);

    return Column(
      children: [
        FormSection(
          title: '基础信息',
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '商品名称')),
            const SizedBox(height: 12),
            TextField(controller: aliasController, decoration: const InputDecoration(labelText: '别名')),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              key: ValueKey(productType),
              initialValue: productType,
              items: const [
                DropdownMenuItem(value: 'consumable', child: Text('消耗品')),
                DropdownMenuItem(value: 'durable', child: Text('常驻品')),
                DropdownMenuItem(value: 'pricing_only', child: Text('计价品')),
              ],
              onChanged: (value) => onProductTypeChanged(value ?? 'consumable'),
              decoration: const InputDecoration(labelText: '商品类型'),
            ),
          ],
        ),
        FormSection(
          title: '归属与展示',
          children: [
            AppDropdownField<String>(
              value: categoryValue,
              decoration: const InputDecoration(labelText: '所属分类'),
              items: [
                ...categories.map((category) => DropdownMenuItem(value: category.name, child: Text(category.name))),
                const DropdownMenuItem(value: '__custom__', child: Text('新建分类')),
              ],
              onChanged: onCategoryChanged,
            ),
            if (selectedCategoryName == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(controller: customCategoryController, decoration: const InputDecoration(labelText: '新分类名称')),
            ],
            const SizedBox(height: 12),
            AppDropdownField<String>(
              value: logoUri,
              decoration: const InputDecoration(labelText: '图标'),
              items: const [
                DropdownMenuItem(value: 'bag', child: Text('购物袋')),
                DropdownMenuItem(value: 'home', child: Text('居家')),
                DropdownMenuItem(value: 'kitchen', child: Text('厨房')),
                DropdownMenuItem(value: 'health', child: Text('健康')),
                DropdownMenuItem(value: 'car', child: Text('出行')),
              ],
              onChanged: (value) => onLogoChanged(value ?? 'bag'),
            ),
            const SizedBox(height: 12),
            TextField(controller: brandController, decoration: const InputDecoration(labelText: '品牌')),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              value: unitValue,
              decoration: const InputDecoration(labelText: '默认单位'),
              items: [
                ...units.map((unit) => DropdownMenuItem(
                      value: unit.symbol,
                      child: Text(Formatters.unitLabel(symbol: unit.symbol, name: unit.name)),
                    )),
                const DropdownMenuItem(value: '__custom__', child: Text('新建单位')),
              ],
              onChanged: onUnitChanged,
            ),
            if (selectedUnitSymbol == '__custom__') ...[
              const SizedBox(height: 12),
              TextField(controller: customUnitController, decoration: const InputDecoration(labelText: '新单位符号')),
            ],
          ],
        ),
        FormSection(
          title: '策略信息',
          subtitle: productType == 'consumable' ? '价格目标、保质期和首页固定状态' : '价格目标和首页固定状态',
          children: [
            AppDropdownField<String>(
              value: currencyCode,
              decoration: const InputDecoration(labelText: '货币'),
              items: const [
                DropdownMenuItem(value: 'CNY', child: Text('人民币（CNY）')),
                DropdownMenuItem(value: 'USD', child: Text('美元（USD）')),
                DropdownMenuItem(value: 'EUR', child: Text('欧元（EUR）')),
                DropdownMenuItem(value: 'JPY', child: Text('日元（JPY）')),
                DropdownMenuItem(value: 'GBP', child: Text('英镑（GBP）')),
                DropdownMenuItem(value: 'CHF', child: Text('法郎（CHF）')),
                DropdownMenuItem(value: 'CAD', child: Text('加元（CAD）')),
                DropdownMenuItem(value: 'KRW', child: Text('韩元（KRW）')),
              ],
              onChanged: (v) => onCurrencyCodeChanged(v ?? 'CNY'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: productType == 'consumable' ? '目标价格' : '参考购入价格'),
            ),
            if (productType == 'consumable') ...[
              const SizedBox(height: 12),
              AppDropdownField<String>(
                value: consumablePriceMode,
                decoration: const InputDecoration(labelText: '价格计算方式'),
                items: const [
                  DropdownMenuItem(value: 'total', child: Text('按总价')),
                  DropdownMenuItem(value: 'unit', child: Text('按单价（总价÷数量）')),
                ],
                onChanged: (value) => onConsumablePriceModeChanged(value ?? 'total'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: shelfLifeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '默认保质期（天）'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text('常驻品不设置保质期，可在库存页记录使用周期与日均开销。', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              DateInputField(controller: durablePurchasedAtController, labelText: '购买日期（YYYY-MM-DD）'),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              value: isPinnedHome,
              onChanged: onPinnedChanged,
              contentPadding: EdgeInsets.zero,
              title: const Text('固定到首页'),
            ),
            const SizedBox(height: 6),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: '备注')),
          ],
        ),
      ],
    );
  }
}


