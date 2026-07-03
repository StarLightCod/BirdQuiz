import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bird_card.dart';

class BirdCardService {
  static const String _keyCards = 'bird_cards';
  Directory? _cardsDir;

  Future<Directory> getCardsDir() async {
    if (_cardsDir != null) return _cardsDir!;
    final homeDir = Directory(Platform.environment['HOME'] ?? '/tmp');
    _cardsDir = Directory('${homeDir.path}/Downloads/birdiq_cards');
    if (!await _cardsDir!.exists()) {
      await _cardsDir!.create(recursive: true);
    }
    return _cardsDir!;
  }

  Future<List<BirdCard>> getAllCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = prefs.getStringList(_keyCards) ?? [];
    
    return cardsJson.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return BirdCard.fromJson(data);
    }).toList();
  }

  Future<void> _saveCards(List<BirdCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = cards.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_keyCards, cardsJson);
  }

  /// Добавить новую карточку
  Future<BirdCard> addCard({
    required String name,
    String? photoPath,
    String? audioPath,
  }) async {
    final cards = await getAllCards();
    
    final existingIndex = cards.indexWhere((c) => c.name == name);
    
    final card = BirdCard(
      id: existingIndex >= 0 ? cards[existingIndex].id : 'card_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      photoPath: photoPath,
      audioPath: audioPath,
      createdAt: existingIndex >= 0 ? cards[existingIndex].createdAt : DateTime.now(),
      isCustom: true,
    );

    if (existingIndex >= 0) {
      cards[existingIndex] = card;
    } else {
      cards.add(card);
    }

    await _saveCards(cards);
    return card;
  }

  /// Обновить карточку (добавить фото или аудио к существующей)
  Future<BirdCard?> updateCardMedia({
    required String name,
    String? photoPath,
    String? audioPath,
  }) async {
    final cards = await getAllCards();
    final index = cards.indexWhere((c) => c.name == name);
    
    if (index < 0) return null;
    
    final existing = cards[index];
    final updated = BirdCard(
      id: existing.id,
      name: existing.name,
      photoPath: photoPath ?? existing.photoPath,
      audioPath: audioPath ?? existing.audioPath,
      createdAt: existing.createdAt,
      isCustom: existing.isCustom,
    );
    
    cards[index] = updated;
    await _saveCards(cards);
    return updated;
  }

  /// Найти карточку по имени
  Future<BirdCard?> findCardByName(String name) async {
    final cards = await getAllCards();
    try {
      return cards.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteCard(String cardId) async {
    final cards = await getAllCards();
    cards.removeWhere((c) => c.id == cardId);
    await _saveCards(cards);
  }

  Future<List<BirdCard>> getCompleteCards() async {
    final cards = await getAllCards();
    return cards.where((c) => c.isComplete).toList();
  }

  Future<List<BirdCard>> getCustomCards() async {
    final cards = await getAllCards();
    return cards.where((c) => c.isCustom).toList();
  }
}