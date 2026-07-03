import 'package:flutter/material.dart';
import '../data/bird_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/responsive.dart';

class BirdCatalogScreen extends StatefulWidget {
  final Function(String latinName) onBirdSelected;
  
  const BirdCatalogScreen({
    super.key,
    required this.onBirdSelected,
  });

  @override
  State<BirdCatalogScreen> createState() => _BirdCatalogScreenState();
}

class _BirdCatalogScreenState extends State<BirdCatalogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, String>> get _filteredBirds {
    if (_searchQuery.isEmpty) {
      return BirdCatalog.russianToLatin.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
    }

    final q = _searchQuery.toLowerCase();
    return BirdCatalog.russianToLatin.entries.where((entry) {
      return entry.key.toLowerCase().contains(q) ||
             entry.value.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final contentWidth = isDesktop ? 900.0 : double.infinity;
    final filteredBirds = _filteredBirds;

    return BirdScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Каталог птиц'),
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
                            Icon(Icons.menu_book, color: AppTheme.sky, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Каталог из ${BirdCatalog.totalSpecies} видов. '
                                'Кликните на птицу для поиска.',
                                style: AppText.small,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Поиск по русскому или латинскому названию...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Найдено: ${filteredBirds.length}',
                            style: AppText.small,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredBirds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: AppTheme.textMuted),
                              const SizedBox(height: 16),
                              Text('Птицы не найдены', style: AppText.h3),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredBirds.length,
                          itemBuilder: (ctx, i) {
                            final entry = filteredBirds[i];
                            return _BirdTile(
                              russianName: entry.key,
                              latinName: entry.value,
                              onTap: () {
                                widget.onBirdSelected(entry.value);
                                Navigator.pop(context);
                              },
                            );
                          },
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

class _BirdTile extends StatelessWidget {
  final String russianName;
  final String latinName;
  final VoidCallback onTap;

  const _BirdTile({
    required this.russianName,
    required this.latinName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    russianName,
                    style: AppText.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    latinName,
                    style: AppText.small.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.sky,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}