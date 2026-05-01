import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/collection_download_service.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';

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
  final _urlController = TextEditingController();
  bool _downloading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Télécharger une base')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              _buildFeedback(_successMessage!, AppTheme.ownedLight,
                  AppTheme.owned,
                  icon: Icons.check_circle,
                  iconColor: AppTheme.owned,
                  textColor: AppTheme.owned),
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
                            leading: const Icon(Icons.check_circle,
                                color: AppTheme.owned),
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
        color: AppTheme.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text('Importer un fichier JSON local',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
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
