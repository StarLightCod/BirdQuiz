import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import '../models/app_state.dart';
import '../services/media_import_service.dart';
import '../services/bird_card_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';

class ImportMediaScreen extends StatefulWidget {
  const ImportMediaScreen({super.key});

  @override
  State<ImportMediaScreen> createState() => _ImportMediaScreenState();
}

class _ImportMediaScreenState extends State<ImportMediaScreen> {
  final _birdNameController = TextEditingController();
  final _cardService = BirdCardService();
  final _audioPlayer = AudioPlayer();

  String? _pendingPhotoPath;
  String? _pendingAudioPath;
  bool _isCreating = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _birdNameController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      setState(() => _pendingPhotoPath = result.files.first.path);
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      setState(() => _pendingAudioPath = result.files.first.path);
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _togglePreview() async {
    if (_pendingAudioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_pendingAudioPath!));
      setState(() => _isPlaying = true);
    }
  }

  void _clearPhoto() {
    setState(() => _pendingPhotoPath = null);
  }

  Future<void> _clearAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _pendingAudioPath = null;
      _isPlaying = false;
    });
  }

  Future<void> _createCard() async {
    final birdName = _birdNameController.text.trim();
    if (birdName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Введите название птицы'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    if (_pendingPhotoPath == null || _pendingAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нужны И фото, И аудио!'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final safeName = MediaImportService.sanitizeFilename(birdName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final photoExt = p.extension(_pendingPhotoPath!);
      final photoDir = await MediaImportService.getUserImagesDir();
      final photoSavePath = '${photoDir.path}/${safeName}_$timestamp$photoExt';
      await File(_pendingPhotoPath!).copy(photoSavePath);

      final audioExt = p.extension(_pendingAudioPath!);
      final audioDir = await MediaImportService.getUserAudioDir();
      final audioSavePath = '${audioDir.path}/${safeName}_$timestamp$audioExt';
      await File(_pendingAudioPath!).copy(audioSavePath);

      final existingCard = await _cardService.findCardByName(birdName);
      
      if (existingCard != null) {
        await _cardService.updateCardMedia(
          name: birdName,
          photoPath: photoSavePath,
          audioPath: audioSavePath,
        );
      } else {
        await _cardService.addCard(
          name: birdName,
          photoPath: photoSavePath,
          audioPath: audioSavePath,
        );
      }

      await _audioPlayer.stop();

      setState(() {
        _isCreating = false;
        _pendingPhotoPath = null;
        _pendingAudioPath = null;
        _isPlaying = false;
        _birdNameController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Карточка "$birdName" создана!'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  bool get _canCreate =>
      _birdNameController.text.trim().isNotEmpty &&
      _pendingPhotoPath != null &&
      _pendingAudioPath != null;

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 900.0 : double.infinity;

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Конструктор карточек'),
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.sky, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Загрузите фото и аудио отдельно. '
                          'Карточка создастся только когда оба файла будут выбраны.',
                          style: AppText.small,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text('1. Название птицы:', style: AppText.h3),
                const SizedBox(height: 8),
                TextField(
                  controller: _birdNameController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Например: Синица, Воробей, Дрозд...',
                    prefixIcon: Icon(Icons.edit, color: AppTheme.textMuted),
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
                ),
                const SizedBox(height: 24),

                Text('2. Фото птицы:', style: AppText.h3),
                const SizedBox(height: 8),
                _buildPhotoBlock(),
                const SizedBox(height: 24),

                Text('3. Голос птицы:', style: AppText.h3),
                const SizedBox(height: 8),
                _buildAudioBlock(),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _canCreate && !_isCreating ? _createCard : null,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_isCreating ? 'Создание...' : 'Создать карточку'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                if (!_canCreate)
                  Text(
                    '⚠️ Заполните название и выберите оба файла',
                    style: AppText.small.copyWith(color: AppTheme.amber),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoBlock() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pendingPhotoPath == null) ...[
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Выбрать фото'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.sky,
                side: BorderSide(color: AppTheme.sky.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Поддерживаемые форматы: JPG, PNG, GIF, WEBP',
              style: AppText.small.copyWith(fontSize: 11),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.bg3,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_pendingPhotoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      p.basename(_pendingPhotoPath!),
                      style: AppText.small.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: _clearPhoto,
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.coral,
                      tooltip: 'Убрать',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Заменить'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.sky,
                side: BorderSide(color: AppTheme.sky.withOpacity(0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioBlock() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_pendingAudioPath == null) ...[
            OutlinedButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.audiotrack),
              label: const Text('Выбрать аудио'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Поддерживаемые форматы: MP3, WAV, OGG, M4A, AAC, FLAC',
              style: AppText.small.copyWith(fontSize: 11),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.audiotrack,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.basename(_pendingAudioPath!),
                        style: AppText.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getFileExtension(_pendingAudioPath!).toUpperCase(),
                        style: AppText.small.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _togglePreview,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  color: _isPlaying ? AppTheme.coral : AppTheme.accent,
                  iconSize: 32,
                  tooltip: _isPlaying ? 'Пауза' : 'Прослушать',
                ),
                IconButton(
                  onPressed: _clearAudio,
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.coral,
                  tooltip: 'Убрать',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isPlaying)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.graphic_eq, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Воспроизведение...',
                        style: AppText.small.copyWith(color: AppTheme.accent),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Заменить'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: BorderSide(color: AppTheme.accent.withOpacity(0.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFileExtension(String path) {
    return p.extension(path).replaceAll('.', '');
  }
}