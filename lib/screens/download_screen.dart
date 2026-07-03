import 'package:flutter/material.dart';
import '../models/bird_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';
import '../services/download_manager.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _manager = DownloadManager();
  final _selected = <String>{};
  String _search = '';
  int _tracksPerBird = 3;

  bool _isDownloading = false;
  int _completed = 0;
  int _total = 0;
  String _status = '';
  final _log = <String>[];

  @override
  void initState() {
    super.initState();
    _selected.addAll(BirdData.allBirds);
  }

  List<String> get _filtered => _search.isEmpty
      ? BirdData.allBirds
      : BirdData.allBirds
          .where((b) => b.toLowerCase().contains(_search.toLowerCase()))
          .toList();

  Future<void> _startDownload() async {
    if (_selected.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _completed = 0;
      _total = _selected.length;
      _log.clear();
    });

    final birds = _selected.toList();
    await _manager.downloadForAllBirds(
      birds,
      tracksPerBird: _tracksPerBird,
      onOverallProgress: (done, total, status) {
        if (mounted) {
          setState(() {
            _completed = done;
            _status = status;
          });
        }
      },
      onBirdProgress: (bird, d, t, status) {
        if (mounted) {
          setState(() {
            _log.insert(0, '[$bird] $status');
            if (_log.length > 20) _log.removeLast();
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _status = 'Завершено! Скачано для ${birds.length} птиц';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Загрузка завершена!'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final horizontalPadding = Responsive.spacing(context, 16, 24, 48);
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 800.0 : double.infinity;

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: _isDownloading ? null : () => Navigator.pop(context),
        ),
        title: const Text('Скачать звуки'),
      ),
      child: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      GlassCard(
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppTheme.sky, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Звуки загружаются с xeno-canto.org (CC лицензии). '
                                'Файлы сохраняются локально и доступны офлайн.',
                                style: AppText.small,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Треков на птицу:', style: AppText.body),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _tracksPerBird,
                            items: [1, 2, 3, 5]
                                .map((n) => DropdownMenuItem(
                                      value: n,
                                      child: Text('$n'),
                                    ))
                                .toList(),
                            onChanged: _isDownloading
                                ? null
                                : (v) => setState(() => _tracksPerBird = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Поиск птиц...',
                          prefixIcon: Icon(Icons.search,
                              color: AppTheme.textMuted),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          PillLabel(text: 'Выбрано: ${_selected.length}'),
                          const Spacer(),
                          TextButton(
                            onPressed: _isDownloading
                                ? null
                                : () => setState(
                                    () => _selected.addAll(filtered)),
                            child: const Text('Все'),
                          ),
                          TextButton(
                            onPressed: _isDownloading
                                ? null
                                : () => setState(
                                    () => _selected.removeAll(filtered)),
                            child: const Text('Сбросить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(horizontalPadding),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final bird = filtered[i];
                      final sel = _selected.contains(bird);
                      return CheckboxListTile(
                        value: sel,
                        title: Text(bird,
                            style: TextStyle(
                              color: sel
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                            )),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: _isDownloading
                            ? null
                            : (v) => setState(() {
                                  if (v == true) {
                                    _selected.add(bird);
                                  } else {
                                    _selected.remove(bird);
                                  }
                                }),
                      );
                    },
                  ),
                ),
                if (_isDownloading)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(
                          value: _total > 0 ? _completed / _total : null,
                          backgroundColor: AppTheme.bg3,
                          valueColor: AlwaysStoppedAnimation(AppTheme.accent),
                        ),
                        const SizedBox(height: 8),
                        Text('$_completed / $_total — $_status',
                            style: AppText.small),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.bg2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView(
                            children: _log
                                .map((l) => Text(l,
                                    style: AppText.small
                                        .copyWith(fontSize: 11)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading || _selected.isEmpty
                          ? null
                          : _startDownload,
                      icon: Icon(_isDownloading
                          ? Icons.downloading
                          : Icons.download_rounded),
                      label: Text(_isDownloading
                          ? 'Скачивание...'
                          : 'Скачать для ${_selected.length} птиц'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}