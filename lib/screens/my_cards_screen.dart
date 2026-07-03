import 'dart:io';
import 'package:flutter/material.dart';
import '../models/bird_card.dart';
import '../services/bird_card_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  final _cardService = BirdCardService();
  List<BirdCard> _cards = [];
  bool _showIncomplete = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await _cardService.getAllCards();
    setState(() => _cards = cards);
  }

  List<BirdCard> get _filteredCards {
    if (_showIncomplete) return _cards;
    return _cards.where((c) => c.isComplete).toList();
  }

  Future<void> _deleteCard(BirdCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: Text('Удалить карточку "${card.name}"?'),
        content: const Text('Карточка будет удалена безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coral),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _cardService.deleteCard(card.id);
    await _loadCards();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Карточка удалена'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 900.0 : double.infinity;
    final filteredCards = _filteredCards;

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Мои карточки'),
        actions: [
          IconButton(
            icon: Icon(_showIncomplete ? Icons.filter_alt_off : Icons.filter_alt),
            tooltip: _showIncomplete ? 'Только полные' : 'Показать все',
            onPressed: () {
              setState(() => _showIncomplete = !_showIncomplete);
            },
          ),
        ],
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
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.sky, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Карточки с фото и звуком для тренировки. '
                            'Неполные карточки можно дополнить через "Мои медиа".',
                            style: AppText.small,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Всего карточек: ${_cards.length}', style: AppText.small),
                      const Spacer(),
                      PillLabel(
                        text: 'Полных: ${_cards.where((c) => c.isComplete).length}',
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredCards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library, size: 64, color: AppTheme.textMuted),
                              const SizedBox(height: 16),
                              Text('Нет карточек', style: AppText.h3),
                              const SizedBox(height: 8),
                              Text(
                                'Загрузите фото и звук через "Мои медиа"',
                                style: AppText.small,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredCards.length,
                          itemBuilder: (ctx, i) {
                            final card = filteredCards[i];
                            return _CardTile(
                              card: card,
                              onDelete: () => _deleteCard(card),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final BirdCard card;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Фото
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
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 30),
                      ),
                    )
                  : const Icon(Icons.image_not_supported, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    style: AppText.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (card.photoPath != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.sky.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo, size: 12, color: AppTheme.sky),
                              const SizedBox(width: 4),
                              Text('Фото', style: TextStyle(color: AppTheme.sky, fontSize: 10)),
                            ],
                          ),
                        ),
                      if (card.audioPath != null) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.audiotrack, size: 12, color: AppTheme.accent),
                              const SizedBox(width: 4),
                              Text('Звук', style: TextStyle(color: AppTheme.accent, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                      if (!card.isComplete) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Неполная',
                            style: TextStyle(color: AppTheme.amber, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.coral,
              onPressed: onDelete,
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }
}