import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/features/home/presentation/home_page.dart';
import 'package:lifer/features/inventory/presentation/consumption_form_page.dart';
import 'package:lifer/features/inventory/presentation/inventory_page.dart';
import 'package:lifer/features/inventory/presentation/restock_form_page.dart';
import 'package:lifer/features/inventory/presentation/stock_batch_edit_page.dart';
import 'package:lifer/features/notes/presentation/notes_page.dart';
import 'package:lifer/features/pricing/presentation/channel_management_page.dart';
import 'package:lifer/features/pricing/presentation/price_record_edit_page.dart';
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
        path: '/product/create',
        builder: (context, state) => ProductFormPage(
          initialProductType: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          return ProductDetailPage(productId: productId);
        },
      ),
      GoRoute(
        path: '/product/edit/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId'] ?? '';
          return ProductFormPage(productId: productId);
        },
      ),
      GoRoute(
        path: '/restock/create',
        builder: (context, state) => RestockFormPage(
          initialProductId: state.uri.queryParameters['productId'],
        ),
      ),
      GoRoute(
        path: '/consume/create',
        builder: (context, state) => ConsumptionFormPage(
          initialProductId: state.uri.queryParameters['productId'],
          initialBatchLabel: state.uri.queryParameters['batchLabel'],
          consumptionId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: '/inventory/batch/edit/:batchId',
        builder: (context, state) => StockBatchEditPage(
          batchId: state.pathParameters['batchId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/reminder-rule/create',
        builder: (context, state) => ReminderRuleFormPage(
          initialProductId: state.uri.queryParameters['productId'],
        ),
      ),
      GoRoute(
        path: '/reminder-rule/edit/:ruleId',
        builder: (context, state) => ReminderRuleFormPage(
          ruleId: state.pathParameters['ruleId'],
          initialProductId: state.uri.queryParameters['productId'],
        ),
      ),
      GoRoute(
        path: '/pricing/record/edit',
        builder: (context, state) => PriceRecordEditPage(
          recordId: state.uri.queryParameters['id'],
          productId: state.uri.queryParameters['productId'],
          recordDate: state.uri.queryParameters['date'] ?? '',
          price: state.uri.queryParameters['price'] ?? '',
          channel: state.uri.queryParameters['channel'] ?? '',
          quantity: state.uri.queryParameters['quantity'] ?? '',
        ),
      ),
      GoRoute(
        path: '/pricing/channels',
        builder: (context, state) => const ChannelManagementPage(),
      ),
    ],
  );
});
