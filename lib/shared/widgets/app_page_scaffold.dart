import 'package:flutter/material.dart';
import 'package:lifer/core/constants/app_spacing.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.title,
    required this.children,
    this.actions = const [],
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pageInsets,
          children: children,
        ),
      ),
    );
  }
}
