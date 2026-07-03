import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Результат импорта файла
class ImportResult {
  final bool success;
  final String? savedPath;
  final String? error;
  final String? birdName;
  final String? fileType;

  ImportResult({
    required this.success,
    this.savedPath,
    this.error,
    this.birdName,
    this.fileType,
  });
}

/// Сервис для импорта пользовательских медиафайлов
class MediaImportService {
  static Directory? _imagesDir;
  static Directory? _audioDir;

  /// Получить папку для пользовательских изображений
  static Future<Directory> getUserImagesDir() async {
    if (_imagesDir == null) {
      final homeDir = Directory(Platform.environment['HOME'] ?? '/tmp');
      _imagesDir = Directory('${homeDir.path}/Downloads/birdiq_media/images');
    }
    
    if (!await _imagesDir!.exists()) {
      await _imagesDir!.create(recursive: true);
    }
    
    return _imagesDir!;
  }

  /// Получить папку для пользовательских аудио
  static Future<Directory> getUserAudioDir() async {
    if (_audioDir == null) {
      final homeDir = Directory(Platform.environment['HOME'] ?? '/tmp');
      _audioDir = Directory('${homeDir.path}/Downloads/birdiq_media/audio');
    }
    
    if (!await _audioDir!.exists()) {
      await _audioDir!.create(recursive: true);
    }
    
    return _audioDir!;
  }

  /// Определить тип файла
  static String detectFileType(String path) {
    final ext = p.extension(path).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      return 'image';
    }
    
    if (['.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac'].contains(ext)) {
      return 'audio';
    }
    
    return 'unknown';
  }

  /// Безопасное имя файла
  static String sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[^\wа-яА-ЯёЁ\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// Получить список пользовательских изображений
  static Future<List<String>> listUserImages() async {
    final dir = await getUserImagesDir();
    if (!await dir.exists()) return [];
    
    return dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final ext = p.extension(f.path).toLowerCase();
          return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
        })
        .map((f) => f.path)
        .toList();
  }

  /// Получить список пользовательских аудио
  static Future<List<String>> listUserAudio() async {
    final dir = await getUserAudioDir();
    if (!await dir.exists()) return [];
    
    return dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final ext = p.extension(f.path).toLowerCase();
          return ['.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac'].contains(ext);
        })
        .map((f) => f.path)
        .toList();
  }

  /// Получить ВСЕ пользовательские файлы (изображения + аудио)
  static Future<List<String>> listAllUserFiles() async {
    final images = await listUserImages();
    final audio = await listUserAudio();
    return [...images, ...audio];
  }

  /// Удалить пользовательский файл
  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  /// Очистить все пользовательские файлы
  static Future<void> clearAll() async {
    try {
      if (_imagesDir != null && await _imagesDir!.exists()) {
        await _imagesDir!.delete(recursive: true);
      }
      if (_audioDir != null && await _audioDir!.exists()) {
        await _audioDir!.delete(recursive: true);
      }
      _imagesDir = null;
      _audioDir = null;
    } catch (e) {
      debugPrint('Clear error: $e');
    }
  }
}