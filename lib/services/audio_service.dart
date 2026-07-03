// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentAsset;

  bool get isPlaying => _isPlaying;
  String? get currentAsset => _currentAsset;

  ValueChanged<bool>? onPlayingChanged;

  Future<void> init() async {
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _currentAsset = null;
      onPlayingChanged?.call(false);
    });

    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        onPlayingChanged?.call(playing);
      }
    });
  }

  Future<void> play(String assetPath) async {
    await stop();
    try {
      _currentAsset = assetPath;
      
      if (assetPath.startsWith('assets/')) {
        final asset = assetPath.replaceFirst('assets/', '');
        await _player.play(AssetSource(asset));
      } else {
        await _player.play(DeviceFileSource(assetPath));
      }
      
      _isPlaying = true;
      onPlayingChanged?.call(true);
    } catch (e) {
      debugPrint('AudioService error: $e');
      _isPlaying = false;
      _currentAsset = null;
      onPlayingChanged?.call(false);
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Stop error: $e');
    }
    _isPlaying = false;
    _currentAsset = null;
    onPlayingChanged?.call(false);
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
      onPlayingChanged?.call(false);
    } catch (e) {
      debugPrint('Pause error: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.resume();
      _isPlaying = true;
      onPlayingChanged?.call(true);
    } catch (e) {
      debugPrint('Resume error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Volume error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}