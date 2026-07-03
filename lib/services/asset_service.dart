import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'media_import_service.dart';

/// Единый сервис для сканирования assets (встроенных + пользовательских)
class AssetService {
  static List<String>? _imageAssets;
  static List<String>? _audioAssets;
  static List<String>? _userImages;
  static List<String>? _userAudio;

  /// Инициализация — сканирует assets и пользовательские папки
  static Future<void> init() async {
    await Future.wait([
      _scanBuiltinAssets(),
      _scanUserFiles(),
    ]);
    debugPrint('AssetService: ${images.length} images, ${audio.length} audio');
  }

  static Future<void> _scanBuiltinAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allKeys = manifest.listAssets();

      _imageAssets = allKeys
          .where((k) =>
              k.startsWith('assets/images/') &&
              (k.endsWith('.jpg') || k.endsWith('.jpeg') || k.endsWith('.png')))
          .toList();

      _audioAssets = allKeys
          .where((k) =>
              k.startsWith('assets/audio/') &&
              (k.endsWith('.mp3') || k.endsWith('.wav') || k.endsWith('.ogg')))
          .toList();
    } catch (e) {
      debugPrint('AssetService builtin error: $e');
      _imageAssets = [];
      _audioAssets = [];
    }
  }

  static Future<void> _scanUserFiles() async {
    try {
      _userImages = await MediaImportService.listUserImages();
      _userAudio = await MediaImportService.listUserAudio();
    } catch (e) {
      debugPrint('AssetService user files error: $e');
      _userImages = [];
      _userAudio = [];
    }
  }

  /// Все изображения (встроенные + пользовательские)
  static List<String> get images => [...?_imageAssets, ...?_userImages];

  /// Всё аудио (встроенное + пользовательское)
  static List<String> get audio => [...?_audioAssets, ...?_userAudio];

  /// Только встроенные изображения
  static List<String> get builtinImages => _imageAssets ?? [];

  /// Только пользовательские изображения
  static List<String> get userImages => _userImages ?? [];

  /// Только встроенное аудио
  static List<String> get builtinAudio => _audioAssets ?? [];

  /// Только пользовательское аудио
  static List<String> get userAudio => _userAudio ?? [];

  /// Пересканировать пользовательские файлы (после импорта)
  static Future<void> refreshUserFiles() async {
    await _scanUserFiles();
  }

  static void reset() {
    _imageAssets = null;
    _audioAssets = null;
    _userImages = null;
    _userAudio = null;
  }
}