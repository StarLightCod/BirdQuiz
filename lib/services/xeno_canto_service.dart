import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/bird_catalog.dart'; // ← Импорт каталога птиц

/// Модель записи с Xeno-canto
class XcRecording {
  final String id;
  final String genus;
  final String species;
  final String englishName;
  final String recordist;
  final String location;
  final String fileUrl;
  final String fileName;
  final String license;
  final String quality;
  final String length;
  final List<String> types;
  final int? downloadCount;

  XcRecording({
    required this.id,
    required this.genus,
    required this.species,
    required this.englishName,
    required this.recordist,
    required this.location,
    required this.fileUrl,
    required this.fileName,
    required this.license,
    required this.quality,
    required this.length,
    required this.types,
    this.downloadCount,
  });

  String get fullName => '$genus $species';
  String get displayName => englishName.isNotEmpty ? englishName : fullName;

  factory XcRecording.fromJson(Map<String, dynamic> json) {
    return XcRecording(
      id: json['id']?.toString() ?? '',
      genus: json['gen'] ?? '',
      species: json['sp'] ?? '',
      englishName: json['en'] ?? '',
      recordist: json['rec'] ?? '',
      location: json['loc'] ?? '',
      fileUrl: json['file'] ?? '',
      fileName: json['file-name'] ?? 'XC${json['id']}.mp3',
      license: json['lic'] ?? '',
      quality: json['q'] ?? 'E',
      length: json['length'] ?? '',
      types: (json['type'] is List)
          ? (json['type'] as List).map((e) => e.toString()).toList()
          : (json['type']?.toString().split(',') ?? []),
      downloadCount: json['download-count'],
    );
  }

  bool get isGoodQuality => quality == 'A' || quality == 'B';

  String get fullFileUrl {
    if (fileUrl.startsWith('//')) return 'https:$fileUrl';
    if (fileUrl.startsWith('http')) return fileUrl;
    return 'https://xeno-canto.org$fileUrl';
  }
}

/// Сервис для работы с API Xeno-canto v3
class XenoCantoService {
  static const String _baseUrl = 'https://xeno-canto.org/api/3/recordings';
  static const String _apiKeyPref = 'xeno_canto_api_key';
  
  String? _apiKey;

  /// Получить API ключ
  Future<String?> getApiKey() async {
    if (_apiKey != null) return _apiKey;
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref);
    return _apiKey;
  }

  /// Сохранить API ключ
  Future<void> setApiKey(String key) async {
    _apiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  /// Удалить API ключ
  Future<void> clearApiKey() async {
    _apiKey = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
  }

  /// Проверить, есть ли API ключ
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Формирует запрос с тегами из латинского названия
  /// "Upupa epops" → "gen:Upupa sp:epops"
  /// "Upupa" → "gen:Upupa"
  String _buildTagQuery(String latinName) {
    final parts = latinName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    
    if (parts.length == 1) {
      return 'gen:${parts[0]}';
    } else {
      return 'gen:${parts[0]} sp:${parts[1]}';
    }
  }

  /// Поиск записей по запросу (теги API v3)
  Future<List<XcRecording>> searchRecordings(
    String query, {
    int page = 1,
    int maxResults = 100,
  }) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('XenoCanto: API key not set');
        return [];
      }

      // Формируем запрос с тегами
      String tagQuery;
      final trimmed = query.trim();
      
      // Если запрос уже содержит теги (gen:, sp:, en:) — используем как есть
      if (trimmed.contains(':')) {
        tagQuery = trimmed;
      } else {
        // Иначе преобразуем в теги
        tagQuery = _buildTagQuery(trimmed);
      }

      if (tagQuery.isEmpty) {
        debugPrint('XenoCanto: Empty query');
        return [];
      }

      final url = Uri.parse(
        '$_baseUrl?query=${Uri.encodeComponent(tagQuery)}'
        '&key=$apiKey'
        '&page=$page'
        '&per_page=$maxResults'
      );

      debugPrint('XenoCanto: GET $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'BirdQuiz/1.0 (Flutter)',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('XenoCanto: HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Проверка на ошибки API
        if (data.containsKey('error')) {
          debugPrint('XenoCanto API error: ${data['error']} - ${data['message']}');
          return [];
        }
        
        final List<dynamic> recordings = data['recordings'] ?? [];
        debugPrint('XenoCanto: Found ${recordings.length} recordings');

        return recordings
            .map((r) => XcRecording.fromJson(r))
            .where((r) => r.fileUrl.isNotEmpty)
            .toList();
      } else {
        debugPrint('XenoCanto: HTTP ${response.statusCode}');
        debugPrint('XenoCanto: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('XenoCanto search error: $e');
      return [];
    }
  }

  /// Поиск по английскому названию
  Future<List<XcRecording>> searchByEnglishName(String englishName) async {
    return await searchRecordings('en:$englishName');
  }

  /// Поиск по русскому названию (через конвертацию в латинское через BirdCatalog)
  Future<List<XcRecording>> searchByRussianName(String russianName) async {
    // Используем каталог для конвертации
    final latin = BirdCatalog.getLatinName(russianName);
    if (latin == null || latin.isEmpty) {
      // Если не нашли в каталоге, пробуем искать как есть
      return await searchRecordings(russianName);
    }
    return await searchRecordings(latin);
  }

  /// Умный поиск — определяет язык запроса
  Future<List<XcRecording>> searchSmart(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Если уже содержит теги — используем как есть
    if (trimmed.contains(':')) {
      return await searchRecordings(trimmed);
    }

    // Проверяем, есть ли в каталоге русское название
    final latin = BirdCatalog.getLatinName(trimmed);
    if (latin != null && latin.isNotEmpty) {
      return await searchRecordings(latin);
    }

    // Проверяем нечёткий поиск (частичное совпадение)
    final results = BirdCatalog.search(trimmed);
    if (results.isNotEmpty) {
      // Если нашли точное совпадение — используем его
      final exactMatch = results.firstWhere(
        (e) => e.key.toLowerCase() == trimmed.toLowerCase() ||
               e.value.toLowerCase() == trimmed.toLowerCase(),
        orElse: () => MapEntry('', ''),
      );
      if (exactMatch.key.isNotEmpty) {
        return await searchRecordings(exactMatch.value);
      }
    }

    // Иначе отправляем как есть (возможно, это уже латинское)
    return await searchRecordings(trimmed);
  }

  /// Получить русское название по латинскому (из каталога)
  static String? getRussianName(String latinName) {
    final results = BirdCatalog.search(latinName);
    for (final entry in results) {
      if (entry.value.toLowerCase() == latinName.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }

  /// Получить латинское название по русскому (из каталога)
  static String? getLatinName(String russianName) {
    return BirdCatalog.getLatinName(russianName);
  }

  /// Скачивание файла
  Future<File?> downloadRecording(
    XcRecording recording,
    String savePath, {
    void Function(int, int)? onProgress,
  }) async {
    try {
      final url = recording.fullFileUrl;
      debugPrint('XenoCanto: Downloading from $url');
      
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = 'BirdQuiz/1.0 (Flutter)';
      
      final client = http.Client();
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        debugPrint('Download failed: HTTP ${streamedResponse.statusCode}');
        client.close();
        return null;
      }

      final totalBytes = streamedResponse.contentLength ?? -1;
      final file = File(savePath);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();

      int downloaded = 0;
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        onProgress?.call(downloaded, totalBytes);
      }

      await sink.close();
      client.close();
      debugPrint('XenoCanto: Downloaded to $savePath');
      return file;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }
}