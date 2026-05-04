import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../core/services/collection_download_service.dart';
import '../../../core/services/collection_search_service.dart';
import '../../../shared/theme/app_theme.dart';

/// Catalogue screen — "Bibliothèque" tab.
/// Search online catalogues via the Node.js proxy and import them.
class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _searchCtrl = TextEditingController();
  final _searchService = CollectionSearchService();
  final _downloadService = CollectionDownloadService();

  bool _proxyAvailable = false;
  bool _searching = false;
  String? _searchError;
  List<CollectionSearchResult>? _results;
  String? _activeCategory;
  int? _importingIdx;

  static const _categories = [
    'Tendances', 'Verres', 'Livres', 'Cartes', 'Vinyles', 'Jouets',
  ];

  static const _popular = [
    ('🍷', 'Verres Moutarde du Lion', 'verres moutarde'),
    ('📚', 'Astérix — Albums', 'asterix'),
    ('🎴', 'Pokémon Base Set', 'pokemon'),
    ('💿', 'Vinyles Pif Gadget', 'pif gadget'),
    ('📌', 'Pin\'s Coca-Cola FR', 'coca cola'),
  ];

  @override
  void initState() {
    super.initState();
    _checkProxy();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkProxy() async {
    final available = await _searchService.isProxyAvailable();
    if (mounted) setState(() => _proxyAvailable = available);
  }

  Future<void> _onSearch([String? query]) async {
    final q = (query ?? _searchCtrl.text).trim();
    if (q.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
    });

    final result = await _searchService.searchCollection(q);
    if (!mounted) return;

    setState(() {
      _searching = false;
      if (result != null) {
        _results = [result];
        _activeCategory = null;
      } else {
        _searchError = _proxyAvailable
            ? 'Aucun résultat pour "$q".'
            : 'Proxy de recherche non détecté. Lancez node server/index.js';
      }
    });
  }

  Future<void> _importResult(int index) async {
    if (_results == null) return;
    final result = _results![index];

    // Check if already imported
    final collections = ref.read(collectionsProvider).valueOrNull ?? [];
    final alreadyExists =
        collections.any((c) => c.sourceUrl == result.collection.id);
    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${result.collection.name} est déjà importée.')),
        );
      }
      return;
    }

    setState(() => _importingIdx = index);
    try {
      await _downloadService.importJson(result.toImportJson());
      ref.invalidate(collectionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${result.collection.name} importée (${result.collection.totalItems} items).'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de l\'import: $e'),
              backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _importingIdx = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final collections = ref.watch(collectionsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text('Catalogues'),
        backgroundColor: tokens.bg,
      ),
      body: Column(
        children: [
          // ── search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: tokens.ink.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            size: 16, color: tokens.ink.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Verres, mangas, cartes…',
                              hintStyle: TextStyle(
                                fontSize: 11,
                                color: tokens.ink.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            style: TextStyle(fontSize: 11, color: tokens.ink),
                            textInputAction: TextInputAction.search,
                            onSubmitted: _onSearch,
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _results = null);
                            },
                            child: Icon(Icons.clear,
                                size: 14, color: tokens.ink.withOpacity(0.4)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_proxyAvailable)
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _searching ? null : () => _onSearch(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text('Chercher',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),

          // ── category pills ──
          if (_results == null)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((label) {
                  final active = _activeCategory == label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeCategory = active ? null : label;
                        });
                        if (!active) _onSearch(label);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? tokens.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active
                                ? tokens.accent
                                : tokens.ink.withOpacity(0.2),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : tokens.ink.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── results or popular ──
          Expanded(
            child: _buildBody(tokens, collections),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeTokens tokens, List collections) {
    // Search in progress
    if (_searching) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Search error
    if (_searchError != null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.cloud_off,
                    size: 48, color: tokens.ink.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  _searchError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.ink.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _searchError = null);
                    _checkProxy();
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Search results
    if (_results != null && _results!.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: List.generate(_results!.length, (i) {
          final r = _results![i];
          final isImporting = _importingIdx == i;
          final alreadyLoaded = collections
              .any((c) => c.sourceUrl == r.collection.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.ink.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: alreadyLoaded
                        ? tokens.accentSoft
                        : tokens.ink.withOpacity(0.06),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    alreadyLoaded ? Icons.check : Icons.library_books_outlined,
                    size: 22,
                    color: alreadyLoaded
                        ? tokens.accent
                        : tokens.ink.withOpacity(0.4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.collection.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.collection.totalItems} objets · ${r.meta.source}',
                        style: TextStyle(
                          fontSize: 10,
                          color: tokens.ink.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isImporting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (alreadyLoaded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Chargé',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  )
                else
                  GestureDetector(
                    onTap: () => _importResult(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: tokens.accent,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Text('+ Charger',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tokens.accent)),
                    ),
                  ),
              ],
            ),
          );
        }),
      );
    }

    // No results yet — show quick search suggestions
    if (_results != null && _results!.isEmpty) {
      return Center(
        child: Text('Aucun résultat.',
            style:
                TextStyle(fontSize: 12, color: tokens.ink.withOpacity(0.5))),
      );
    }

    // Default: popular collections
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: _popular.map((p) {
        final (emoji, name, query) = p;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.ink.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: tokens.accentSoft,
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rechercher cette collection',
                      style: TextStyle(
                        fontSize: 10,
                        color: tokens.ink.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _searchCtrl.text = query;
                  _onSearch(query);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: tokens.accent,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Icon(Icons.search,
                      size: 16, color: tokens.accent),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
