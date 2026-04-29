import 'package:flutter/material.dart';
import 'package:lifer/core/constants/app_spacing.dart';

class FormPageScaffold extends StatelessWidget {
  const FormPageScaffold({
    required this.title,
    required this.children,
    this.primaryAction,
    this.primaryLabel = '保存',
    this.isSubmitting = false,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Future<void> Function()? primaryAction;
  final String primaryLabel;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pageInsets,
          children: [
            ...children,
            const SizedBox(height: 0),
            FilledButton(
              onPressed: (primaryAction == null || isSubmitting) ? null : () async => primaryAction!.call(),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(primaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
