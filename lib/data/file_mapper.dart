import 'asset_names.dart';

/// Точный маппинг русских названий птиц на реальные имена файлов.
/// Использует AssetNames как единый источник истины.
class FileMapper {
  FileMapper._();

  // Строим обратный маппинг: русское название -> имя файла
  static final Map<String, String> _imageMap = _buildReverseMap(AssetNames.imageToDisplayName);
  static final Map<String, String> _audioMap = _buildReverseMap(AssetNames.audioToDisplayName);

  static Map<String, String> _buildReverseMap(Map<String, String> assetMap) {
    final map = <String, String>{};
    for (final entry in assetMap.entries) {
      // entry.key – имя файла, entry.value – русское название
      map[entry.value] = entry.key;
    }
    return map;
  }

  /// Получить путь к картинке по русскому названию
  static String? getImagePath(String birdName) {
    final fileName = _imageMap[birdName];
    return fileName != null ? 'assets/images/$fileName' : null;
  }

  /// Получить путь к аудио по русскому названию
  static String? getAudioPath(String birdName) {
    final fileName = _audioMap[birdName];
    return fileName != null ? 'assets/audio/$fileName' : null;
  }

  static bool hasImage(String birdName) => _imageMap.containsKey(birdName);
  static bool hasAudio(String birdName) => _audioMap.containsKey(birdName);

  /// Обратный поиск: по имени файла (с путём или без) получить русское название (для изображений)
  static String? getBirdNameByImageFile(String filePath) {
    final fileName = filePath.split('/').last;
    return AssetNames.imageToDisplayName[fileName];
  }

  /// Обратный поиск: по имени файла (с путём или без) получить русское название (для аудио)
  static String? getBirdNameByAudioFile(String filePath) {
    final fileName = filePath.split('/').last;
    return AssetNames.audioToDisplayName[fileName];
  }
}