import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class BirdScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const BirdScaffold({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: child,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bg1,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppTheme.cardBorder,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class PillLabel extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  // Убрали const, добавили значения по умолчанию через ?? в build
  PillLabel({
    super.key,
    required this.text,
    Color? color,
    Color? textColor,
  })  : color = color ?? AppTheme.accent,
        textColor = textColor ?? AppTheme.bg0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  final int current;
  final int correct;
  final int total;

  const ScoreBar({
    super.key,
    required this.current,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? current / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current / $total',
              style: AppText.small.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: AppTheme.accent),
                const SizedBox(width: 4),
                Text(
                  '$correct правильно',
                  style: AppText.small.copyWith(color: AppTheme.accent),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.bg3,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class AnswerButton extends StatelessWidget {
  final String text;
  final AnswerState state;
  final VoidCallback? onTap;

  const AnswerButton({
    super.key,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? trailingIcon;

    switch (state) {
      case AnswerState.idle:
        bgColor = AppTheme.bg2;
        borderColor = AppTheme.cardBorder;
        textColor = AppTheme.textPrimary;
        break;
      case AnswerState.correct:
        bgColor = AppTheme.accent.withOpacity(0.15);
        borderColor = AppTheme.accent;
        textColor = AppTheme.accent;
        trailingIcon = Icon(Icons.check_circle, color: AppTheme.accent, size: 18);
        break;
      case AnswerState.wrong:
        bgColor = AppTheme.coral.withOpacity(0.12);
        borderColor = AppTheme.coral;
        textColor = AppTheme.coral;
        trailingIcon = Icon(Icons.cancel, color: AppTheme.coral, size: 18);
        break;
      case AnswerState.revealed:
        bgColor = AppTheme.amber.withOpacity(0.12);
        borderColor = AppTheme.amber;
        textColor = AppTheme.amber;
        trailingIcon = Icon(Icons.lightbulb_outline, color: AppTheme.amber, size: 18);
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: state == AnswerState.idle ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 13, 14, 15),
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum AnswerState { idle, correct, wrong, revealed }

class AudioPlayButton extends StatefulWidget {
  final VoidCallback? onPlay;
  final bool isPlaying;
  final double size;

  const AudioPlayButton({
    super.key,
    this.onPlay,
    this.isPlaying = false,
    this.size = 120,
  });

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPlay,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          final scale = widget.isPlaying ? _scaleAnim.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isPlaying
                    ? AppTheme.accentGradient
                    : LinearGradient(
                        colors: [AppTheme.bg2, AppTheme.bg3],
                      ),
                border: Border.all(
                  color: widget.isPlaying ? AppTheme.accent : AppTheme.cardBorder,
                  width: 2,
                ),
                boxShadow: widget.isPlaying
                    ? [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: Icon(
                widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: widget.size * 0.43,
                color: widget.isPlaying ? AppTheme.bg0 : AppTheme.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ExpertInput extends StatefulWidget {
  final List<String> suggestions;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool enabled;

  const ExpertInput({
    super.key,
    required this.suggestions,
    required this.controller,
    required this.onSubmit,
    this.enabled = true,
  });

  @override
  State<ExpertInput> createState() => _ExpertInputState();
}

class _ExpertInputState extends State<ExpertInput> {
  List<String> _matches = [];
  bool _showDropdown = false;

  void _updateMatches(String text) {
    if (text.isEmpty) {
      setState(() {
        _matches = [];
        _showDropdown = false;
      });
      return;
    }
    final q = text.toLowerCase();
    final matches = widget.suggestions
        .where((b) => b.toLowerCase().contains(q))
        .take(6)
        .toList();
    setState(() {
      _matches = matches;
      _showDropdown = matches.isNotEmpty;
    });
  }

  void _selectSuggestion(String bird) {
    widget.controller.text = bird;
    setState(() => _showDropdown = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          onChanged: _updateMatches,
          onSubmitted: (_) => widget.onSubmit(),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Введите название птицы...',
            prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
          ),
          textInputAction: TextInputAction.done,
        ),
        if (_showDropdown) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: _matches.map((bird) {
                  return InkWell(
                    onTap: () => _selectSuggestion(bird),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bird,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: widget.enabled ? widget.onSubmit : null,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Проверить'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: AppTheme.bg0,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class ResultDialog extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onHome;
  final VoidCallback onReplay;

  const ResultDialog({
    super.key,
    required this.correct,
    required this.total,
    required this.onHome,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final emoji = pct >= 90 ? '🏆' : pct >= 70 ? '🌿' : pct >= 50 ? '🐦' : '🥚';
    final message = pct >= 90
        ? 'Великолепно!'
        : pct >= 70
            ? 'Хороший результат'
            : pct >= 50
                ? 'Неплохо'
                : 'Продолжайте учиться';

    return Dialog(
      backgroundColor: AppTheme.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(message, style: AppText.h2),
            const SizedBox(height: 8),
            Text(
              '$correct из $total правильно',
              style: AppText.body.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onHome,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(color: AppTheme.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('В меню'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReplay,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ещё раз'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveBirdImage extends StatelessWidget {
  final String assetPath;
  final Widget? placeholder;
  final double borderRadius;

  const ResponsiveBirdImage({
    super.key,
    required this.assetPath,
    this.placeholder,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => placeholder ??
            Container(
              color: AppTheme.bg3,
              child: const Center(
                child: Text('🦅', style: TextStyle(fontSize: 48)),
              ),
            ),
      ),
    );
  }
}

class GradientModeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const GradientModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.fontSize(context, 28, 32, 36);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(Responsive.spacing(context, 16, 20, 24)),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
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
              Text(icon, style: TextStyle(fontSize: iconSize)),
              SizedBox(width: Responsive.spacing(context, 12, 16, 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.fontSize(context, 15, 17, 19),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: Responsive.fontSize(context, 11, 13, 14),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}