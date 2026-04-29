import 'package:flutter/material.dart';

class DateInputField extends StatelessWidget {
  const DateInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String labelText;
  final bool enabled;

  Future<void> _pickDate(BuildContext context) async {
    final initial = DateTime.tryParse(controller.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    controller.text = picked.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: IconButton(
          onPressed: enabled ? () => _pickDate(context) : null,
          icon: const Icon(Icons.calendar_month_rounded),
          tooltip: '选择日期',
        ),
      ),
    );
  }
}
