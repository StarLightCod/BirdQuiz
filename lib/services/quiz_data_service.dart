import 'dart:io';
import '../models/bird_card.dart';
import '../models/bird_data.dart';
import '../services/bird_card_service.dart';
import '../data/file_mapper.dart';

/// Модель данных для викторины
class QuizBirdData {
  final String name;
  final String? photoPath;
  final String? audioPath;
  final bool isCustom;

  QuizBirdData({
    required this.name,
    this.photoPath,
    this.audioPath,
    this.isCustom = false,
  });

  /// Получить путь к фото из assets (для встроенных птиц)
  String? get assetPhotoPath {
    if (isCustom || photoPath != null) return photoPath;
    return FileMapper.getImagePath(name);
  }

  /// Получить путь к аудио из assets (для встроенных птиц)
  String? get assetAudioPath {
    if (isCustom || audioPath != null) return audioPath;
    return FileMapper.getAudioPath(name);
  }
}

/// Сервис для получения данных викторины
class QuizDataService {
  final BirdCardService _cardService = BirdCardService();

  /// Получить список птиц для викторины с фильтрацией по режиму
  Future<List<QuizBirdData>> getQuizBirds(
    List<String> selectedBirds,
    List<String> selectedCards,
    bool useCardsMode,
    QuizMode mode,
  ) async {
    if (useCardsMode) {
      return await _getCardsData(selectedCards);
    } else {
      var birds = _getBirdsData(selectedBirds);
      // Фильтрация по наличию медиа в зависимости от режима
      switch (mode) {
        case QuizMode.images:
          birds = birds.where((b) => FileMapper.hasImage(b.name)).toList();
          break;
        case QuizMode.audio:
          birds = birds.where((b) => FileMapper.hasAudio(b.name)).toList();
          break;
        case QuizMode.complex:
          birds = birds.where((b) => FileMapper.hasImage(b.name) && FileMapper.hasAudio(b.name)).toList();
          break;
      }
      return birds;
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
    return bird.assetPhotoPath != null;
  }

  /// Проверить, есть ли аудио для птицы
  Future<bool> hasAudio(QuizBirdData bird) async {
    if (bird.isCustom) {
      return bird.audioPath != null && File(bird.audioPath!).existsSync();
    }
    return bird.assetAudioPath != null;
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