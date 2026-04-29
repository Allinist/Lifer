import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/features/settings/application/settings_providers.dart';
import 'package:lifer/shared/widgets/app_dropdown_field.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAppIcon = ref.watch(currentAppIconAssetProvider);
    final currentSplashLogo = ref.watch(currentSplashLogoAssetProvider);
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    final settingsActions = ref.watch(settingsActionsProvider);
    final documentsPath = ref.watch(appDocumentsDirectoryPathProvider).valueOrNull ?? '--';

    Future<void> runAndToast(Future<String> Function() action, String successPrefix) async {
      try {
        final path = await action();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$successPrefix\n$path')));
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }

    return AppPageScaffold(
      title: '设置',
      actions: [
        IconButton(
          onPressed: () => context.push('/settings/theme'),
          icon: const Icon(Icons.palette_outlined),
          tooltip: '颜色设置',
        ),
      ],
      children: [
        SectionCard(
          title: '数据管理',
          subtitle: '应用文档目录：$documentsPath',
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('JSON 导入'),
                subtitle: const Text('选择任意 JSON 文件作为导入源'),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                    allowMultiple: false,
                  );
                  final pickedPath = result?.files.single.path;
                  if (pickedPath == null || pickedPath.isEmpty) return;
                  await runAndToast(() => settingsActions.importJsonFromPath(pickedPath), '导入完成');
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('JSON 导出'),
                subtitle: const Text('选择导出保存位置与文件名'),
                onTap: () async {
                  final filePath = await FilePicker.platform.saveFile(
                    dialogTitle: '选择导出文件保存位置',
                    fileName: 'lifer_export_${DateTime.now().millisecondsSinceEpoch}.json',
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                    bytes: Uint8List(0),
                  );
                  if (filePath == null || filePath.isEmpty) return;
                  await runAndToast(() => settingsActions.exportJsonToPath(filePath), '导出完成');
                },
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
                onChanged: settingsActions.saveNotificationsEnabled,
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
              AppDropdownField<String>(
                value: const ['zh-CN', 'en-US'].contains(settings?.languageCode) ? settings?.languageCode : 'zh-CN',
                decoration: const InputDecoration(prefixIcon: Icon(Icons.language_rounded), labelText: '语言'),
                items: const [
                  DropdownMenuItem(value: 'zh-CN', child: Text('简体中文（zh-CN）')),
                  DropdownMenuItem(value: 'en-US', child: Text('English (en-US)')),
                ],
                onChanged: (value) {
                  if (value != null) settingsActions.saveLanguageCode(value);
                },
              ),
              const SizedBox(height: 12),
              AppDropdownField<String>(
                value: const ['CNY', 'USD', 'EUR', 'JPY', 'GBP', 'CHF', 'CAD', 'KRW'].contains(settings?.currencyCode)
                    ? settings?.currencyCode
                    : 'CNY',
                decoration: const InputDecoration(prefixIcon: Icon(Icons.currency_yen_rounded), labelText: '记账货币'),
                items: const [
                  DropdownMenuItem(value: 'CNY', child: Text('人民币（CNY）')),
                  DropdownMenuItem(value: 'USD', child: Text('美元（USD）')),
                  DropdownMenuItem(value: 'EUR', child: Text('欧元（EUR）')),
                  DropdownMenuItem(value: 'JPY', child: Text('日元（JPY）')),
                  DropdownMenuItem(value: 'GBP', child: Text('英镑（GBP）')),
                  DropdownMenuItem(value: 'CHF', child: Text('法郎（CHF）')),
                  DropdownMenuItem(value: 'CAD', child: Text('加元（CAD）')),
                  DropdownMenuItem(value: 'KRW', child: Text('韩元（KRW）')),
                ],
                onChanged: (value) {
                  if (value != null) settingsActions.saveCurrencyCode(value);
                },
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
          title: '应用图标 Logo',
          subtitle: '单独设置安装图标',
          child: Row(
            children: [
              Expanded(
                child: _LogoOption(
                  title: 'Lifer',
                  assetPath: defaultLogoAsset,
                  selected: currentAppIcon == defaultLogoAsset,
                  onTap: () => settingsActions.saveAppIconAsset(defaultLogoAsset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LogoOption(
                  title: 'Logo',
                  assetPath: alternateLogoAsset,
                  selected: currentAppIcon == alternateLogoAsset,
                  onTap: () => settingsActions.saveAppIconAsset(alternateLogoAsset),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '开屏 Logo',
          subtitle: '单独设置开屏展示图',
          child: Row(
            children: [
              Expanded(
                child: _LogoOption(
                  title: 'Lifer',
                  assetPath: defaultLogoAsset,
                  selected: currentSplashLogo == defaultLogoAsset,
                  onTap: () => settingsActions.saveSplashLogoAsset(defaultLogoAsset),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LogoOption(
                  title: 'Logo',
                  assetPath: alternateLogoAsset,
                  selected: currentSplashLogo == alternateLogoAsset,
                  onTap: () => settingsActions.saveSplashLogoAsset(alternateLogoAsset),
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
            color: selected ? Theme.of(context).colorScheme.secondary : Theme.of(context).dividerColor,
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          children: [
            SizedBox(width: 54, height: 54, child: Image.asset(assetPath)),
            const SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}

