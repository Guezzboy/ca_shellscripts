import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/collection_download_service.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';

// Popular collections registry
const _popularCollections = [
  (
    name: 'Verres Amora Disney',
    icon: '🍷',
    url: 'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/main/sample_data/amora_disney.json',
  ),
  (
    name: 'Cartes Panini FIFA 2026',
    icon: '⚽',
    url: 'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/main/sample_data/panini_fifa2026.json',
  ),
  (
    name: 'Figurines Nintendo Smash',
    icon: '🎮',
    url: 'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/main/sample_data/nintendo_smash.json',
  ),
  (
    name: 'Cartes Magic The Gathering',
    icon: '🃏',
    url: 'https://raw.githubusercontent.com/guezzboy/ca_shellscripts/main/sample_data/magic_mtg.json',
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
            // Collections populaires
            const Text(
              'Collections populaires',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_popularCollections.map((c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(c.icon,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(c.name),
                    subtitle: Text(
                      c.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: TextButton(
                      onPressed: _downloading
                          ? null
                          : () => _download(c.url, c.name),
                      child: const Text('Télécharger'),
                    ),
                  ),
                ))),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Custom URL
            const Text(
              'URL personnalisée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
              label: Text(_downloading ? 'Téléchargement...' : 'Télécharger'),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ],

            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.ownedGreenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.ownedGreen),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.ownedGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_successMessage!,
                          style:
                              const TextStyle(color: AppTheme.ownedGreen)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            // Already downloaded
            const Text(
              'Collections téléchargées',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            collectionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (collections) {
                if (collections.isEmpty) {
                  return Text(
                    'Aucune collection pour l\'instant.',
                    style: TextStyle(color: Colors.brown.shade500),
                  );
                }
                return Column(
                  children: collections
                      .map((c) => ListTile(
                            leading: const Icon(Icons.check_circle,
                                color: AppTheme.ownedGreen),
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

            // Format documentation
            _buildFormatDoc(),
          ],
        ),
      ),
    );
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

  Widget _buildFormatDoc() {
    return ExpansionTile(
      title: const Text(
        'Format JSON attendu',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SelectableText(
            '{\n'
            '  "name": "Ma Collection",\n'
            '  "version": 1,\n'
            '  "items": [\n'
            '    {\n'
            '      "id": "item-001",\n'
            '      "name": "Mickey Mouse",\n'
            '      "number": "001",\n'
            '      "description": "...",\n'
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
}
