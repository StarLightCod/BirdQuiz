import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/xeno_canto_service.dart';
import '../services/bird_photo_service.dart';
import '../data/bird_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';
import 'bird_catalog_screen.dart';

class XenoCantoScreen extends StatefulWidget {
  const XenoCantoScreen({super.key});

  @override
  State<XenoCantoScreen> createState() => _XenoCantoScreenState();
}

class _XenoCantoScreenState extends State<XenoCantoScreen> {
  final _xcService = XenoCantoService();
  final _photoService = BirdPhotoService();
  final _audioPlayer = AudioPlayer();
  final _controller = TextEditingController();

  List<XcRecording> _results = [];
  bool _isSearching = false;
  bool _isDownloadingAll = false;
  String? _error;
  final Set<String> _downloadingAudioIds = {};
  final Set<String> _downloadingPhotoIds = {};
  final Set<String> _downloadingBothIds = {};
  final Set<String> _previewingIds = {};
  Directory? _audioDir;
  Directory? _photoDir;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _initDirs();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _previewingIds.clear());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initDirs() async {
    final appDir = await getApplicationDocumentsDirectory();
    _audioDir = Directory('${appDir.path}/birdiq_audio');
    _photoDir = Directory('${appDir.path}/birdiq_photos');
    if (!await _audioDir!.exists()) {
      await _audioDir!.create(recursive: true);
    }
    if (!await _photoDir!.exists()) {
      await _photoDir!.create(recursive: true);
    }
  }

  Future<void> _checkApiKey() async {
    final hasKey = await _xcService.hasApiKey();
    if (!hasKey && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApiKeyDialog();
      });
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    final results = await _xcService.searchRecordings(query);

    setState(() {
      _isSearching = false;
      _results = results;
      if (results.isEmpty) {
        _error = 'Записи не найдены для "$query"';
      }
    });
  }

  /// Предпрослушивание аудио
  Future<void> _previewAudio(XcRecording rec) async {
    if (_previewingIds.contains(rec.id)) {
      await _audioPlayer.pause();
      setState(() => _previewingIds.remove(rec.id));
      return;
    }

    try {
      setState(() {
        _previewingIds.add(rec.id);
      });

      await _audioPlayer.play(UrlSource(rec.fullFileUrl));
    } catch (e) {
      setState(() => _previewingIds.remove(rec.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка воспроизведения: $e')),
        );
      }
    }
  }

  /// Скачать и показать фото с зумом
  Future<void> _previewPhoto(XcRecording rec) async {
    try {
      final latinName = rec.fullName;
      final russianName = BirdCatalog.russianToLatin.entries
          .where((e) => e.value.toLowerCase() == latinName.toLowerCase())
          .map((e) => e.key)
          .firstWhere((_) => true, orElse: () => '');

      final birdName = russianName.isNotEmpty ? russianName : latinName;

      // Ищем фото через iNaturalist
      final photoUrls = await _photoService.searchPhotoUrls(latinName);
      
      if (photoUrls.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Фото не найдено'),
              backgroundColor: AppTheme.coral,
            ),
          );
        }
        return;
      }

      // Показываем диалог с фото и зумом
      if (mounted) {
        _showPhotoPreviewDialog(photoUrls, birdName, rec.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _showPhotoPreviewDialog(List<String> photoUrls, String birdName, String recordingId) {
    int currentIndex = 0;
    double currentScale = 1.0;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 800),
            decoration: BoxDecoration(
              color: AppTheme.bg1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          birdName,
                          style: AppText.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${currentIndex + 1}/${photoUrls.length}',
                        style: AppText.small,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(color: AppTheme.cardBorder),
                
                // Фото с зумом
                Expanded(
                  child: GestureDetector(
                    onDoubleTap: () {
                      setDialogState(() {
                        currentScale = currentScale == 1.0 ? 2.0 : 1.0;
                      });
                    },
                    child: Container(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          photoUrls[currentIndex],
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (ctx, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.broken_image, size: 64),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Кнопки управления
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Кнопки навигации
                      if (photoUrls.length > 1)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: currentIndex > 0
                                    ? () {
                                        setDialogState(() {
                                          currentIndex--;
                                          currentScale = 1.0;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Назад'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: currentIndex < photoUrls.length - 1
                                    ? () {
                                        setDialogState(() {
                                          currentIndex++;
                                          currentScale = 1.0;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Вперёд'),
                              ),
                            ),
                          ],
                        ),
                      if (photoUrls.length > 1) const SizedBox(height: 8),
                      // Кнопки зума и скачивания
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  currentScale = 1.0;
                                });
                              },
                              icon: const Icon(Icons.zoom_out_map),
                              label: const Text('Сбросить зум'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _downloadPhotoById(recordingId);
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Скачать'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Скачать аудио
  Future<void> _downloadAudio(XcRecording rec) async {
    if (_audioDir == null) await _initDirs();
    setState(() => _downloadingAudioIds.add(rec.id));

    try {
      final fileName = '${rec.genus}_${rec.species}_XC${rec.id}.mp3';
      final savePath = '${_audioDir!.path}/$fileName';
      final file = await _xcService.downloadRecording(rec, savePath);

      if (mounted) {
        setState(() => _downloadingAudioIds.remove(rec.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(file != null
                ? '🎵 Скачано: $fileName'
                : '❌ Ошибка скачивания'),
            backgroundColor: file != null ? AppTheme.accent : AppTheme.coral,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadingAudioIds.remove(rec.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  /// Скачать фото по ID записи
  Future<void> _downloadPhotoById(String recordingId) async {
    final rec = _results.firstWhere((r) => r.id == recordingId, orElse: () => _results.first);
    await _downloadPhoto(rec);
  }

  /// Скачать фото
  Future<void> _downloadPhoto(XcRecording rec) async {
    setState(() => _downloadingPhotoIds.add(rec.id));

    try {
      final latinName = rec.fullName;
      final russianName = BirdCatalog.russianToLatin.entries
          .where((e) => e.value.toLowerCase() == latinName.toLowerCase())
          .map((e) => e.key)
          .firstWhere((_) => true, orElse: () => '');

      final birdName = russianName.isNotEmpty ? russianName : latinName;

      final photoPath = await _photoService.downloadPhoto(latinName, birdName);

      if (mounted) {
        setState(() => _downloadingPhotoIds.remove(rec.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(photoPath != null
                ? '📷 Фото скачано: $birdName'
                : '❌ Фото не найдено для $birdName'),
            backgroundColor: photoPath != null ? AppTheme.accent : AppTheme.coral,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadingPhotoIds.remove(rec.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  /// Скачать аудио + фото вместе
  Future<void> _downloadBoth(XcRecording rec) async {
    setState(() => _downloadingBothIds.add(rec.id));

    try {
      final latinName = rec.fullName;
      final russianName = BirdCatalog.russianToLatin.entries
          .where((e) => e.value.toLowerCase() == latinName.toLowerCase())
          .map((e) => e.key)
          .firstWhere((_) => true, orElse: () => '');

      final birdName = russianName.isNotEmpty ? russianName : latinName;

      // Скачиваем аудио
      if (_audioDir == null) await _initDirs();
      final fileName = '${rec.genus}_${rec.species}_XC${rec.id}.mp3';
      final audioPath = '${_audioDir!.path}/$fileName';
      final audioFile = await _xcService.downloadRecording(rec, audioPath);

      // Скачиваем фото
      final photoPath = await _photoService.downloadPhoto(latinName, birdName);

      if (mounted) {
        setState(() => _downloadingBothIds.remove(rec.id));
        
        String message = '';
        bool success = false;
        
        if (audioFile != null && photoPath != null) {
          message = '✅ Скачано: аудио + фото ($birdName)';
          success = true;
        } else if (audioFile != null) {
          message = '✅ Скачано аудио ($birdName)';
          success = true;
        } else if (photoPath != null) {
          message = '✅ Скачано фото ($birdName)';
          success = true;
        } else {
          message = '❌ Ошибка скачивания';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? AppTheme.accent : AppTheme.coral,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadingBothIds.remove(rec.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  /// Скачать всё (аудио + фото) для первых N записей
  Future<void> _downloadAll() async {
    if (_results.isEmpty) return;
    setState(() => _isDownloadingAll = true);

    int audioOk = 0;
    int photoOk = 0;
    final limit = _results.length > 10 ? 10 : _results.length;

    for (int i = 0; i < limit; i++) {
      final rec = _results[i];
      final latinName = rec.fullName;

      // Скачиваем аудио
      try {
        if (_audioDir == null) await _initDirs();
        final fileName = '${rec.genus}_${rec.species}_XC${rec.id}.mp3';
        final savePath = '${_audioDir!.path}/$fileName';
        if (!await File(savePath).exists()) {
          final file = await _xcService.downloadRecording(rec, savePath);
          if (file != null) audioOk++;
        } else {
          audioOk++;
        }
      } catch (e) {
        debugPrint('Audio download error: $e');
      }

      // Скачиваем фото (только для первой записи каждого вида)
      if (i == 0) {
        try {
          final russianName = BirdCatalog.russianToLatin.entries
              .where((e) => e.value.toLowerCase() == latinName.toLowerCase())
              .map((e) => e.key)
              .firstWhere((_) => true, orElse: () => '');
          final birdName = russianName.isNotEmpty ? russianName : latinName;
          final photo = await _photoService.downloadPhoto(latinName, birdName);
          if (photo != null) photoOk++;
        } catch (e) {
          debugPrint('Photo download error: $e');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (mounted) {
      setState(() => _isDownloadingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Аудио: $audioOk, Фото: $photoOk (из $limit)'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bg1,
        title: const Text('API ключ Xeno-canto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Для работы поиска нужен API ключ с xeno-canto.org',
                  style: AppText.body),
              const SizedBox(height: 12),
              Text('Как получить:', style: AppText.h3),
              const SizedBox(height: 8),
              Text(
                '1. Зарегистрируйтесь на xeno-canto.org\n'
                '2. Подтвердите email\n'
                '3. Перейдите в профиль → API Key\n'
                '4. Скопируйте ключ',
                style: AppText.small,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Вставьте API ключ...',
                  prefixIcon: Icon(Icons.key),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await _xcService.setApiKey(key);
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('API ключ сохранён'),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 1000.0 : double.infinity;

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Xeno-canto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Каталог птиц (${BirdCatalog.totalSpecies} видов)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BirdCatalogScreen(
                    onBirdSelected: (latinName) {
                      setState(() {
                        _controller.text = latinName;
                      });
                      _search();
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'API ключ',
            onPressed: _showApiKeyDialog,
          ),
         
          if (_results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillLabel(
                text: '🎵 ${_results.length}',
                color: AppTheme.sky,
              ),
            ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassCard(
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.sky, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Поиск голосов и фото птиц. '
                                '▶️ — прослушать, 📷 — просмотреть фото (двойной клик для зума). '
                                'Выберите из каталога (📖) или введите латинское название.',
                                style: AppText.small,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Например: Upupa epops',
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                         suffixIcon: IconButton(
                          icon: const Icon(Icons.menu_book),
                          tooltip: 'Выбрать из каталога',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BirdCatalogScreen(
                                  onBirdSelected: (latinName) {
                                    setState(() {
                                      _controller.text = latinName;
                                    });
                                    _search();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                                              
                          filled: true,
                          fillColor: AppTheme.bg2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSearching || _controller.text.trim().isEmpty
                                  ? null
                                  : _search,
                              icon: const Icon(Icons.search),
                              label: Text(_isSearching ? 'Поиск...' : 'Найти записи'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_results.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _isDownloadingAll ? null : _downloadAll,
                              icon: _isDownloadingAll
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(_isDownloadingAll ? '...' : 'Всё'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.sky,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildResults()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: AppTheme.sky));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(_error!, style: AppText.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('Выберите птицу из каталога или введите латинское название',
                style: AppText.body, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final rec = _results[i];
        return _RecordingTile(
          recording: rec,
          isPreviewing: _previewingIds.contains(rec.id),
          isDownloadingAudio: _downloadingAudioIds.contains(rec.id),
          isDownloadingPhoto: _downloadingPhotoIds.contains(rec.id),
          isDownloadingBoth: _downloadingBothIds.contains(rec.id),
          onPreviewAudio: () => _previewAudio(rec),
          onPreviewPhoto: () => _previewPhoto(rec),
          onDownloadAudio: () => _downloadAudio(rec),
          onDownloadPhoto: () => _downloadPhoto(rec),
          onDownloadBoth: () => _downloadBoth(rec),
        );
      },
    );
  }
}

/// Карточка записи с предпросмотром
class _RecordingTile extends StatelessWidget {
  final XcRecording recording;
  final bool isPreviewing;
  final bool isDownloadingAudio;
  final bool isDownloadingPhoto;
  final bool isDownloadingBoth;
  final VoidCallback onPreviewAudio;
  final VoidCallback onPreviewPhoto;
  final VoidCallback onDownloadAudio;
  final VoidCallback onDownloadPhoto;
  final VoidCallback onDownloadBoth;

  const _RecordingTile({
    required this.recording,
    required this.isPreviewing,
    required this.isDownloadingAudio,
    required this.isDownloadingPhoto,
    required this.isDownloadingBoth,
    required this.onPreviewAudio,
    required this.onPreviewPhoto,
    required this.onDownloadAudio,
    required this.onDownloadPhoto,
    required this.onDownloadBoth,
  });

  Color get _qualityColor {
    switch (recording.quality) {
      case 'A': return AppTheme.accent;
      case 'B': return const Color(0xFF8FD4A8);
      case 'C': return AppTheme.amber;
      case 'D': return AppTheme.coral;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final russianName = BirdCatalog.russianToLatin.entries
        .where((e) => e.value.toLowerCase() == '${recording.genus} ${recording.species}'.toLowerCase())
        .map((e) => e.key)
        .firstWhere((_) => true, orElse: () => '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording.fullName,
                        style: AppText.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (russianName.isNotEmpty)
                        Text(
                          russianName,
                          style: AppText.small.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (recording.englishName.isNotEmpty)
                        Text(
                          recording.englishName,
                          style: AppText.small.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _qualityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _qualityColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Q: ${recording.quality}',
                    style: TextStyle(
                      color: _qualityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Детали
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (recording.recordist.isNotEmpty)
                  _DetailChip(icon: Icons.person, text: recording.recordist),
                if (recording.location.isNotEmpty)
                  _DetailChip(icon: Icons.location_on, text: recording.location),
                if (recording.length.isNotEmpty)
                  _DetailChip(icon: Icons.timer, text: '${recording.length} сек'),
                if (recording.types.isNotEmpty)
                  _DetailChip(
                    icon: Icons.graphic_eq,
                    text: recording.types.take(2).join(', '),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Кнопки предпросмотра
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPreviewAudio,
                    icon: Icon(isPreviewing ? Icons.pause : Icons.play_arrow, size: 16),
                    label: Text(isPreviewing ? 'Стоп' : '▶️ Прослушать'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: BorderSide(color: AppTheme.accent.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPreviewPhoto,
                    icon: const Icon(Icons.photo_library, size: 16),
                    label: const Text('📷 Фото'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sky,
                      side: BorderSide(color: AppTheme.sky.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Кнопки скачивания
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDownloadingAudio || isDownloadingBoth ? null : onDownloadAudio,
                    icon: isDownloadingAudio
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.audiotrack, size: 16),
                    label: Text(isDownloadingAudio ? '...' : 'Аудио'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isDownloadingPhoto || isDownloadingBoth ? null : onDownloadPhoto,
                    icon: isDownloadingPhoto
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library, size: 16),
                    label: Text(isDownloadingPhoto ? '...' : 'Фото'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.sky,
                      side: BorderSide(color: AppTheme.sky.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDownloadingBoth ? null : onDownloadBoth,
                    icon: isDownloadingBoth
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, size: 16),
                    label: Text(isDownloadingBoth ? '...' : 'Всё'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sky,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppText.small.copyWith(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}