import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Модель цветового пресета
class ColorPreset {
  final String id;
  final String name;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color bg0;
  final Color bg1;
  final Color bg2;

  const ColorPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.bg0,
    required this.bg1,
    required this.bg2,
  });

  static const List<ColorPreset> presets = [
    ColorPreset(
      id: 'forest',
      name: 'Лес',
      emoji: '🌲',
      primary: Color(0xFF6EBF8B),
      secondary: Color(0xFF3D7A55),
      accent: Color(0xFFE8A838),
      bg0: Color(0xFF0E1511),
      bg1: Color(0xFF141C18),
      bg2: Color(0xFF1C2820),
    ),
    ColorPreset(
      id: 'ocean',
      name: 'Океан',
      emoji: '🌊',
      primary: Color(0xFF5BA8D4),
      secondary: Color(0xFF2A5580),
      accent: Color(0xFFE86038),
      bg0: Color(0xFF0A1520),
      bg1: Color(0xFF101E2E),
      bg2: Color(0xFF182A3E),
    ),
    ColorPreset(
      id: 'sunset',
      name: 'Закат',
      emoji: '🌅',
      primary: Color(0xFFE86038),
      secondary: Color(0xFFB04020),
      accent: Color(0xFFE8A838),
      bg0: Color(0xFF1A1008),
      bg1: Color(0xFF241810),
      bg2: Color(0xFF302018),
    ),
    ColorPreset(
      id: 'lavender',
      name: 'Лаванда',
      emoji: '💜',
      primary: Color(0xFFB06CF0),
      secondary: Color(0xFF7A3DB0),
      accent: Color(0xFF6EBF8B),
      bg0: Color(0xFF120E1A),
      bg1: Color(0xFF1A1424),
      bg2: Color(0xFF241C30),
    ),
    ColorPreset(
      id: 'rose',
      name: 'Роза',
      emoji: '🌹',
      primary: Color(0xFFE87BA8),
      secondary: Color(0xFFB04878),
      accent: Color(0xFFE8A838),
      bg0: Color(0xFF1A0E14),
      bg1: Color(0xFF24141C),
      bg2: Color(0xFF301C28),
    ),
    ColorPreset(
      id: 'midnight',
      name: 'Полночь',
      emoji: '🌙',
      primary: Color(0xFF8A9BFF),
      secondary: Color(0xFF5060C0),
      accent: Color(0xFF6EBF8B),
      bg0: Color(0xFF0A0E1A),
      bg1: Color(0xFF101624),
      bg2: Color(0xFF182030),
    ),
    ColorPreset(
      id: 'mono',
      name: 'Монохром',
      emoji: '',
      primary: Color(0xFFDCEAE0),
      secondary: Color(0xFF8FAF97),
      accent: Color(0xFFFFFFFF),
      bg0: Color(0xFF0E0E0E),
      bg1: Color(0xFF161616),
      bg2: Color(0xFF202020),
    ),
  ];

  static ColorPreset? findById(String id) {
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return presets.first;
    }
  }
}

/// Режим темы приложения
enum AppThemeMode { dark, light, system }

/// Сервис управления темой приложения
class ThemeService extends ChangeNotifier {
  // Ключи для SharedPreferences
  static const String _keyMode = 'theme_mode';
  static const String _keyPreset = 'theme_preset';
  static const String _keyCustomPrimary = 'custom_primary';
  static const String _keyCustomSecondary = 'custom_secondary';
  static const String _keyCustomAccent = 'custom_accent';
  static const String _keyCustomBg0 = 'custom_bg0';
  static const String _keyCustomBg1 = 'custom_bg1';
  static const String _keyCustomBg2 = 'custom_bg2';
  static const String _keyUseCustom = 'use_custom_colors';
  static const String _keyFontScale = 'font_scale';

  // Внутренние переменные
  AppThemeMode _mode = AppThemeMode.dark;
  String _presetId = 'forest';
  bool _useCustom = false;
  Color _customPrimary = const Color(0xFF6EBF8B);
  Color _customSecondary = const Color(0xFF3D7A55);
  Color _customAccent = const Color(0xFFE8A838);
  Color _customBg0 = const Color(0xFF0E1511);
  Color _customBg1 = const Color(0xFF141C18);
  Color _customBg2 = const Color(0xFF1C2820);
  double _fontScale = 1.0;

  // Геттеры
  AppThemeMode get mode => _mode;
  String get presetId => _presetId;
  ColorPreset get currentPreset => 
      ColorPreset.findById(_presetId) ?? ColorPreset.presets.first;
  bool get useCustom => _useCustom;
  Color get customPrimary => _customPrimary;
  Color get customSecondary => _customSecondary;
  Color get customAccent => _customAccent;
  Color get customBg0 => _customBg0;
  Color get customBg1 => _customBg1;
  Color get customBg2 => _customBg2;
  double get fontScale => _fontScale;

  // Вычисляемые цвета (используются в приложении)
  Color get primaryColor => _useCustom ? _customPrimary : currentPreset.primary;
  Color get secondaryColor => _useCustom ? _customSecondary : currentPreset.secondary;
  Color get accentColor => _useCustom ? _customAccent : currentPreset.accent;
  Color get bgColor0 => _useCustom ? _customBg0 : currentPreset.bg0;
  Color get bgColor1 => _useCustom ? _customBg1 : currentPreset.bg1;
  Color get bgColor2 => _useCustom ? _customBg2 : currentPreset.bg2;

  /// Получение режима темы для MaterialApp
  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Загрузка настроек из SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    _mode = AppThemeMode.values[prefs.getInt(_keyMode) ?? 0];
    _presetId = prefs.getString(_keyPreset) ?? 'forest';
    _useCustom = prefs.getBool(_keyUseCustom) ?? false;
    _fontScale = prefs.getDouble(_keyFontScale) ?? 1.0;

    final cp = prefs.getInt(_keyCustomPrimary);
    final cs = prefs.getInt(_keyCustomSecondary);
    final ca = prefs.getInt(_keyCustomAccent);
    final cb0 = prefs.getInt(_keyCustomBg0);
    final cb1 = prefs.getInt(_keyCustomBg1);
    final cb2 = prefs.getInt(_keyCustomBg2);
    
    if (cp != null) _customPrimary = Color(cp);
    if (cs != null) _customSecondary = Color(cs);
    if (ca != null) _customAccent = Color(ca);
    if (cb0 != null) _customBg0 = Color(cb0);
    if (cb1 != null) _customBg1 = Color(cb1);
    if (cb2 != null) _customBg2 = Color(cb2);

    notifyListeners();
  }

  /// Установка режима темы
  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, mode.index);
    notifyListeners();
  }

  /// Установка пресета
  Future<void> setPreset(String presetId) async {
    _presetId = presetId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreset, presetId);
    notifyListeners();
  }

  /// Включение/выключение кастомных цветов
  Future<void> setUseCustom(bool value) async {
    _useCustom = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCustom, value);
    notifyListeners();
  }

  /// Установка кастомных цветов
  Future<void> setCustomColors({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? bg0,
    Color? bg1,
    Color? bg2,
  }) async {
    if (primary != null) _customPrimary = primary;
    if (secondary != null) _customSecondary = secondary;
    if (accent != null) _customAccent = accent;
    if (bg0 != null) _customBg0 = bg0;
    if (bg1 != null) _customBg1 = bg1;
    if (bg2 != null) _customBg2 = bg2;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCustomPrimary, _customPrimary.value);
    await prefs.setInt(_keyCustomSecondary, _customSecondary.value);
    await prefs.setInt(_keyCustomAccent, _customAccent.value);
    await prefs.setInt(_keyCustomBg0, _customBg0.value);
    await prefs.setInt(_keyCustomBg1, _customBg1.value);
    await prefs.setInt(_keyCustomBg2, _customBg2.value);
    notifyListeners();
  }

  /// Установка основного цвета с авто-генерацией фона
  Future<void> setPrimaryAndAutoBg(Color primary) async {
    _customPrimary = primary;
    
    // Генерируем тёмные оттенки фона из основного цвета
    _customBg0 = _darkenColor(primary, 0.85);
    _customBg1 = _darkenColor(primary, 0.75);
    _customBg2 = _darkenColor(primary, 0.65);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCustomPrimary, _customPrimary.value);
    await prefs.setInt(_keyCustomBg0, _customBg0.value);
    await prefs.setInt(_keyCustomBg1, _customBg1.value);
    await prefs.setInt(_keyCustomBg2, _customBg2.value);
    notifyListeners();
  }

  /// Затемнение цвета
  Color _darkenColor(Color color, double factor) {
    final r = (color.red * factor).round().clamp(0, 255);
    final g = (color.green * factor).round().clamp(0, 255);
    final b = (color.blue * factor).round().clamp(0, 255);
    return Color.fromARGB(color.alpha, r, g, b);
  }

  /// Установка масштаба шрифта
  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.8, 1.4);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, _fontScale);
    notifyListeners();
  }

  /// Сброс всех настроек к значениям по умолчанию
  Future<void> resetToDefaults() async {
    _mode = AppThemeMode.dark;
    _presetId = 'forest';
    _useCustom = false;
    _fontScale = 1.0;
    _customPrimary = const Color(0xFF6EBF8B);
    _customSecondary = const Color(0xFF3D7A55);
    _customAccent = const Color(0xFFE8A838);
    _customBg0 = const Color(0xFF0E1511);
    _customBg1 = const Color(0xFF141C18);
    _customBg2 = const Color(0xFF1C2820);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}