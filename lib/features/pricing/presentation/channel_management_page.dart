import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/providers/database_providers.dart';
import 'package:lifer/features/pricing/application/pricing_actions.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class ChannelManagementPage extends ConsumerStatefulWidget {
  const ChannelManagementPage({super.key});

  @override
  ConsumerState<ChannelManagementPage> createState() => _ChannelManagementPageState();
}

class _ChannelManagementPageState extends ConsumerState<ChannelManagementPage> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _addressController = TextEditingController();
  String _channelType = 'offline';

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(pricingActionsProvider).createOrUpdateChannel(
          name: _nameController.text,
          channelType: _channelType,
          url: _urlController.text,
          address: _addressController.text,
        );

    if (mounted) {
      _nameController.clear();
      _urlController.clear();
      _addressController.clear();
      setState(() {
        _channelType = 'offline';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(_channelsProvider);

    return FormPageScaffold(
      title: '渠道管理',
      primaryAction: _save,
      primaryLabel: '保存渠道',
      children: [
        FormSection(
          title: '新增或维护渠道',
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '渠道名称'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _channelType,
              decoration: const InputDecoration(labelText: '渠道类型'),
              items: const [
                DropdownMenuItem(value: 'offline', child: Text('线下')),
                DropdownMenuItem(value: 'online', child: Text('线上')),
              ],
              onChanged: (value) {
                setState(() {
                  _channelType = value ?? 'offline';
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: '链接'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: '地址'),
            ),
          ],
        ),
        FormSection(
          title: '现有渠道',
          children: [
            channelsAsync.when(
              data: (channels) {
                if (channels.isEmpty) {
                  return const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('暂无渠道'),
                  );
                }
                return Column(
                  children: channels
                      .map(
                        (channel) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(channel.name),
                          subtitle: Text('${channel.channelType} · ${channel.url ?? channel.address ?? '--'}'),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('加载中...'),
              ),
              error: (_, __) => const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('渠道加载失败'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final _channelsProvider = FutureProvider<List<PurchaseChannel>>((ref) {
  return ref.watch(pricingDaoProvider).getChannels();
});
