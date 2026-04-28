import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifer/core/constants/app_spacing.dart';
import 'package:lifer/features/notes/application/notes_providers.dart';
import 'package:lifer/shared/widgets/app_page_scaffold.dart';
import 'package:lifer/shared/widgets/section_card.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(filteredProductNoteLinksProvider);
    final settings = ref.watch(notesObsidianSettingsProvider).valueOrNull;

    return AppPageScaffold(
      title: '笔记',
      onRefresh: () async {
        ref.invalidate(allProductNoteLinksProvider);
        ref.invalidate(notesObsidianSettingsProvider);
      },
      children: [
        TextField(
          onChanged: (value) {
            ref.read(notesSearchQueryProvider.notifier).state = value;
          },
          decoration: const InputDecoration(
            hintText: '搜索商品笔记或 Obsidian 路径',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: '商品关联笔记',
          subtitle: '根据数据库中的商品笔记链接实时显示',
          child: links.isEmpty
              ? const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('暂无商品笔记'),
                  subtitle: Text('写入 product_note_links 后，这里会自动显示。'),
                )
              : Column(
                  children: links
                      .map(
                        (link) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => context.push('/product/${link.productId}'),
                          title: Text(link.productName),
                          subtitle: Text('${link.title}\n${link.pathLabel}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.open_in_new_rounded),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: AppSpacing.section),
        SectionCard(
          title: 'Obsidian Sync',
          subtitle: '读取当前设置表中的 Vault 路径和 URI Scheme',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vault 路径'),
                subtitle: Text(settings?.obsidianVaultPath ?? '未配置'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('URI Scheme'),
                subtitle: Text(settings?.obsidianUriScheme ?? '未配置'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
