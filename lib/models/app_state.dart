import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bird_data.dart';
import 'bird_card.dart';
import '../services/bird_card_service.dart';

class AppState extends ChangeNotifier {
  List<String> _selectedBirds = List.from(BirdData.allBirds);
  List<String> _selectedCards = [];
  bool _useCardsMode = false;
  bool _isMuted = false;
  int _totalCorrect = 0;
  int _totalAnswered = 0;

  List<String> get selectedBirds => _selectedBirds;
  List<String> get selectedCards => _selectedCards;
  bool get useCardsMode => _useCardsMode;
  bool get isMuted => _isMuted;
  int get totalCorrect => _totalCorrect;
  int get totalAnswered => _totalAnswered;
  int get totalWrong => _totalAnswered - _totalCorrect;

  double get accuracy =>
      _totalAnswered == 0 ? 0.0 : _totalCorrect / _totalAnswered;

  /// Получить количество активных элементов (птиц или карточек)
  int get activeCount => _useCardsMode ? _selectedCards.length : _selectedBirds.length;

  /// Проверить, есть ли активные элементы
  bool get hasActiveItems => activeCount > 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    final stored = prefs.getString('selected_birds');
    if (stored != null) {
      try {
        final List<dynamic> decoded = json.decode(stored);
        final birds = decoded.cast<String>().toList();
        if (birds.isNotEmpty) _selectedBirds = birds;
      } catch (_) {}
    }
    
    final cardsStored = prefs.getString('selected_cards');
    if (cardsStored != null) {
      try {
        final List<dynamic> decoded = json.decode(cardsStored);
        _selectedCards = decoded.cast<String>().toList();
      } catch (_) {}
    }
    
    _useCardsMode = prefs.getBool('use_cards_mode') ?? false;
    _isMuted = prefs.getBool('muted') ?? false;
    _totalCorrect = prefs.getInt('total_correct') ?? 0;
    _totalAnswered = prefs.getInt('total_answered') ?? 0;
    notifyListeners();
  }

  Future<void> saveSelectedBirds(List<String> birds) async {
    _selectedBirds = List.from(birds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_birds', json.encode(_selectedBirds));
    notifyListeners();
  }

  Future<void> saveSelectedCards(List<String> cards) async {
    _selectedCards = List.from(cards);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_cards', json.encode(_selectedCards));
    notifyListeners();
  }

  Future<void> toggleCard(String cardName) async {
    if (_selectedCards.contains(cardName)) {
      _selectedCards.remove(cardName);
    } else {
      _selectedCards.add(cardName);
    }
    await saveSelectedCards(_selectedCards);
  }

  Future<void> setUseCardsMode(bool value) async {
    _useCardsMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_cards_mode', value);
    notifyListeners();
  }

  Future<void> selectAllBirds() async {
    _selectedBirds = List.from(BirdData.allBirds);
    await saveSelectedBirds(_selectedBirds);
  }

  Future<void> clearSelectedBirds() async {
    _selectedBirds = [];
    await saveSelectedBirds(_selectedBirds);
  }

  Future<void> toggleBird(String bird) async {
    if (_selectedBirds.contains(bird)) {
      _selectedBirds.remove(bird);
    } else {
      _selectedBirds.add(bird);
    }
    await saveSelectedBirds(_selectedBirds);
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('muted', _isMuted);
    notifyListeners();
  }

  Future<void> recordResult(int correct, int total) async {
    _totalCorrect += correct;
    _totalAnswered += total;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_correct', _totalCorrect);
    await prefs.setInt('total_answered', _totalAnswered);
    notifyListeners();
  }

  Future<void> resetStats() async {
    _totalCorrect = 0;
    _totalAnswered = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('total_correct');
    await prefs.remove('total_answered');
    notifyListeners();
  }

  Future<void> resetAll() async {
    _selectedBirds = List.from(BirdData.allBirds);
    _selectedCards = [];
    _useCardsMode = false;
    _isMuted = false;
    _totalCorrect = 0;
    _totalAnswered = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> addBird(String bird) async {
    if (!_selectedBirds.contains(bird)) {
      _selectedBirds.add(bird);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_birds', json.encode(_selectedBirds));
      notifyListeners();
    }
  }

  Future<void> removeBird(String bird) async {
    _selectedBirds.remove(bird);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_birds', json.encode(_selectedBirds));
    notifyListeners();
  }
}