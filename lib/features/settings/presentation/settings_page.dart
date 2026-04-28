import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/features/settings/application/settings_providers.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLogo = ref.watch(currentLogoAssetProvider);
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    final settingsActions = ref.watch(settingsActionsProvider);
    final documentsPath = ref.watch(appDocumentsDirectoryPathProvider).valueOrNull ?? '--';

    Future<void> runAndToast(Future<String> Function() action, String successPrefix) async {
      try {
        final path = await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$successPrefix\n$path')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }

    return AppPageScaffold(
      title: '设置',
      children: [
        SectionCard(
          title: '数据管理',
          subtitle: '应用文档目录：$documentsPath',
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('JSON 导入'),
                subtitle: const Text('从应用文档目录读取 lifer_import.json，没有时回退到 lifer_export_latest.json'),
                onTap: () => runAndToast(settingsActions.importJson, '导入完成'),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('JSON 导出'),
                subtitle: const Text('导出到应用文档目录，并额外生成一份 lifer_export_latest.json'),
                onTap: () => runAndToast(settingsActions.exportJson, '导出完成'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('导入文件名'),
                subtitle: Text('lifer_import.json'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('最新导出文件名'),
                subtitle: Text('lifer_export_latest.json'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '通知与提醒',
          child: Column(
            children: [
              SwitchListTile(
                value: settings?.notificationsEnabled ?? true,
                onChanged: (value) {
                  settingsActions.saveNotificationsEnabled(value);
                },
                title: const Text('启用系统通知'),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('提醒时段与频率'),
                subtitle: const Text('进入提醒规则配置'),
                onTap: () => context.push('/reminder-rule/create'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '语言、货币与 Obsidian',
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('语言'),
                subtitle: Text(settings?.languageCode ?? 'zh-CN'),
              ),
              ListTile(
                leading: const Icon(Icons.currency_yen_rounded),
                title: const Text('记账货币'),
                subtitle: Text(settings?.currencyCode ?? 'CNY'),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Obsidian Vault'),
                subtitle: Text(settings?.obsidianVaultPath ?? '未配置'),
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Obsidian URI Scheme'),
                subtitle: Text(settings?.obsidianUriScheme ?? '未配置'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: 'Flutter 应用 Logo',
          subtitle: '这里切换的是桌面启动图标，默认使用 Lifer.png，可切换为 Logo.png',
          child: Row(
            children: [
              Expanded(
                child: _LogoOption(
                  title: 'Lifer',
                  assetPath: defaultLogoAsset,
                  selected: currentLogo == defaultLogoAsset,
                  onTap: () {
                    settingsActions.saveLogoAsset(defaultLogoAsset);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LogoOption(
                  title: 'Logo',
                  assetPath: alternateLogoAsset,
                  selected: currentLogo == alternateLogoAsset,
                  onTap: () {
                    settingsActions.saveLogoAsset(alternateLogoAsset);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoOption extends StatelessWidget {
  const _LogoOption({
    required this.title,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).dividerColor,
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Image.asset(assetPath),
            ),
            const SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}
