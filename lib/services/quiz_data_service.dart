import 'dart:io';
import '../models/bird_card.dart';
import '../models/bird_data.dart';
import '../services/bird_card_service.dart';

/// Модель данных для викторины
class QuizBirdData {
  final String name; // Название птицы
  final String? photoPath; // Путь к фото (null если нет)
  final String? audioPath; // Путь к аудио (null если нет)
  final bool isCustom; // true = карточка, false = встроенная птица

  QuizBirdData({
    required this.name,
    this.photoPath,
    this.audioPath,
    this.isCustom = false,
  });

  /// Получить путь к фото из assets (для встроенных птиц)
  String? get assetPhotoPath {
    if (isCustom || photoPath != null) return photoPath;
    return 'assets/images/$name.jpg';
  }

  /// Получить путь к аудио из assets (для встроенных птиц)
  String? get assetAudioPath {
    if (isCustom || audioPath != null) return audioPath;
    return 'assets/audio/$name.mp3';
  }
}

/// Сервис для получения данных викторины
class QuizDataService {
  final BirdCardService _cardService = BirdCardService();

  /// Получить список птиц для викторины
  Future<List<QuizBirdData>> getQuizBirds(
    List<String> selectedBirds,
    List<String> selectedCards,
    bool useCardsMode,
  ) async {
    if (useCardsMode) {
      return await _getCardsData(selectedCards);
    } else {
      return _getBirdsData(selectedBirds);
    }
  }

  /// Получить данные карточек
  Future<List<QuizBirdData>> _getCardsData(List<String> cardNames) async {
    final allCards = await _cardService.getAllCards();
    final result = <QuizBirdData>[];

    for (final cardName in cardNames) {
      final card = allCards.where((c) => c.name == cardName).firstOrNull;
      if (card != null) {
        result.add(QuizBirdData(
          name: card.name,
          photoPath: card.photoPath,
          audioPath: card.audioPath,
          isCustom: true,
        ));
      }
    }

    return result;
  }

  /// Получить данные встроенных птиц
  List<QuizBirdData> _getBirdsData(List<String> birdNames) {
    return birdNames.map((name) => QuizBirdData(
      name: name,
      isCustom: false,
    )).toList();
  }

  /// Проверить, есть ли фото для птицы
  Future<bool> hasPhoto(QuizBirdData bird) async {
    if (bird.isCustom) {
      return bird.photoPath != null && File(bird.photoPath!).existsSync();
    }
    // Для встроенных птиц проверяем assets
    return true; // Предполагаем что assets есть
  }

  /// Проверить, есть ли аудио для птицы
  Future<bool> hasAudio(QuizBirdData bird) async {
    if (bird.isCustom) {
      return bird.audioPath != null && File(bird.audioPath!).existsSync();
    }
    return true; // Предполагаем что assets есть
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}