import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Сервис для скачивания фото птиц через iNaturalist API
class BirdPhotoService {
  static const String _baseUrl = 'https://api.inaturalist.org/v1';
  Directory? _photoDir;

  /// Получить папку для фото
  Future<Directory> getPhotoDir() async {
    if (_photoDir != null) return _photoDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _photoDir = Directory('${appDir.path}/birdiq_photos');
    if (!await _photoDir!.exists()) {
      await _photoDir!.create(recursive: true);
    }
    return _photoDir!;
  }

  /// Найти URL фото по латинскому названию
  Future<List<String>> searchPhotoUrls(String latinName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/observations'
        '?taxon_name=${Uri.encodeComponent(latinName)}'
        '&order=desc'
        '&order_by=created_at'
        '&per_page=5'
        '&quality_grade=research'
        '&has[]=photos',
      );

      debugPrint('iNaturalist: GET $url');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('iNaturalist: HTTP ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final results = data['results'] as List? ?? [];

      final urls = <String>[];
      for (final obs in results) {
        final photos = obs['observation_photos'] as List? ?? [];
        for (final op in photos) {
          final photo = op['photo'] as Map?;
          if (photo != null) {
            final photoUrl = photo['url'] as String?;
            if (photoUrl != null && photoUrl.isNotEmpty) {
              // Заменяем размер на large
              final largeUrl = photoUrl
                  .replaceFirst('/square.', '/large.')
                  .replaceFirst('/small.', '/large.')
                  .replaceFirst('/medium.', '/large.');
              if (!urls.contains(largeUrl)) {
                urls.add(largeUrl);
              }
            }
          }
        }
        if (urls.length >= 5) break;
      }

      debugPrint('iNaturalist: Found ${urls.length} photos for $latinName');
      return urls;
    } catch (e) {
      debugPrint('iNaturalist search error: $e');
      return [];
    }
  }

  /// Скачать лучшее фото для птицы
  /// Возвращает путь к файлу или null
  Future<String?> downloadPhoto(String latinName, String birdName) async {
    try {
      final dir = await getPhotoDir();
      final safeName = birdName
          .replaceAll(RegExp(r'[^\wа-яА-ЯёЁ\s\-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();

      if (safeName.isEmpty) return null;

      final savePath = '${dir.path}/$safeName.jpg';

      // Если фото уже есть — не скачиваем повторно
      if (await File(savePath).exists()) {
        debugPrint('Photo already exists: $savePath');
        return savePath;
      }

      // Ищем фото
      final urls = await searchPhotoUrls(latinName);
      if (urls.isEmpty) {
        debugPrint('No photos found for $latinName');
        return null;
      }

      // Скачиваем первое (лучшее) фото
      final photoUrl = urls.first;
      debugPrint('Downloading: $photoUrl');

      final response = await http
          .get(Uri.parse(photoUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Photo saved: $savePath (${response.bodyBytes.length} bytes)');
        return savePath;
      } else {
        debugPrint('Download failed: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Download photo error: $e');
      return null;
    }
  }

  /// Скачать несколько фото для птицы
  Future<List<String>> downloadMultiplePhotos(
    String latinName,
    String birdName, {
    int count = 3,
  }) async {
    final downloaded = <String>[];
    try {
      final dir = await getPhotoDir();
      final safeName = birdName
          .replaceAll(RegExp(r'[^\wа-яА-ЯёЁ\s\-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();

      if (safeName.isEmpty) return downloaded;

      final urls = await searchPhotoUrls(latinName);
      if (urls.isEmpty) return downloaded;

      for (int i = 0; i < urls.length && i < count; i++) {
        final suffix = i == 0 ? '' : '_$i';
        final savePath = '${dir.path}/$safeName$suffix.jpg';

        if (await File(savePath).exists()) {
          downloaded.add(savePath);
          continue;
        }

        try {
          final response = await http
              .get(Uri.parse(urls[i]))
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final file = File(savePath);
            await file.writeAsBytes(response.bodyBytes);
            downloaded.add(savePath);
            debugPrint('Photo saved: $savePath');
          }
        } catch (e) {
          debugPrint('Download photo $i error: $e');
        }
      }
    } catch (e) {
      debugPrint('Download multiple photos error: $e');
    }
    return downloaded;
  }

  /// Найти фото птицы в локальной папке
  Future<String?> findLocalPhoto(String birdName) async {
    try {
      final dir = await getPhotoDir();
      if (!await dir.exists()) return null;

      final safeName = birdName
          .replaceAll(RegExp(r'[^\wа-яА-ЯёЁ\s\-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();

      final path = '${dir.path}/$safeName.jpg';
      if (await File(path).exists()) return path;
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Удалить фото птицы
  Future<bool> deletePhoto(String birdName) async {
    try {
      final dir = await getPhotoDir();
      final safeName = birdName
          .replaceAll(RegExp(r'[^\wа-яА-ЯёЁ\s\-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .trim();

      final path = '${dir.path}/$safeName.jpg';
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete photo error: $e');
      return false;
    }
  }

  /// Список всех локальных фото
  Future<List<String>> listAllPhotos() async {
    try {
      final dir = await getPhotoDir();
      if (!await dir.exists()) return [];

      return dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
          .map((f) => f.path)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Очистить все фото
  Future<void> clearAll() async {
    final dir = await getPhotoDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _photoDir = null;
  }
}