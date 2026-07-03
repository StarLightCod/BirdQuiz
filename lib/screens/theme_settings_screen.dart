import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  bool _autoBg = true;

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 800.0 : double.infinity;

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Настройки темы'),
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ─ Режим темы ─────────────────────────────
                _SectionTitle(title: 'Режим отображения', icon: Icons.brightness_6),
                const SizedBox(height: 12),
                _ThemeModeSelector(
                  current: themeService.mode,
                  onChanged: themeService.setMode,
                ),
                const SizedBox(height: 24),

                // ── Пресеты ──────────────────────────────
                _SectionTitle(title: 'Цветовая схема', icon: Icons.palette),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ColorPreset.presets.map((preset) {
                    final isSelected = themeService.presetId == preset.id &&
                        !themeService.useCustom;
                    return _PresetChip(
                      preset: preset,
                      isSelected: isSelected,
                      onTap: () {
                        themeService.setUseCustom(false);
                        themeService.setPreset(preset.id);
                        setState(() => _autoBg = true);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Кастомные цвета ──────────────────────
                _SectionTitle(title: 'Свои цвета', icon: Icons.color_lens),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        title: const Text('Использовать свои цвета'),
                        subtitle: const Text('Переопределить пресет'),
                        value: themeService.useCustom,
                        activeColor: AppTheme.accent,
                        onChanged: (v) {
                          themeService.setUseCustom(v);
                          if (v) {
                            themeService.setCustomColors(
                              primary: themeService.customPrimary,
                              secondary: themeService.customSecondary,
                              accent: themeService.customAccent,
                              bg0: themeService.customBg0,
                              bg1: themeService.customBg1,
                              bg2: themeService.customBg2,
                            );
                          }
                        },
                      ),
                      if (themeService.useCustom) ...[
                        const SizedBox(height: 8),
                        _ColorPickerTile(
                          label: 'Основной цвет (кнопки, акценты)',
                          color: themeService.customPrimary,
                          onChanged: (c) {
                            if (_autoBg) {
                              themeService.setPrimaryAndAutoBg(c);
                            } else {
                              themeService.setCustomColors(primary: c);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _ColorPickerTile(
                          label: 'Вторичный цвет',
                          color: themeService.customSecondary,
                          onChanged: (c) => themeService.setCustomColors(secondary: c),
                        ),
                        const SizedBox(height: 8),
                        _ColorPickerTile(
                          label: 'Акцентный цвет',
                          color: themeService.customAccent,
                          onChanged: (c) => themeService.setCustomColors(accent: c),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Настройка фона ───────────────────────
                if (themeService.useCustom) ...[
                  _SectionTitle(title: 'Цвета фона', icon: Icons.layers),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          title: const Text('Авто-генерация фона'),
                          subtitle: const Text('Фон создаётся из основного цвета'),
                          value: _autoBg,
                          activeColor: AppTheme.accent,
                          onChanged: (v) {
                            setState(() => _autoBg = v);
                            if (v) {
                              themeService.setPrimaryAndAutoBg(themeService.customPrimary);
                            }
                          },
                        ),
                        if (!_autoBg) ...[
                          const SizedBox(height: 8),
                          _ColorPickerTile(
                            label: 'Фон 0 (основной, градиент)',
                            color: themeService.customBg0,
                            onChanged: (c) => themeService.setCustomColors(bg0: c),
                          ),
                          const SizedBox(height: 8),
                          _ColorPickerTile(
                            label: 'Фон 1 (карточки)',
                            color: themeService.customBg1,
                            onChanged: (c) => themeService.setCustomColors(bg1: c),
                          ),
                          const SizedBox(height: 8),
                          _ColorPickerTile(
                            label: 'Фон 2 (элементы)',
                            color: themeService.customBg2,
                            onChanged: (c) => themeService.setCustomColors(bg2: c),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Размер шрифта ────────────────────────
                _SectionTitle(title: 'Размер текста', icon: Icons.text_fields),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_size, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${(themeService.fontScale * 100).round()}%',
                            style: AppText.body,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: themeService.fontScale,
                        min: 0.8,
                        max: 1.4,
                        divisions: 6,
                        label: '${(themeService.fontScale * 100).round()}%',
                        onChanged: themeService.setFontScale,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Превью ───────────────────────────────
                _SectionTitle(title: 'Предпросмотр', icon: Icons.preview),
                const SizedBox(height: 12),
                _ThemePreview(),
                const SizedBox(height: 24),

                // ─ Сброс ────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => _showResetDialog(context, themeService),
                  icon: const Icon(Icons.restore),
                  label: const Text('Сбросить к настройкам по умолчанию'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.coral,
                    side: BorderSide(color: AppTheme.coral.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, ThemeService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: const Text('Сбросить настройки?'),
        content: const Text('Все настройки темы будут сброшены к значениям по умолчанию.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              service.resetToDefaults();
              setState(() => _autoBg = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coral),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppText.h3),
      ],
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final AppThemeMode current;
  final ValueChanged<AppThemeMode> onChanged;

  const _ThemeModeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final modes = [
      (AppThemeMode.dark, Icons.dark_mode, 'Тёмная'),
      (AppThemeMode.light, Icons.light_mode, 'Светлая'),
      (AppThemeMode.system, Icons.settings_suggest, 'Системная'),
    ];

    return Row(
      children: modes.map((m) {
        final mode = m.$1;
        final icon = m.$2;
        final label = m.$3;
        final selected = current == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.accent.withOpacity(0.15)
                      : AppTheme.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppTheme.accent : AppTheme.cardBorder,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: selected ? AppTheme.accent : AppTheme.textSecondary,
                        size: 24),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? AppTheme.accent : AppTheme.textSecondary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final ColorPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [preset.secondary.withOpacity(0.4), preset.primary],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: preset.primary.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(preset.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              preset.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorPickerTile extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorPickerTile({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.body)),
            Icon(Icons.edit, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    Color picked = color;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: Text('Выберите $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (c) => picked = c,
            paletteType: PaletteType.hsv,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(picked);
              Navigator.pop(ctx);
            },
            child: const Text('Выбрать'),
          ),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Основной цвет', style: AppText.h3),
                    Text('Используется для кнопок и акцентов',
                        style: AppText.small),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ColorSwatch(color: AppTheme.accent, label: 'Primary'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorSwatch(color: AppTheme.accentDim, label: 'Secondary'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorSwatch(color: AppTheme.amber, label: 'Accent'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ColorSwatch(color: AppTheme.bg0, label: 'Bg 0'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorSwatch(color: AppTheme.bg1, label: 'Bg 1'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ColorSwatch(color: AppTheme.bg2, label: 'Bg 2'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String label;
  const _ColorSwatch({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}