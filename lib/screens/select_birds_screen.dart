import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/bird_data.dart';
import '../models/bird_card.dart';
import '../services/bird_card_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';

class SelectBirdsScreen extends StatefulWidget {
  final QuizMode mode;
  const SelectBirdsScreen({super.key, required this.mode});

  @override
  State<SelectBirdsScreen> createState() => _SelectBirdsScreenState();
}

class _SelectBirdsScreenState extends State<SelectBirdsScreen> {
  final _cardService = BirdCardService();
  List<BirdCard> _myCards = [];

  @override
  void initState() {
    super.initState();
    _loadMyCards();
  }

  Future<void> _loadMyCards() async {
    final cards = await _cardService.getCompleteCards();
    if (mounted) {
      setState(() => _myCards = cards);
    }
  }

  bool get _hasSelectedCards {
    final appState = context.read<AppState>();
    return appState.selectedCards.isNotEmpty;
  }

  bool get _hasSelectedRegularBirds {
    final appState = context.read<AppState>();
    return appState.selectedBirds.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 900.0 : double.infinity;

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Выбор птиц — ${widget.mode.label}'),
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (_hasSelectedCards) {
                                    _showModeSwitchWarning('карточки');
                                  } else {
                                    appState.setUseCardsMode(false);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !appState.useCardsMode
                                        ? AppTheme.accent.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: !appState.useCardsMode
                                          ? AppTheme.accent
                                          : AppTheme.cardBorder,
                                      width: !appState.useCardsMode ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.list,
                                        color: !appState.useCardsMode
                                            ? AppTheme.accent
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Птицы',
                                        style: TextStyle(
                                          color: !appState.useCardsMode
                                              ? AppTheme.accent
                                              : AppTheme.textSecondary,
                                          fontWeight: !appState.useCardsMode
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (_hasSelectedRegularBirds) {
                                    _showModeSwitchWarning('птицы');
                                  } else {
                                    appState.setUseCardsMode(true);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: appState.useCardsMode
                                        ? AppTheme.sky.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: appState.useCardsMode
                                          ? AppTheme.sky
                                          : AppTheme.cardBorder,
                                      width: appState.useCardsMode ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_library,
                                        color: appState.useCardsMode
                                            ? AppTheme.sky
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Карточки',
                                        style: TextStyle(
                                          color: appState.useCardsMode
                                              ? AppTheme.sky
                                              : AppTheme.textSecondary,
                                          fontWeight: appState.useCardsMode
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (!appState.useCardsMode) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => appState.selectAllBirds(),
                                  icon: const Icon(Icons.check_box, size: 16),
                                  label: const Text('Выбрать всех'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accent,
                                    side: BorderSide(color: AppTheme.accent.withOpacity(0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => appState.clearSelectedBirds(),
                                  icon: const Icon(Icons.check_box_outline_blank, size: 16),
                                  label: const Text('Убрать всех'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.coral,
                                    side: BorderSide(color: AppTheme.coral.withOpacity(0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Выбрано: ${appState.selectedBirds.length}',
                                style: AppText.small,
                              ),
                              Text(
                                'Всего: ${BirdData.allBirds.length}',
                                style: AppText.small,
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Карточек: ${appState.selectedCards.length}',
                                style: AppText.small,
                              ),
                              Text(
                                'Всего: ${_myCards.length}',
                                style: AppText.small,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: appState.useCardsMode
                      ? _buildCardsList(appState)
                      : _buildBirdsList(appState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModeSwitchWarning(String currentMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: const Text('Конфликт выбора'),
        content: Text(
          'У вас уже выбраны $currentMode. '
          'Сначала уберите их, чтобы переключиться.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList(AppState appState) {
    if (_myCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('Нет карточек', style: AppText.h3),
            const SizedBox(height: 8),
            Text(
              'Создайте карточки через "Конструктор карточек"',
              style: AppText.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _myCards.length,
      itemBuilder: (ctx, i) {
        final card = _myCards[i];
        return _CardTileWithCheckbox(card: card);
      },
    );
  }

  Widget _buildBirdsList(AppState appState) {
    final grouped = <int, List<String>>{};
    for (final bird in appState.selectedBirds) {
      final group = BirdData.birdGroups[bird] ?? 0;
      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }
      grouped[group]!.add(bird);
    }

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('Нет выбранных птиц', style: AppText.h3),
            const SizedBox(height: 8),
            Text(
              'Нажмите "Выбрать всех" или добавьте птиц вручную',
              style: AppText.small,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: grouped.length,
      itemBuilder: (ctx, i) {
        final groupNum = grouped.keys.elementAt(i);
        final birds = grouped[groupNum]!;
        final groupName = BirdData.groupNames[groupNum] ?? 'Другие';

        return _BirdGroupTile(
          groupName: groupName,
          birds: birds,
          onRemove: (bird) {
            appState.toggleBird(bird);
          },
        );
      },
    );
  }
}

class _CardTileWithCheckbox extends StatelessWidget {
  final BirdCard card;
  const _CardTileWithCheckbox({required this.card});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isSelected = appState.selectedCards.contains(card.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => appState.toggleCard(card.name),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bg1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.bg3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: card.photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(card.photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 30),
                          ),
                        )
                      : const Icon(Icons.image_not_supported, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name, style: AppText.h3),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.photo, size: 14, color: AppTheme.sky),
                          const SizedBox(width: 4),
                          Icon(Icons.audiotrack,
                              size: 14, color: AppTheme.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Карточка',
                            style: AppText.small.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => appState.toggleCard(card.name),
                  activeColor: AppTheme.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BirdGroupTile extends StatelessWidget {
  final String groupName;
  final List<String> birds;
  final Function(String) onRemove;

  const _BirdGroupTile({
    required this.groupName,
    required this.birds,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(groupName, style: AppText.h3),
                ),
                Text(
                  '${birds.length} птиц',
                  style: AppText.small,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: AppTheme.cardBorder),
            const SizedBox(height: 8),
            ...birds.map((bird) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        bird,
                        style: AppText.body,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      color: AppTheme.coral,
                      onPressed: () => onRemove(bird),
                      tooltip: 'Убрать из списка',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}