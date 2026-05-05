import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/collection_download_service.dart';
import '../../../core/services/collection_search_service.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/search_result_card.dart';

const _catalogIndexUrl =
    'https://raw.githubusercontent.com/Guezzboy/ca_shellscripts/claude/'
    'collection-app-android-0XgBI/sample_data/index.json';

const _popularCollections = [
  (
    name: 'Verres Pokémon Amora',
    icon: '⭐',
    url:
        'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/claude/collection-app-android-0XgBI/sample_data/amora_pokemon.json',
  ),
  (
    name: 'Verres Amora Disney',
    icon: '🍷',
    url:
        'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/claude/collection-app-android-0XgBI/sample_data/amora_disney.json',
  ),
  (
    name: 'Cartes Panini FIFA 2026',
    icon: '⚽',
    url:
        'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/claude/collection-app-android-0XgBI/sample_data/panini_fifa2026.json',
  ),
  (
    name: 'Figurines Nintendo Smash',
    icon: '🎮',
    url:
        'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/claude/collection-app-android-0XgBI/sample_data/nintendo_smash.json',
  ),
  (
    name: 'Cartes Magic The Gathering',
    icon: '🃏',
    url:
        'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/claude/collection-app-android-0XgBI/sample_data/magic_mtg.json',
  ),
];

class _CatalogEntry {
  final String name;
  final String description;
  final String category;
  final int itemCount;
  final String emoji;
  final String url;
  final String source;

  const _CatalogEntry({
    required this.name,
    required this.description,
    required this.category,
    required this.itemCount,
    required this.emoji,
    required this.url,
    required this.source,
  });

  factory _CatalogEntry.fromJson(Map<String, dynamic> json) => _CatalogEntry(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
        emoji: json['emoji'] as String? ?? '📦',
        url: json['url'] as String? ?? '',
        source: json['source'] as String? ?? '',
      );
}

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  ThemeTokens get _tokens => context.themeTokens;
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  bool _downloading = false;
  String? _errorMessage;
  String? _successMessage;

  // ── Catalog state ──
  List<_CatalogEntry> _catalogEntries = [];
  bool _catalogLoading = false;
  String? _catalogError;

  // ── Search state ──
  bool _isSearching = false;
  List<CollectionSearchResult>? _searchResults;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
  }

  Future<void> _fetchCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10)));
      final resp = await dio.get(_catalogIndexUrl);
      if (resp.data == null) {
        setState(() {
          _catalogLoading = false;
          _catalogError = 'Réponse vide du catalogue.';
        });
        return;
      }
      final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
      final raw = (data['collections'] as List<dynamic>?)
              ?.map((e) => _CatalogEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _catalogEntries = raw;
        _catalogLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = 'Catalogue indisponible : recherche locale utilisée.';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Découvrir')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Recherche de collection ───────────────────────────────────
            _buildSearchBar(),
            // ── Catalog status indicators ──
            if (_catalogLoading)
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 16, right: 16),
                child: Row(
                  children: [
                    SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Chargement du catalogue...',
                        style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            if (_catalogError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
                child: Text(_catalogError!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange.shade700)),
              ),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildFeedback(
                    _searchError!, Colors.red.shade50, Colors.red.shade200,
                    icon: Icons.error, iconColor: Colors.red),
              ),
            if (_searchResults != null && _searchResults!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Résultats',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              ..._searchResults!.map((r) => _buildSearchResultCard(r)),
              const SizedBox(height: 8),
              const Divider(),
            ] else if (_searchResults != null && _searchResults!.isEmpty &&
                _searchError == null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Aucune collection trouvée.',
                  style: TextStyle(
                      fontSize: 13, color: Colors.brown.shade500),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],

            const SizedBox(height: 8),

            // ── Import fichier local ──────────────────────────────────────
            _buildLocalImportCard(),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── URL personnalisée ─────────────────────────────────────────
            const Text('Depuis une URL',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL de la base (JSON)',
                hintText: 'https://example.com/collection.json',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _downloading ? null : _downloadFromUrl,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              label:
                  Text(_downloading ? 'Téléchargement...' : 'Télécharger'),
            ),

            // ── Collections populaires (nécessitent internet) ─────────────
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Collections populaires',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text('nécessite internet',
                      style: TextStyle(
                          fontSize: 10, color: Colors.orange.shade800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...(_popularSectionEntries().map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading:
                        Text(e.emoji, style: const TextStyle(fontSize: 24)),
                    title: Text(e.name),
                    subtitle: Text(
                      e.description.isNotEmpty
                          ? e.description
                          : e.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: TextButton(
                      onPressed: _downloading
                          ? null
                          : () => _download(e.url, e.name),
                      child: const Text('Télécharger'),
                    ),
                  ),
                ))),

            // ── Feedback ─────────────────────────────────────────────────
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildFeedback(
                  _errorMessage!, Colors.red.shade50, Colors.red.shade200,
                  icon: Icons.error, iconColor: Colors.red),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              _buildFeedback(_successMessage!, _tokens.accentSoft,
                  _tokens.accent,
                  icon: Icons.check_circle,
                  iconColor: _tokens.accent,
                  textColor: _tokens.accent),
            ],

            // ── Collections déjà importées ────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Collections importées',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            collectionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (collections) {
                if (collections.isEmpty) {
                  return Text('Aucune collection pour l\'instant.',
                      style: TextStyle(color: Colors.brown.shade500));
                }
                return Column(
                  children: collections
                      .map((c) => ListTile(
                            leading: Icon(Icons.check_circle,
                                color: _tokens.accent),
                            title: Text(c.name),
                            subtitle: Text('${c.itemCount} items'),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () {
                                context.pop();
                                context.push('/collection/${c.id}');
                              },
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFormatDoc(),
          ],
        ),
      ),
    );
  }

  /// Merge catalog entries with hardcoded fallback for the popular section.
  List<({String name, String emoji, String description, String url})>
      _popularSectionEntries() {
    if (_catalogEntries.isNotEmpty) {
      return _catalogEntries
          .map((e) => (
                name: e.name,
                emoji: e.emoji,
                description: e.description,
                url: e.url,
              ))
          .toList();
    }
    // Fallback: use hardcoded list (no descriptions available)
    return _popularCollections
        .map((c) => (
              name: c.name,
              emoji: c.icon,
              description: '',
              url: c.url,
            ))
        .toList();
  }

  Widget _buildLocalImportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tokens.accent.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tokens.ink.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open, color: _tokens.accent),
              const SizedBox(width: 8),
              Text('Importer un fichier JSON local',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _tokens.accent)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sélectionne un fichier .json sur ton ordinateur. '
            'Les fichiers de démo sont dans le dossier sample_data/ du projet.',
            style: TextStyle(fontSize: 13, color: Colors.brown.shade700),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _downloading ? null : _importFromFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choisir un fichier JSON'),
          ),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une collection...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = null;
                                _searchError = null;
                              });
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearch(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearching ? null : _onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tokens.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: const Text('Chercher',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(CollectionSearchResult result) {
    final colName = result.collection.name;
    final existingCollections = ref.read(collectionsProvider).valueOrNull;
    final alreadyImported = existingCollections?.any(
          (c) => c.name.toLowerCase() == colName.toLowerCase(),
        ) ??
        false;

    return SearchResultCard(
      result: result,
      alreadyImported: alreadyImported,
      onImport: () => _importResult(result),
    );
  }

  // ── Search actions ───────────────────────────────────────────────────────

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = null;
    });

    final results = await _localSearch(query);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchResults = results;
      if (results.isEmpty) {
        _searchError = 'Aucune collection trouvée pour "$query".';
      }
    });
  }

  /// Search the online catalog + hardcoded fallback by name / description / category.
  Future<List<CollectionSearchResult>> _localSearch(String query) async {
    final q = _normalize(query);
    final results = <CollectionSearchResult>[];
    final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12)));

    // ── 1. Search online catalog entries ──
    final catalogMatches = _catalogEntries
        .where((e) =>
            _normalize(e.name).contains(q) ||
            _normalize(e.description).contains(q) ||
            _normalize(e.category).contains(q))
        .toList();

    for (final entry in catalogMatches) {
      try {
        final resp = await dio.get(entry.url);
        if (resp.data == null) continue;
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        final result = _parseJsonToSearchResult(
            data as Map<String, dynamic>,
            catalogEntry: entry);
        if (result != null) results.add(result);
      } catch (_) {}
    }

    // ── 2. Hardcoded fallback (only for entries NOT already in catalog) ──
    final catalogUrls =
        _catalogEntries.map((e) => e.url.toLowerCase()).toSet();
    final hardcodedMatches = _popularCollections
        .where((c) =>
            _normalize(c.name).contains(q) &&
            !catalogUrls.contains(c.url.toLowerCase()))
        .toList();

    for (final match in hardcodedMatches) {
      try {
        final resp = await dio.get(match.url);
        if (resp.data == null) continue;
        final data = resp.data is String ? jsonDecode(resp.data) : resp.data;
        final result = _parseJsonToSearchResult(
            data as Map<String, dynamic>,
            fallbackIcon: match.icon);
        if (result != null) results.add(result);
      } catch (_) {}
    }

    return results;
  }

  /// Strip diacritics so "pokémon" matches "pokemon".
  String _normalize(String s) {
    return s
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .toLowerCase();
  }

  /// Parse a downloaded JSON (popular collection format) into a search result.
  /// Handles three formats:
  /// - Flat: {name, items[]}
  /// - Structured: {collection: {name, ...}, items[]}
  /// - Amora: {collection: {nom, marque, licence, verres[]}}
  ///
  /// [catalogEntry] enriches the result with catalog metadata (emoji, description, source).
  /// [fallbackIcon] is used for hardcoded entries not in the online catalog.
  CollectionSearchResult? _parseJsonToSearchResult(Map<String, dynamic> json,
      {_CatalogEntry? catalogEntry, String? fallbackIcon}) {
    try {
      // ── Amora format: {collection: {nom, marque, licence, verres[]}} ──
      if (json.containsKey('collection')) {
        final col = json['collection'] as Map<String, dynamic>;
        if (col.containsKey('verres') && col.containsKey('nom')) {
          return _parseAmoraFormat(col, catalogEntry: catalogEntry);
        }
      }

      // ── Structured: {collection: {...}, items: [...]} ──
      Map<String, dynamic> colData;
      List<dynamic> itemsRaw;

      if (json.containsKey('collection') && json.containsKey('items')) {
        colData = json['collection'] as Map<String, dynamic>;
        itemsRaw = json['items'] as List<dynamic>;
      } else if (json.containsKey('name') && json.containsKey('items')) {
        // ── Flat: {name, items[]} ──
        colData = json;
        itemsRaw = json['items'] as List<dynamic>;
      } else {
        return null;
      }

      final items = itemsRaw.map((i) {
        final m = i is Map<String, dynamic> ? i : <String, dynamic>{};
        return SearchResultItem.fromJson(m);
      }).toList();

      final source = catalogEntry?.source.isNotEmpty == true
          ? catalogEntry!.source
          : 'local';
      final desc = catalogEntry?.description ??
          colData['description']?.toString() ??
          '';
      final emoji = catalogEntry?.emoji ?? fallbackIcon ?? '';
      final richDesc = emoji.isNotEmpty ? '$emoji  $desc' : desc;

      return CollectionSearchResult(
        collection: CollectionMeta(
          id: colData['id']?.toString() ?? colData['name']?.toString() ?? '',
          name: colData['name']?.toString() ?? '',
          description: richDesc,
          totalItems: (colData['item_count'] as num?)?.toInt() ?? items.length,
        ),
        items: items,
        meta: SearchMeta(
            source: source, imageCompleteness: 1.0),
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse Amora-specific format: {nom, marque, licence, verres[]}.
  CollectionSearchResult _parseAmoraFormat(Map<String, dynamic> col,
      {_CatalogEntry? catalogEntry}) {
    final name = col['nom'] as String? ?? '';
    final marque = col['marque'] as String?;
    final licence = col['licence'] as String?;
    final displayName = [name, if (marque != null) marque].join(' — ');
    final source = catalogEntry?.source.isNotEmpty == true
        ? catalogEntry!.source
        : 'local';
    final desc = catalogEntry?.description ?? licence ?? '';
    final emoji = catalogEntry?.emoji ?? '';
    final description = emoji.isNotEmpty ? '$emoji  $desc' : desc;

    final rawItems = col['verres'] as List<dynamic>? ?? [];
    final items = rawItems.map((raw) {
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final artworkUrl = map['artwork_url'] as String?;
      final spriteUrl = map['sprite_url'] as String?;
      final imageUrl = (artworkUrl?.isNotEmpty ?? false) ? artworkUrl : spriteUrl;

      return SearchResultItem(
        id: map['id']?.toString() ?? '',
        name: map['pokemon'] as String? ?? '',
        subtitle: map['type'] is List
            ? (map['type'] as List).join(', ')
            : map['type']?.toString() ?? '',
        year: map['annee_edition']?.toString(),
        series: map['serie'] as String?,
        description: [map['couleur_dominante']?.toString(),
                      if (map['rare'] == true) 'Rare']
            .whereType<String>()
            .join(', '),
        images: [if (imageUrl?.isNotEmpty ?? false) imageUrl!],
      );
    }).toList();

    return CollectionSearchResult(
      collection: CollectionMeta(
        id: name,
        name: displayName,
        description: description,
        totalItems: items.length,
      ),
      items: items,
      meta: SearchMeta(source: source, imageCompleteness: 1.0),
    );
  }

  Future<void> _importResult(CollectionSearchResult result) async {
    setState(() {
      _downloading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final service = CollectionDownloadService();
      final imported =
          await service.importJson(result.toImportJson());
      await ref.read(collectionsProvider.notifier).refresh();
      if (mounted) {
        setState(() {
          _downloading = false;
          _successMessage =
              '${result.collection.name} importée : ${imported.itemCount} items.';
          _searchResults = null;
          _searchController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _errorMessage = 'Erreur : ${e.toString()}';
        });
      }
    }
  }

  Widget _buildFeedback(String message, Color bg, Color border,
      {required IconData icon,
      required Color iconColor,
      Color? textColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: textColor ?? iconColor))),
        ],
      ),
    );
  }

  Widget _buildFormatDoc() {
    return ExpansionTile(
      title: const Text('Format JSON attendu',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)),
          child: const SelectableText(
            '{\n'
            '  "name": "Ma Collection",\n'
            '  "version": 1,\n'
            '  "items": [\n'
            '    {\n'
            '      "id": "item-001",\n'
            '      "name": "Mickey Mouse",\n'
            '      "number": "001",\n'
            '      "image_url": "https://..."\n'
            '    }\n'
            '  ]\n'
            '}',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _importFromFile() async {
    setState(() {
      _downloading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) {
        setState(() => _downloading = false);
        return;
      }
      final content =
          await File(result.files.single.path!).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      final service = CollectionDownloadService();
      final imported = await service.importJson(data);
      await ref.read(collectionsProvider.notifier).refresh();
      if (mounted) {
        setState(() => _successMessage =
            'Importé : ${imported.itemCount} items ajoutés.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur : ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _downloadFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir une URL.');
      return;
    }
    await _download(url, null);
  }

  Future<void> _download(String url, String? displayName) async {
    setState(() {
      _downloading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final service = CollectionDownloadService();
      final result = await service.downloadFromUrl(url);
      await ref.read(collectionsProvider.notifier).refresh();
      if (mounted) {
        setState(() => _successMessage =
            '${displayName ?? "Collection"} téléchargée : '
            '${result.itemCount} items importés.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur : ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}
