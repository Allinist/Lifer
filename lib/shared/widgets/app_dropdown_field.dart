import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:lifer/app/theme/app_colors.dart';

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.initialValue,
    this.decoration,
  });

  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final T? initialValue;
  final InputDecoration? decoration;
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField2<T>(
      key: key,
      value: value ?? initialValue,
      isExpanded: true,
      decoration: decoration,
      items: items,
      onChanged: onChanged,
      iconStyleData: const IconStyleData(
        icon: Icon(Icons.keyboard_arrow_down_rounded),
        iconEnabledColor: AppColors.textMuted,
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: 360,
        elevation: 8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
      ),
      buttonStyleData: const ButtonStyleData(
        padding: EdgeInsets.only(right: 8),
      ),
      menuItemStyleData: const MenuItemStyleData(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
