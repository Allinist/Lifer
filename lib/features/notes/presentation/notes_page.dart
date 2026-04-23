import 'package:flutter/material.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: '笔记',
      children: [
        const TextField(
          decoration: InputDecoration(
            hintText: '搜索商品笔记或 Obsidian 路径',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        SizedBox(height: AppSpacing.section),
        const SectionCard(
          title: '商品关联笔记',
          child: Column(
            children: [
              ListTile(
                title: Text('牛奶'),
                subtitle: Text('recipes/breakfast/oat-milk.md'),
                trailing: Icon(Icons.open_in_new_rounded),
              ),
              ListTile(
                title: Text('鸡蛋'),
                subtitle: Text('recipes/meal-prep/egg-box.md'),
                trailing: Icon(Icons.open_in_new_rounded),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.section),
        const SectionCard(
          title: 'Obsidian Sync 预留',
          subtitle: 'V1 先支持 URI 与路径映射，后续再增加 Markdown 模板导出',
          child: ListTile(
            title: Text('已绑定 Vault'),
            subtitle: Text('PersonalKnowledge/Lifer'),
            trailing: Icon(Icons.chevron_right_rounded),
          ),
        ),
      ],
    );
  }
}
