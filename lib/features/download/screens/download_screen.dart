import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/collection_download_service.dart';
import '../../../core/services/collection_search_service.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/search_result_card.dart';

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

  // ── Search state ──
  final _searchService = CollectionSearchService();
  bool _proxyAvailable = false;
  bool _isSearching = false;
  List<CollectionSearchResult>? _searchResults;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _checkProxy();
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
            ...(_popularCollections.map((c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading:
                        Text(c.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(c.name),
                    subtitle: Text(
                      c.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: TextButton(
                      onPressed:
                          _downloading ? null : () => _download(c.url, c.name),
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
          if (!_proxyAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recherche avancée indisponible. '
                      'Utilise les collections populaires ou importe un fichier ci-dessous.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
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
                  onSubmitted: _proxyAvailable ? (_) => _onSearch() : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (_isSearching || !_proxyAvailable) ? null : _onSearch,
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

  Future<void> _checkProxy() async {
    final available = await _searchService.isProxyAvailable();
    if (mounted) {
      setState(() => _proxyAvailable = available);
    }
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = null;
    });

    final result = await _searchService.searchCollection(query);
    if (!mounted) return;

    setState(() {
      _isSearching = false;
      if (result != null) {
        _searchResults = [result];
      } else {
        _searchError =
            'Impossible de contacter le serveur de recherche. Vérifiez que le proxy est lancé.';
      }
    });
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
