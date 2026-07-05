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
  String _searchQuery = '';

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

                // Переключатель режимов
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
                                  if (appState.selectedCards.isNotEmpty) {
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
                                  if (appState.selectedBirds.isNotEmpty) {
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

                        // Статистика
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              appState.useCardsMode
                                  ? 'Выбрано карточек: ${appState.selectedCards.length}'
                                  : 'Выбрано птиц: ${appState.selectedBirds.length}',
                              style: AppText.small,
                            ),
                            Text(
                              appState.useCardsMode
                                  ? 'Всего карточек: ${_myCards.length}'
                                  : 'Всего птиц: ${BirdData.allBirds.length}',
                              style: AppText.small,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Поиск и кнопки
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(
                            hintText: 'Поиск...',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          if (appState.useCardsMode) {
                            // Выбрать все карточки
                            final allNames = _myCards.map((c) => c.name).toList();
                            for (final name in allNames) {
                              if (!appState.selectedCards.contains(name)) {
                                appState.toggleCard(name);
                              }
                            }
                          } else {
                            // Выбрать всех птиц (с учётом фильтра)
                            final filtered = _filteredBirds;
                            for (final bird in filtered) {
                              if (!appState.selectedBirds.contains(bird)) {
                                appState.toggleBird(bird);
                              }
                            }
                          }
                        },
                        child: const Text('Все'),
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: () {
                          if (appState.useCardsMode) {
                            for (final name in appState.selectedCards.toList()) {
                              appState.toggleCard(name);
                            }
                          } else {
                            for (final bird in appState.selectedBirds.toList()) {
                              appState.toggleBird(bird);
                            }
                          }
                        },
                        child: const Text('Сбросить'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Основной список
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

  List<String> get _filteredBirds {
    final all = BirdData.allBirds;
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all.where((b) => b.toLowerCase().contains(q)).toList();
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
    final filtered = _filteredBirds;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('Нет птиц, соответствующих поиску', style: AppText.h3),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final bird = filtered[i];
        final isSelected = appState.selectedBirds.contains(bird);
        return CheckboxListTile(
          value: isSelected,
          title: Text(bird),
          onChanged: (_) => appState.toggleBird(bird),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.accent,
          secondary: isSelected
              ? Icon(Icons.check_circle, color: AppTheme.accent)
              : null,
        );
      },
    );
  }
}

// Вспомогательный виджет для карточек (без изменений)
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