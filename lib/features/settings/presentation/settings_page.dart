import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/features/settings/application/settings_providers.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLogo = ref.watch(currentLogoAssetProvider);
    final settingsActions = ref.watch(settingsActionsProvider);

    return AppPageScaffold(
      title: '设置',
      children: [
        const SectionCard(
          title: '数据管理',
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.upload_file_outlined),
                title: Text('JSON 导入'),
              ),
              ListTile(
                leading: Icon(Icons.download_outlined),
                title: Text('JSON 导出'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const SectionCard(
          title: '通知与提醒',
          child: Column(
            children: [
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('启用系统通知'),
              ),
              ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('提醒时段与频率'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const SectionCard(
          title: '语言、货币与 Obsidian',
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.language_rounded),
                title: Text('语言'),
                subtitle: Text('简体中文'),
              ),
              ListTile(
                leading: Icon(Icons.currency_yen_rounded),
                title: Text('记账单位'),
                subtitle: Text('CNY'),
              ),
              ListTile(
                leading: Icon(Icons.menu_book_outlined),
                title: Text('Obsidian Sync'),
                subtitle: Text('配置 Vault 路径与 URI Scheme'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '应用 Logo',
          subtitle: '默认使用 Lifer.png，可切换为 Logo.png',
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
