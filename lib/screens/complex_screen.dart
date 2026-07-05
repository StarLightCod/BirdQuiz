// lib/screens/complex_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bird_data.dart';
import '../models/app_state.dart';
import '../models/quiz_logic.dart';
import '../services/audio_service.dart';
import '../services/asset_service.dart';
import '../data/asset_names.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';
import '../data/file_mapper.dart';

class _BirdCard {
  final String assetPath;
  final String birdName;
  String? assignedAudioAsset;
  String? assignedBirdName;
  AnswerState status = AnswerState.idle;
  _BirdCard({required this.assetPath, required this.birdName});
}

class _AudioItem {
  final String assetPath;
  final String birdName;
  _AudioItem({required this.assetPath, required this.birdName});
}

class ComplexScreen extends StatefulWidget {
  final Difficulty difficulty;
  const ComplexScreen({super.key, required this.difficulty});

  @override
  State<ComplexScreen> createState() => _ComplexScreenState();
}

class _ComplexScreenState extends State<ComplexScreen> {
  final _audio = AudioService();
  List<_BirdCard> _cards = [];
  List<_AudioItem> _audioItems = [];
  String? _resultMessage;
  bool _checked = false;
  bool _loading = true;
  bool _isPlaying = false;
  String? _playingAsset;

  int _maxAvailable = 4;
  int _cardCount = 4;

  bool get _isEasy => widget.difficulty == Difficulty.easy;
  bool get _isExpert => widget.difficulty == Difficulty.expert;

  @override
  void initState() {
    super.initState();
    _audio.onPlayingChanged = (playing) {
      if (mounted) setState(() => _isPlaying = playing);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  @override
  void dispose() {
    _audio.onPlayingChanged = null;
    _audio.dispose();
    super.dispose();
  }

  Future<void> _setup() async {
    await AssetService.init();
    await _audio.init();
    _initGame();
  }

  // ============================================================
  // ИСПРАВЛЕННЫЙ _decodeName
  // ============================================================
  String _decodeName(String assetPath) {
    final filename = assetPath.split('/').last;
    
    // 1. Пробуем через FileMapper (он использует AssetNames)
    final fromMapper = FileMapper.getBirdNameByImageFile(filename) 
        ?? FileMapper.getBirdNameByAudioFile(filename);
    if (fromMapper != null) return fromMapper;
    
    // 2. Fallback: старая логика
    String decoded;
    try { decoded = Uri.decodeComponent(filename); } catch (_) { decoded = filename; }
    final noExt = decoded.replaceAll(RegExp(r'\.[^.]+$'), '');
    return QuizLogic.extractBirdName(noExt.replaceAll('_', ' ').trim());
  }
  
  List<String> _buildPool() {
    final appState = context.read<AppState>();
    final selected = appState.selectedBirds;

    final imgByBird = <String, String>{};
    for (final a in AssetService.images) {
      imgByBird.putIfAbsent(_decodeName(a), () => a);
    }
    final audByBird = <String, String>{};
    for (final a in AssetService.audio) {
      audByBird.putIfAbsent(_decodeName(a), () => a);
    }

    List<String> pool;
    if (_isExpert) {
      pool = imgByBird.keys
          .where((b) => selected.contains(b) ||
              selected.any((s) => QuizLogic.fuzzyMatch(b, s, threshold: 0.25)))
          .toList();
      if (pool.length < 4) pool = imgByBird.keys.toList();
    } else {
      pool = imgByBird.keys
          .where((b) => audByBird.containsKey(b))
          .where((b) => selected.contains(b) ||
              selected.any((s) => QuizLogic.fuzzyMatch(b, s, threshold: 0.25)))
          .toList();
      if (pool.length < 4) {
        pool = imgByBird.keys.where((b) => audByBird.containsKey(b)).toList();
      }
    }

    _maxAvailable = pool.length.clamp(4, 9999);
    if (_cardCount > _maxAvailable) _cardCount = _maxAvailable;
    if (_cardCount < 4) _cardCount = 4;

    return pool;
  }

  void _initGame() {
    final pool = _buildPool();
    final audByBird = <String, String>{};
    for (final a in AssetService.audio) {
      audByBird.putIfAbsent(_decodeName(a), () => a);
    }
    final imgByBird = <String, String>{};
    for (final a in AssetService.images) {
      imgByBird.putIfAbsent(_decodeName(a), () => a);
    }

    if (pool.length < 4) {
      setState(() {
        _cards = [];
        _resultMessage = 'Недостаточно медиафайлов';
        _loading = false;
      });
      return;
    }

    final rng = Random();
    final chosen = List<String>.from(pool)..shuffle(rng);
    final take = chosen.take(_cardCount).toList();

    setState(() {
      _cards = take.map((b) => _BirdCard(
        assetPath: imgByBird[b]!,
        birdName: b,
      )).toList();

      final audioList = take
          .where((b) => audByBird.containsKey(b))
          .map((b) => _AudioItem(assetPath: audByBird[b]!, birdName: b))
          .toList()..shuffle(rng);
      _audioItems = audioList;

      _checked = false;
      _resultMessage = null;
      _loading = false;
      _playingAsset = null;
    });
  }

  Future<void> _playAudio(String assetPath) async {
    if (!mounted) return;
    if (context.read<AppState>().isMuted) return;
    try {
      if (_playingAsset == assetPath && _isPlaying) {
        await _audio.stop();
        setState(() => _playingAsset = null);
      } else {
        setState(() => _playingAsset = assetPath);
        await _audio.play(assetPath);
      }
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  void _assignAudio(_BirdCard card, _AudioItem audio) {
    if (_checked) return;
    for (final c in _cards) {
      if (c.assignedAudioAsset == audio.assetPath) {
        c.assignedAudioAsset = null;
        c.assignedBirdName = null;
        c.status = AnswerState.idle;
      }
    }
    setState(() {
      card.assignedAudioAsset = audio.assetPath;
      card.assignedBirdName = audio.birdName;
      card.status = AnswerState.idle;
    });
  }

  void _checkAnswers() {
    int correct = 0;
    setState(() {
      _checked = true;
      for (final card in _cards) {
        if (_isExpert) {
          final input = card.assignedBirdName ?? '';
          final ok = input.isNotEmpty &&
              QuizLogic.fuzzyMatch(input, card.birdName, threshold: 0.3);
          card.status = ok ? AnswerState.correct : AnswerState.wrong;
          if (ok) correct++;
        } else {
          if (card.assignedAudioAsset != null) {
            final audioBird = _decodeName(card.assignedAudioAsset!);
            final ok = audioBird == card.birdName ||
                QuizLogic.fuzzyMatch(audioBird, card.birdName, threshold: 0.2);
            card.status = ok ? AnswerState.correct : AnswerState.wrong;
            if (ok) correct++;
          } else {
            card.status = AnswerState.wrong;
          }
        }
      }
      _resultMessage = 'Правильно: $correct / ${_cards.length}';
    });
    context.read<AppState>().recordResult(correct, _cards.length);
  }

  void _showExpertInput(_BirdCard card) {
    if (_checked) return;
    final ctrl = TextEditingController(text: card.assignedBirdName ?? '');
    final appState = context.read<AppState>();

    _AudioItem? matchingAudio;
    try {
      matchingAudio = _audioItems.firstWhere(
        (a) => a.birdName == card.birdName ||
            QuizLogic.fuzzyMatch(a.birdName, card.birdName, threshold: 0.25),
      );
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Назовите птицу', style: AppText.h2),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (matchingAudio != null)
                  GestureDetector(
                    onTap: () => _playAudio(matchingAudio!.assetPath),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.sky.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.sky.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (_isPlaying && _playingAsset == matchingAudio.assetPath)
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AppTheme.sky,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (_isPlaying && _playingAsset == matchingAudio.assetPath)
                                ? 'Воспроизводится...'
                                : 'Прослушать птицу',
                            style: TextStyle(
                                color: AppTheme.sky, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ExpertInput(
                  suggestions: appState.selectedBirds,
                  controller: ctrl,
                  onSubmit: () {
                    final input = ctrl.text.trim();
                    setState(() => card.assignedBirdName = input);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showZoom(String assetPath, String birdName) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Text('🦅', style: TextStyle(fontSize: 64))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(birdName,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Комплексный режим'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PillLabel(text: widget.difficulty.label),
          ),
          IconButton(
            icon: Icon(
              appState.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => appState.toggleMute(),
          ),
        ],
      ),
      child: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : Column(
                children: [
                  _ControlsBar(
                    cardCount: _cardCount,
                    maxCount: _maxAvailable,
                    resultMessage: _resultMessage,
                    onCountChanged: (v) => setState(() => _cardCount = v),
                    onRefresh: () {
                      setState(() => _loading = true);
                      Future.microtask(_initGame);
                    },
                    onCheck: _cards.isEmpty ? null : _checkAnswers,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // На десктопе и планшете — ряд, на мобилке — колонка
                        final useRow = constraints.maxWidth >= 700;
                        final audioPanelWidth = isDesktop
                            ? 240.0
                            : isTablet
                                ? 200.0
                                : 160.0;

                        if (useRow) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildGrid(constraints.maxWidth - audioPanelWidth),
                              ),
                              SizedBox(
                                width: audioPanelWidth,
                                child: _AudioPanel(
                                  items: _audioItems,
                                  playingAsset: _playingAsset,
                                  isPlaying: _isPlaying,
                                  showLabels: _isEasy,
                                  isExpert: _isExpert,
                                  onPlay: _playAudio,
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Мобильный: grid сверху, audio panel снизу
                          return Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildGrid(constraints.maxWidth),
                              ),
                              SizedBox(
                                height: constraints.maxHeight * 0.3,
                                child: _AudioPanel(
                                  items: _audioItems,
                                  playingAsset: _playingAsset,
                                  isPlaying: _isPlaying,
                                  showLabels: _isEasy,
                                  isExpert: _isExpert,
                                  onPlay: _playAudio,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Text(
                      _isExpert
                          ? 'Нажмите карточку → введите название и/или прослушайте звук'
                          : 'Перетащите звук на карточку • нажмите карточку для зума',
                      style: AppText.small.copyWith(
                          color: AppTheme.textMuted, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGrid(double availableWidth) {
    // Адаптивное количество колонок на основе ширины
    int crossAxisCount;
    if (_cardCount <= 4) {
      crossAxisCount = availableWidth > 500 ? 2 : 2;
    } else if (_cardCount <= 9) {
      crossAxisCount = availableWidth > 700 ? 3 : 2;
    } else {
      crossAxisCount = availableWidth > 900 ? 4 : 3;
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: _cards.length,
      itemBuilder: (ctx, i) {
        final card = _cards[i];
        return _ImageCardWidget(
          card: card,
          isExpert: _isExpert,
          checked: _checked,
          onTap: () => _isExpert
              ? _showExpertInput(card)
              : _showZoom(card.assetPath, card.birdName),
          onLongPress: () => _showZoom(card.assetPath, card.birdName),
          onDrop: (audio) => _assignAudio(card, audio),
        );
      },
    );
  }
}

class _ControlsBar extends StatelessWidget {
  final int cardCount;
  final int maxCount;
  final String? resultMessage;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onRefresh;
  final VoidCallback? onCheck;

  const _ControlsBar({
    required this.cardCount,
    required this.maxCount,
    required this.resultMessage,
    required this.onCountChanged,
    required this.onRefresh,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Карточки:', style: AppText.small),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: AppTheme.accent,
                    inactiveTrackColor: AppTheme.bg3,
                    thumbColor: AppTheme.accent,
                    overlayColor: AppTheme.accent.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: cardCount.toDouble(),
                    min: 4,
                    max: maxCount.toDouble(),
                    divisions: (maxCount - 4).clamp(1, 9999),
                    onChanged: (v) => onCountChanged(v.round()),
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                ),
                child: Text(
                  '$cardCount',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.refresh_rounded,
                      color: AppTheme.textSecondary, size: 20),
                ),
              ),
              ElevatedButton(
                onPressed: onCheck,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Проверить'),
              ),
            ],
          ),
          if (resultMessage != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Text(
                resultMessage!,
                style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageCardWidget extends StatelessWidget {
  final _BirdCard card;
  final bool isExpert;
  final bool checked;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<_AudioItem> onDrop;

  const _ImageCardWidget({
    required this.card,
    required this.isExpert,
    required this.checked,
    required this.onTap,
    required this.onLongPress,
    required this.onDrop,
  });

  Color get _borderColor {
    switch (card.status) {
      case AnswerState.correct: return AppTheme.accent;
      case AnswerState.wrong:   return AppTheme.coral;
      default:                  return AppTheme.cardBorder;
    }
  }

  Widget _cardBody() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _borderColor,
            width: card.status != AnswerState.idle ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              child: Image.asset(
                card.assetPath,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.bg3,
                  child: const Center(
                      child: Text('🦅', style: TextStyle(fontSize: 22))),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (checked)
                    Text(
                      card.birdName,
                      style: TextStyle(
                          fontSize: 8, color: AppTheme.textSecondary),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (isExpert && card.assignedBirdName != null)
                    Text(
                      card.assignedBirdName!,
                      style: TextStyle(fontSize: 8, color: AppTheme.sky),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (!isExpert && card.assignedAudioAsset != null)
                    Icon(Icons.music_note_rounded,
                        size: 10, color: AppTheme.sky),
                  if (isExpert && !checked)
                    Icon(
                      card.assignedBirdName != null
                          ? Icons.edit_rounded
                          : Icons.add_rounded,
                      size: 10,
                      color: AppTheme.textMuted,
                    ),
                  if (card.status == AnswerState.correct)
                    Icon(Icons.check_circle, size: 12, color: AppTheme.accent)
                  else if (card.status == AnswerState.wrong)
                    Icon(Icons.cancel, size: 12, color: AppTheme.coral),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isExpert) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: _cardBody(),
      );
    }

    return DragTarget<_AudioItem>(
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (ctx, candidates, _) {
        final hovered = candidates.isNotEmpty;
        return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hovered ? AppTheme.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: _cardBody(),
          ),
        );
      },
    );
  }
}

class _AudioPanel extends StatelessWidget {
  final List<_AudioItem> items;
  final String? playingAsset;
  final bool isPlaying;
  final bool showLabels;
  final bool isExpert;
  final Future<void> Function(String) onPlay;

  const _AudioPanel({
    required this.items,
    required this.playingAsset,
    required this.isPlaying,
    required this.showLabels,
    required this.isExpert,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Text(
              isExpert ? '🎵 Звуки' : '🎵 Перетащи',
              style: AppText.small.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          Container(height: 1, color: AppTheme.divider),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('Нет аудио',
                        style: AppText.small
                            .copyWith(color: AppTheme.textMuted, fontSize: 10)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(5),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final active =
                          isPlaying && playingAsset == item.assetPath;
                      final tile = _AudioTileContent(
                        item: item,
                        isPlaying: active,
                        showLabel: showLabels,
                        onPlay: () => onPlay(item.assetPath),
                      );
                      if (isExpert) return tile;
                      return _DraggableAudioTile(
                          item: item, isPlaying: active, child: tile);
                    },
                  ),
          ),
          if (!isExpert)
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                'Перетащи\nна карточку',
                style: AppText.small
                    .copyWith(color: AppTheme.textMuted, fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioTileContent extends StatelessWidget {
  final _AudioItem item;
  final bool isPlaying;
  final bool showLabel;
  final VoidCallback onPlay;

  const _AudioTileContent({
    required this.item,
    required this.isPlaying,
    required this.showLabel,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: isPlaying ? AppTheme.sky.withOpacity(0.12) : AppTheme.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isPlaying
                ? AppTheme.sky.withOpacity(0.5)
                : AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: showLabel
                ? Text(
                    item.birdName,
                    style: TextStyle(
                      color:
                          isPlaying ? AppTheme.sky : AppTheme.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : Icon(
                    Icons.music_note_rounded,
                    size: 14,
                    color: isPlaying ? AppTheme.sky : AppTheme.textMuted,
                  ),
          ),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isPlaying
                    ? AppTheme.sky.withOpacity(0.3)
                    : AppTheme.sky.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppTheme.sky,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableAudioTile extends StatelessWidget {
  final _AudioItem item;
  final bool isPlaying;
  final Widget child;

  const _DraggableAudioTile({
    required this.item,
    required this.isPlaying,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<_AudioItem>(
      data: item,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.sky.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.music_note_rounded, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.birdName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}