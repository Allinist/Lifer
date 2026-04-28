import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: NavigationBar(
              height: 64,
              selectedIndex: navigationShell.currentIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: Icon(Icons.show_chart_outlined),
                  selectedIcon: Icon(Icons.show_chart),
                  label: '价格',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: '库存',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: '笔记',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: '设置',
                ),
              ],
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
