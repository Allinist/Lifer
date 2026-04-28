import 'package:flutter/material.dart';
import 'package:lifer/core/constants/app_spacing.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.title,
    required this.children,
    this.actions = const [],
    this.onRefresh,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh ?? () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pageInsets,
            children: children,
          ),
        ),
      ),
    );
  }
}
