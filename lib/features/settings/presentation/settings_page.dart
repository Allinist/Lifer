import 'package:flutter/material.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        SizedBox(height: AppSpacing.section),
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
        SizedBox(height: AppSpacing.section),
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
      ],
    );
  }
}
