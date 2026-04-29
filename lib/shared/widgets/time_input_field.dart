import 'package:flutter/material.dart';

class TimeInputField extends StatelessWidget {
  const TimeInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String labelText;
  final bool enabled;

  Future<void> _pickTime(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    controller.text = '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: IconButton(
          onPressed: enabled ? () => _pickTime(context) : null,
          icon: const Icon(Icons.access_time_rounded),
          tooltip: '选择时间',
        ),
      ),
    );
  }
}
