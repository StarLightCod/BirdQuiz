import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'xeno_canto_service.dart';

class DownloadManager {
  final XenoCantoService _xcService = XenoCantoService();
  Directory? _audioDir;

  Future<Directory> getAudioDir() async {
    if (_audioDir != null) return _audioDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _audioDir = Directory('${appDir.path}/birdiq_xc_audio');
    if (!await _audioDir!.exists()) {
      await _audioDir!.create(recursive: true);
    }
    return _audioDir!;
  }

  Future<String> _getSavePath(XcRecording rec, {String? birdName}) async {
    final dir = await getAudioDir();
    final safeName = (birdName ?? '${rec.genus}_${rec.species}')
        .replaceAll(RegExp(r'[^\wа-яА-ЯёЁ\s]'), '')
        .replaceAll(' ', '_');
    return '${dir.path}/${safeName}_XC${rec.id}.mp3';
  }

  /// Скачать конкретную запись
  Future<DownloadResult> downloadRecording(
    XcRecording recording, {
    String? birdName,
    void Function(int, int)? onProgress,
  }) async {
    final result = DownloadResult(birdName: birdName ?? recording.displayName);
    final savePath = await _getSavePath(recording, birdName: birdName);

    if (await File(savePath).exists()) {
      result.downloaded.add(savePath);
      result.recordings.add(recording);
      return result;
    }

    try {
      final file = await _xcService.downloadRecording(
        recording,
        savePath,
        onProgress: onProgress,
      );
      if (file != null && await file.exists()) {
        result.downloaded.add(savePath);
        result.recordings.add(recording);
      } else {
        result.failed.add(recording);
      }
    } catch (e) {
      debugPrint('Download failed: $e');
      result.failed.add(recording);
      result.error = e.toString();
    }
    return result;
  }

  /// Скачать топ-N лучших записей для птицы
  Future<DownloadResult> downloadForBird(
    String russianName, {
    int count = 3,
    void Function(int, int, String)? onProgress,
    bool onlyGoodQuality = true,
  }) async {
    final result = DownloadResult(birdName: russianName);

    onProgress?.call(0, count, 'Поиск записей...');
    final recordings = await _xcService.searchByRussianName(russianName);

    if (recordings.isEmpty) {
      result.error = 'Не найдено записей для "$russianName"';
      return result;
    }

    List<XcRecording> candidates = List.from(recordings);

    if (onlyGoodQuality) {
      final good = candidates.where((r) => r.isGoodQuality).toList();
      if (good.length >= count) candidates = good;
    }

    candidates.sort((a, b) {
      final qualityOrder = {'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4};
      final qa = qualityOrder[a.quality] ?? 5;
      final qb = qualityOrder[b.quality] ?? 5;
      if (qa != qb) return qa.compareTo(qb);
      return (b.downloadCount ?? 0).compareTo(a.downloadCount ?? 0);
    });

    candidates = candidates.take(count).toList();

    for (int i = 0; i < candidates.length; i++) {
      final rec = candidates[i];
      onProgress?.call(i, count, 'Скачивание ${i + 1}/${candidates.length}...');

      final subResult = await downloadRecording(rec, birdName: russianName);
      result.downloaded.addAll(subResult.downloaded);
      result.recordings.addAll(subResult.recordings);
      result.failed.addAll(subResult.failed);
    }

    onProgress?.call(count, count, 'Готово!');
    return result;
  }

  Future<List<String>> listDownloadedAudio() async {
    final dir = await getAudioDir();
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mp3'))
        .map((f) => f.path)
        .toList();
  }

  Future<void> clearAll() async {
    final dir = await getAudioDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

class DownloadResult {
  final String birdName;
  final List<String> downloaded = [];
  final List<XcRecording> recordings = [];
  final List<XcRecording> failed = [];
  String? error;

  DownloadResult({required this.birdName});

  bool get isSuccess => downloaded.isNotEmpty && error == null;
}