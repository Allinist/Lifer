import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifer/app/theme/theme_palette.dart';
import 'package:lifer/features/settings/application/settings_providers.dart';
import 'package:lifer/shared/widgets/form_page_scaffold.dart';
import 'package:lifer/shared/widgets/form_section.dart';

class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage> {
  Color? _primary;
  Color? _secondary;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    final actions = ref.watch(settingsActionsProvider);
    final resolved = resolveThemePalette(settings?.themeMode);
    _primary ??= resolved.primary;
    _secondary ??= resolved.secondary;

    return FormPageScaffold(
      title: '主题色设置',
      primaryLabel: '保存主题',
      primaryAction: () async {
        if (_primary == null || _secondary == null) return;
        final mode = encodeCustomThemeMode(primary: _primary!, secondary: _secondary!);
        await actions.saveThemeMode(mode);
        if (mounted) Navigator.of(context).pop();
      },
      children: [
        FormSection(
          title: '预设主题',
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in themePalettes)
                  _PresetChip(
                    label: p.label,
                    color: p.secondary,
                    onTap: () => setState(() {
                      _primary = p.primary;
                      _secondary = p.secondary;
                    }),
                  ),
              ],
            ),
          ],
        ),
        FormSection(
          title: '单独设置颜色',
          subtitle: '曲线等强调元素跟随“强调色”',
          children: [
            _ColorPickerRow(
              title: '主色',
              selected: _primary!,
              onSelect: (c) => setState(() => _primary = c),
            ),
            const SizedBox(height: 12),
            _ColorPickerRow(
              title: '强调色（曲线）',
              selected: _secondary!,
              onSelect: (c) => setState(() => _secondary = c),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({
    required this.title,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final Color selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in selectableThemeColors)
              InkWell(
                onTap: () => onSelect(c),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.value == selected.value
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

