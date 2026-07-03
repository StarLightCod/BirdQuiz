import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/bird_data.dart';
import '../models/bird_card.dart';
import '../services/quiz_data_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';

class QuizScreen extends StatefulWidget {
  final QuizMode mode;
  final Difficulty difficulty;
  
  const QuizScreen({
    super.key,
    required this.mode,
    required this.difficulty,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _quizDataService = QuizDataService();
  final _audioService = AudioService();
  
  List<QuizBirdData> _birds = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;
  int _correctCount = 0;
  int _totalCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioService.init();
    _loadQuiz();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    
    final appState = context.read<AppState>();
    final birds = await _quizDataService.getQuizBirds(
      appState.selectedBirds,
      appState.selectedCards,
      appState.useCardsMode,
    );
    
    // Перемешиваем КОПИЮ списка
    final shuffled = List<QuizBirdData>.from(birds)..shuffle();
    
    setState(() {
      _birds = shuffled;
      _currentIndex = 0;
      _correctCount = 0;
      _totalCount = 0;
      _isLoading = false;
    });
  }

  Future<void> _playAudio(QuizBirdData bird) async {
    final audioPath = bird.isCustom 
        ? bird.audioPath
        : 'assets/audio/${bird.name}.mp3';
    
    if (audioPath != null) {
      await _audioService.play(audioPath);
    }
  }

  void _selectAnswer(String answer) {
    if (_isAnswered) return;
    
    final currentBird = _birds[_currentIndex];
    final isCorrect = answer == currentBird.name;
    
    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
      _totalCount++;
      if (isCorrect) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _birds.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final appState = context.read<AppState>();
    appState.recordResult(_correctCount, _totalCount);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: const Text('Результаты'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Правильных ответов: $_correctCount из $_totalCount',
              style: AppText.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'Точность: ${_totalCount > 0 ? (_correctCount / _totalCount * 100).toStringAsFixed(1) : 0}%',
              style: AppText.body,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('В меню'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadQuiz();
            },
            child: const Text('Ещё раз'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 800.0 : double.infinity;

    if (_isLoading) {
      return BirdScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Загрузка...'),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_birds.isEmpty) {
      return BirdScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Викторина'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text('Нет птиц для викторины', style: AppText.h3),
              const SizedBox(height: 8),
              Text(
                'Выберите птиц в настройках',
                style: AppText.small,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Вернуться в меню'),
              ),
            ],
          ),
        ),
      );
    }

    final currentBird = _birds[_currentIndex];

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Вопрос ${_currentIndex + 1}/${_birds.length}'),
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: _buildQuestion(currentBird),
                ),
                const SizedBox(height: 16),
                if (_isAnswered)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Выйти'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nextQuestion,
                            child: Text(
                              _currentIndex < _birds.length - 1 
                                  ? 'Далее' 
                                  : 'Результаты',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(QuizBirdData bird) {
    switch (widget.mode) {
      case QuizMode.images:
        return _buildImageQuestion(bird);
      case QuizMode.audio:
        return _buildAudioQuestion(bird);
      case QuizMode.complex:
        return _buildComplexQuestion(bird);
    }
  }

  Widget _buildImageQuestion(QuizBirdData bird) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPhotoWidget(bird),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnswerOptions(bird),
      ],
    );
  }

  Widget _buildPhotoWidget(QuizBirdData bird) {
    if (bird.isCustom) {
      // Пользовательская карточка
      if (bird.photoPath != null && File(bird.photoPath!).existsSync()) {
        return Image.file(
          File(bird.photoPath!),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
      return _buildPlaceholder();
    } else {
      // Встроенная птица - из assets
      return Image.asset(
        'assets/images/${bird.name}.jpg',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.bg3,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 8),
            Text('Фото не найдено', style: AppText.small),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioQuestion(QuizBirdData bird) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassCard(
          child: Column(
            children: [
              Icon(Icons.audiotrack, size: 64, color: AppTheme.accent),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _playAudio(bird),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Прослушать'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildAnswerOptions(bird),
      ],
    );
  }

  Widget _buildComplexQuestion(QuizBirdData bird) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPhotoWidget(bird),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          child: ElevatedButton.icon(
            onPressed: () => _playAudio(bird),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Прослушать голос'),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnswerOptions(bird),
      ],
    );
  }

  Widget _buildAnswerOptions(QuizBirdData bird) {
    final options = _generateOptions(bird);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: options.map((option) {
          final isSelected = _selectedAnswer == option;
          final isCorrect = option == bird.name;
          
          Color? backgroundColor;
          IconData? icon;
          
          if (_isAnswered) {
            if (isCorrect) {
              backgroundColor = AppTheme.accent.withOpacity(0.3);
              icon = Icons.check_circle;
            } else if (isSelected && !isCorrect) {
              backgroundColor = AppTheme.coral.withOpacity(0.3);
              icon = Icons.cancel;
            }
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: _isAnswered ? null : () => _selectAnswer(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> _generateOptions(QuizBirdData bird) {
    final options = <String>{bird.name};
    
    // Создаем КОПИЮ списка перед перемешиванием
    final allBirds = widget.mode == QuizMode.audio 
        ? List<String>.from(_birds.map((b) => b.name))
        : List<String>.from(BirdData.allBirds);
    
    allBirds.shuffle();
    
    for (final name in allBirds) {
      if (options.length >= 4) break;
      if (name != bird.name) {
        options.add(name);
      }
    }
    
    // Заполняем до 4 вариантов если нужно
    while (options.length < 4 && allBirds.length > 0) {
      final random = allBirds[DateTime.now().millisecondsSinceEpoch % allBirds.length];
      if (random != bird.name) {
        options.add(random);
      }
      allBirds.remove(random);
    }
    
    final result = options.toList()..shuffle();
    return result;
  }
}