// lib/models/quiz_logic.dart
import 'dart:math';
import 'bird_data.dart';

class QuizLogic {
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> prev = List.generate(s2.length + 1, (i) => i);
    for (int i = 0; i < s1.length; i++) {
      List<int> curr = [i + 1];
      for (int j = 0; j < s2.length; j++) {
        int insertions = prev[j + 1] + 1;
        int deletions = curr[j] + 1;
        int substitutions = prev[j] + (s1[i] != s2[j] ? 1 : 0);
        curr.add([insertions, deletions, substitutions].reduce(min));
      }
      prev = curr;
    }
    return prev.last;
  }

  static String cleanBirdName(String raw) {
    String name = raw.replaceAll(RegExp(r'\([^)]*\)'), '');
    name = name.replaceAll(RegExp(r'[_\-]+'), ' ');
    name = name.replaceAll(RegExp(r'[^\wа-яА-ЯёЁ\s]'), '');
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool fuzzyMatch(String userInput, String correctName, {double threshold = 0.3}) {
    final userNorm = cleanBirdName(userInput);
    final correctNorm = cleanBirdName(correctName);
    if (userNorm.isEmpty || correctNorm.isEmpty) return false;
    final dist = levenshteinDistance(userNorm, correctNorm);
    final allowed = max(1, (correctNorm.length * threshold).round());
    return dist <= allowed;
  }

  static String extractBirdName(String filename) {
    final cleaned = cleanBirdName(filename);
    String? bestMatch;
    int bestDist = 1000;

    for (final bird in BirdData.allBirds) {
      final birdClean = cleanBirdName(bird);
      if (birdClean == cleaned) return bird;
      final d = levenshteinDistance(cleaned, birdClean);
      if (d < bestDist) {
        bestDist = d;
        bestMatch = bird;
      }
    }
    if (bestMatch != null && bestDist <= 3) return bestMatch;
    return filename;
  }

  static List<String> getOptions(
    String correctName,
    Difficulty difficulty,
    List<String> availableBirds,
  ) {
    if (difficulty == Difficulty.expert) return [];

    final rng = Random();
    final int group = BirdData.birdGroups[correctName] ?? 0;
    final allOther = availableBirds.where((n) => n != correctName).toList();
    List<String> other;

    switch (difficulty) {
      case Difficulty.easy:
        final diffGroup = allOther.where((n) => (BirdData.birdGroups[n] ?? 0) != group).toList();
        diffGroup.shuffle(rng);
        other = diffGroup.take(3).toList();
        if (other.length < 3) {
          allOther.shuffle(rng);
          other = allOther.take(3).toList();
        }
        break;
      case Difficulty.medium:
        final same = allOther.where((n) => (BirdData.birdGroups[n] ?? 0) == group).toList()..shuffle(rng);
        final diff = allOther.where((n) => (BirdData.birdGroups[n] ?? 0) != group).toList()..shuffle(rng);
        other = [];
        if (same.isNotEmpty) {
          other.add(same.first);
          other.addAll(diff.take(2));
        }
        if (other.length < 3) {
          allOther.shuffle(rng);
          other = allOther.take(3).toList();
        }
        break;
      case Difficulty.hard:
        final same = allOther.where((n) => (BirdData.birdGroups[n] ?? 0) == group).toList()..shuffle(rng);
        final diff = allOther.where((n) => (BirdData.birdGroups[n] ?? 0) != group).toList()..shuffle(rng);
        if (same.length >= 2) {
          other = [...same.take(2), ...(diff.isEmpty ? allOther.take(1) : diff.take(1))];
        } else {
          other = same + diff.take(3 - same.length).toList();
        }
        if (other.length < 3) {
          allOther.shuffle(rng);
          other = allOther.take(3).toList();
        }
        break;
      case Difficulty.expert:
        return [];
    }

    final options = [correctName, ...other.take(3)];
    options.shuffle(rng);
    return options;
  }
}