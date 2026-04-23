import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/features/home/presentation/home_page.dart';
import 'package:lifer/features/inventory/presentation/consumption_form_page.dart';
import 'package:lifer/features/inventory/presentation/inventory_page.dart';
import 'package:lifer/features/inventory/presentation/restock_form_page.dart';
import 'package:lifer/features/notes/presentation/notes_page.dart';
import 'package:lifer/features/pricing/presentation/pricing_page.dart';
import 'package:lifer/features/product/presentation/product_detail_page.dart';
import 'package:lifer/features/product/presentation/product_form_page.dart';
import 'package:lifer/features/product/presentation/reminder_rule_form_page.dart';
import 'package:lifer/features/settings/presentation/settings_page.dart';
import 'package:lifer/shared/widgets/main_shell_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pricing',
                builder: (context, state) => const PricingPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          return ProductDetailPage(productId: productId);
        },
      ),
      GoRoute(
        path: '/product/create',
        builder: (context, state) => const ProductFormPage(),
      ),
      GoRoute(
        path: '/restock/create',
        builder: (context, state) => const RestockFormPage(),
      ),
      GoRoute(
        path: '/consume/create',
        builder: (context, state) => const ConsumptionFormPage(),
      ),
      GoRoute(
        path: '/reminder-rule/create',
        builder: (context, state) => const ReminderRuleFormPage(),
      ),
    ],
  );
});
