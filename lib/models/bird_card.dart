/// Карточка птицы для тренировки
class BirdCard {
  final String id;
  final String name; // Название птицы (русское или произвольное)
  final String? photoPath; // Путь к фото
  final String? audioPath; // Путь к аудио
  final DateTime createdAt;
  final bool isCustom; // true - пользовательская, false - встроенная

  BirdCard({
    required this.id,
    required this.name,
    this.photoPath,
    this.audioPath,
    required this.createdAt,
    this.isCustom = true,
  });

  factory BirdCard.fromJson(Map<String, dynamic> json) {
    return BirdCard(
      id: json['id'],
      name: json['name'],
      photoPath: json['photoPath'],
      audioPath: json['audioPath'],
      createdAt: DateTime.parse(json['createdAt']),
      isCustom: json['isCustom'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoPath': photoPath,
      'audioPath': audioPath,
      'createdAt': createdAt.toIso8601String(),
      'isCustom': isCustom,
    };
  }

  BirdCard copyWith({
    String? name,
    String? photoPath,
    String? audioPath,
  }) {
    return BirdCard(
      id: id,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt,
      isCustom: isCustom,
    );
  }

  bool get isComplete => photoPath != null && audioPath != null;
}