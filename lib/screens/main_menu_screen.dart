import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bird_data.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';
import 'select_birds_screen.dart';
import 'quiz_screen.dart';
import 'complex_screen.dart';
import 'import_media_screen.dart';
import 'xeno_canto_screen.dart';
import 'theme_settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _startQuiz(BuildContext context, QuizMode mode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _DifficultySheet(mode: mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedCount = state.selectedBirds.length;
    final horizontalPadding = Responsive.spacing(context, 16, 24, 48);

    return BirdScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 900
                ? 900.0
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ───────────────────────────────────────
                      _buildHeader(state, selectedCount),
                      SizedBox(height: Responsive.spacing(context, 24, 32, 40)),

                      // ── Birds filter card ────────────────────────────
                      _buildBirdsFilterCard(context, selectedCount),
                      SizedBox(height: Responsive.spacing(context, 20, 28, 32)),

                      // ── Section label: Actions ───────────────────────
                      Text('ИНСТРУМЕНТЫ', style: AppText.label),
                      const SizedBox(height: 14),

                      // ── Import media card ────────────────────────────
                      _GradientActionCard(
                        icon: Icons.add_photo_alternate_rounded,
                        title: 'Добавить свои медиа',
                        subtitle: 'Фото и звуки ваших птиц',
                        gradient: AppTheme.purpleGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ImportMediaScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Xeno-canto card ──────────────────────────────
                      _GradientActionCard(
                        icon: Icons.public_rounded,
                        title: 'Xeno-canto',
                        subtitle: 'Найти и скачать голоса птиц',
                        gradient: AppTheme.skyGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => XenoCantoScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Theme settings card ──────────────────────────
                      _GradientActionCard(
                        icon: Icons.palette_rounded,
                        title: 'Настройки темы',
                        subtitle: 'Цвета, режим, размер шрифта',
                        gradient: AppTheme.coralGradient,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                        ),
                      ),
                      SizedBox(height: Responsive.spacing(context, 20, 28, 32)),

                      // ── Section label: Game modes ────────────────────
                      Text('РЕЖИМЫ ИГРЫ', style: AppText.label),
                      const SizedBox(height: 14),

                      // ── Mode cards ───────────────────────────────────
                      ...[QuizMode.images, QuizMode.audio, QuizMode.complex].map((mode) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ModeCard(
                            mode: mode,
                            onTap: () => _startQuiz(context, mode),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppState state, int selectedCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🦉', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text('Птицы', style: AppText.hero),
              Text(
                'викторина-определитель',
                style: AppText.body.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        if (state.totalAnswered > 0)
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(state.accuracy * 100).round()}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                  ),
                ),
                Text(
                  '${state.totalCorrect}/${state.totalAnswered}',
                  style: AppText.small,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBirdsFilterCard(BuildContext context, int selectedCount) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SelectBirdsScreen(mode: QuizMode.images)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentDim.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.filter_list_rounded,
                  color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Выбор птиц', style: AppText.h3),
                  Text(
                    'Выбрано: $selectedCount из ${BirdData.allBirds.length}',
                    style: AppText.small,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Mode card ───────────────────────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final QuizMode mode;
  final VoidCallback onTap;

  const _ModeCard({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradients = {
      QuizMode.images: AppTheme.accentGradient,
      QuizMode.audio: AppTheme.skyGradient,
      QuizMode.complex: AppTheme.amberGradient,
    };

    return GradientModeCard(
      icon: mode.icon,
      title: mode.label,
      subtitle: mode.description,
      gradient: gradients[mode]!,
      onTap: onTap,
    );
  }
}

// ─── Gradient action card ────────────────────────────────────────────────────
class _GradientActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _GradientActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ─── Difficulty selection sheet ──────────────────────────────────────────────
class _DifficultySheet extends StatelessWidget {
  final QuizMode mode;

  const _DifficultySheet({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final maxWidth = isDesktop ? 500.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bg1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(mode.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(mode.label, style: AppText.h2),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Выберите уровень сложности',
                style: AppText.small.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ...Difficulty.values.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DifficultyOption(
                    difficulty: d,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (mode == QuizMode.complex) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ComplexScreen(difficulty: d),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(mode: mode, difficulty: d),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Difficulty option ───────────────────────────────────────────────────────
class _DifficultyOption extends StatelessWidget {
  final Difficulty difficulty;
  final VoidCallback onTap;

  const _DifficultyOption({required this.difficulty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = {
      Difficulty.easy: AppTheme.accent,
      Difficulty.medium: AppTheme.amber,
      Difficulty.hard: AppTheme.coral,
      Difficulty.expert: AppTheme.purple,
    };
    final icons = {
      Difficulty.easy: Icons.eco_rounded,
      Difficulty.medium: Icons.thermostat_rounded,
      Difficulty.hard: Icons.local_fire_department_rounded,
      Difficulty.expert: Icons.psychology_rounded,
    };
    final color = colors[difficulty]!;

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icons[difficulty], color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(difficulty.label, style: AppText.h3),
                Text(difficulty.description, style: AppText.small),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}