import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/app_state.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final appState = AppState();
  final themeService = ThemeService();

  await Future.wait([
    appState.load(),
    themeService.load(),
  ]);

  // Применяем цвета темы при старте
  AppTheme.updateFromService(themeService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ],
      child: const BirdQuizApp(),
    ),
  );
}

class BirdQuizApp extends StatelessWidget {
  const BirdQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    
    // Обновляем цвета при каждом изменении темы
    AppTheme.updateFromService(themeService);

    return MaterialApp(
      title: 'Птицы — викторина',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainMenuScreen(),
    );
  }
}