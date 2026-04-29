import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/app_identity.dart';
import 'package:lifer/app/router/app_router.dart';
import 'package:lifer/app/theme/app_theme.dart';
import 'package:lifer/features/settings/application/settings_providers.dart';

class LiferApp extends ConsumerWidget {
  const LiferApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    final languageCode = settings?.languageCode ?? 'zh-CN';
    final locale = languageCode == 'en-US' ? const Locale('en', 'US') : const Locale('zh', 'CN');

    return MaterialApp.router(
      title: AppIdentity.appName,
      debugShowCheckedModeBanner: false,
      theme: buildLiferTheme(themeMode: settings?.themeMode),
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      routerConfig: router,
    );
  }
}
