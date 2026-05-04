import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/collection_download_service.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';

enum _Step { name, searching, preview, saving }

class CreateCollectionScreen extends ConsumerStatefulWidget {
  const CreateCollectionScreen({super.key});

  @override
  ConsumerState<CreateCollectionScreen> createState() =>
      _CreateCollectionScreenState();
}

class _CreateCollectionScreenState
    extends ConsumerState<CreateCollectionScreen> {
  _Step _step = _Step.name;
  final _nameCtrl = TextEditingController();
  Map<String, dynamic>? _data;
  String _source = 'scaffold';
  double _imageCompleteness = 1.0;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  static String _toSlug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'ç'), 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  Future<void> _search() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _step = _Step.searching;
      _error = null;
    });

    final slug = _toSlug(name);
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ));

    // 1. Local asset
    try {
      final raw =
          await rootBundle.loadString('assets/collections/$slug.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _data = data;
          _source = 'local';
          _imageCompleteness = 1.0;
          _step = _Step.preview;
        });
      }
      return;
    } catch (_) {}

    // 2. Proxy server (Coleka enrichment)
    final proxyUrl =
        (prefs.getString('search_proxy_url') ?? '').trim();
    if (proxyUrl.isNotEmpty) {
      try {
        final resp = await dio.post<dynamic>(
          '$proxyUrl/api/search-collection',
          data: {'query': name},
        );
        final raw = resp.data;
        final data = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        final meta =
            data['_meta'] as Map<String, dynamic>? ?? {};
        final proxySource =
            (meta['source'] as String?) ?? 'coleka';
        // Only accept non-scaffold results from proxy
        if (proxySource != 'scaffold') {
          if (mounted) {
            setState(() {
              _data = data;
              _source = proxySource;
              _imageCompleteness =
                  (meta['imageCompleteness'] as num?)
                      ?.toDouble() ??
                  1.0;
              _step = _Step.preview;
            });
          }
          return;
        }
      } catch (_) {}
    }

    // 3. Remote URL from settings
    final base =
        (prefs.getString('remote_collection_base_url') ?? '').trim();
    if (base.isNotEmpty) {
      try {
        final resp = await dio.get<dynamic>('$base/$slug.json');
        final raw = resp.data;
        final data = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : raw as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _data = data;
            _source = 'remote';
            _imageCompleteness = 1.0;
            _step = _Step.preview;
          });
        }
        return;
      } catch (_) {}
    }

    // 4. Scaffold fallback
    if (mounted) {
      setState(() {
        _data = _buildScaffold(name, slug);
        _source = 'scaffold';
        _imageCompleteness = 0.0;
        _step = _Step.preview;
      });
    }
  }

  static Map<String, dynamic> _buildScaffold(String name, String slug) => {
        'collection': {
          'id': slug,
          'name': name,
          'description': '',
          'totalItems': 10,
        },
        'items': List.generate(10, (i) {
          final n = (i + 1).toString().padLeft(3, '0');
          return {
            'id': '$slug-$n',
            'name': 'Item $n',
            'subtitle': '',
            'year': null,
            'series': null,
            'description': '',
            'images': <String>[],
            'owned': false,
            'notes': '',
          };
        }),
      };

  Future<void> _confirm() async {
    if (_data == null) return;
    setState(() => _step = _Step.saving);
    try {
      final service = CollectionDownloadService();
      final result = await service.importJson(_data!);
      await ref.read(collectionsProvider.notifier).refresh();
      if (mounted) context.go('/collection/${result.collectionId}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _step = _Step.preview;
        });
      }
    }
  }

  // ── Preview helpers ───────────────────────────────────────────────────────

  String get _previewName {
    final d = _data!;
    final col = d['collection'];
    if (col is Map) return col['name'] as String? ?? '';
    return d['name'] as String? ?? '';
  }

  String get _previewDescription {
    final d = _data!;
    final col = d['collection'];
    if (col is Map) return col['description'] as String? ?? '';
    return '';
  }

  int get _previewCount {
    final d = _data!;
    final items = d['items'] as List<dynamic>?;
    if (items != null) return items.length;
    final col = d['collection'];
    if (col is Map) {
      return (col['verres'] as List<dynamic>?)?.length ??
          (col['totalItems'] as int? ?? 0);
    }
    return 0;
  }

  List<String> get _previewImages {
    final d = _data!;
    final List<dynamic> items = d['items'] as List<dynamic>?
        ?? (d['collection'] is Map
            ? ((d['collection'] as Map)['verres'] as List<dynamic>? ?? [])
            : []);
    final urls = <String>[];
    for (final raw in items) {
      if (urls.length >= 9) break;
      final item = raw as Map<String, dynamic>;
      // Structured format: images[]
      final imgs = item['images'] as List<dynamic>?;
      if (imgs != null && imgs.isNotEmpty) {
        urls.add(imgs.first as String);
        continue;
      }
      // Standard format
      final url = item['image_url'] as String?;
      if (url != null && url.isNotEmpty) { urls.add(url); continue; }
      // Amora format
      final artwork = item['artwork_url'] as String?;
      final sprite = item['sprite_url'] as String?;
      final u = (artwork?.isNotEmpty ?? false) ? artwork : sprite;
      if (u != null && u.isNotEmpty) urls.add(u);
    }
    return urls;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.ink,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text('Nouvelle collection',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (_step) {
          _Step.name => _buildNameStep(),
          _Step.searching => _buildSearchingStep(),
          _Step.preview => _buildPreviewStep(),
          _Step.saving => _buildSavingStep(),
        },
      ),
    );
  }

  Widget _buildNameStep() {
    final tokens = context.themeTokens;
    return SingleChildScrollView(
      key: const ValueKey('name'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Nom de la collection',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: tokens.ink)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ex: Cartes Panini FIFA 2026',
              prefixIcon: Icon(Icons.collections_bookmark_outlined),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Rechercher les données'),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.accent.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.ink.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comment ça marche ?',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: tokens.ink)),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.folder_outlined,
                    label: 'Fichiers locaux',
                    text: 'assets/collections/{slug}.json'),
                _InfoRow(
                    icon: Icons.travel_explore_outlined,
                    label: 'Proxy Coleka',
                    text: 'URL proxy dans Paramètres → Serveur proxy'),
                _InfoRow(
                    icon: Icons.cloud_outlined,
                    label: 'Serveur distant',
                    text: 'URL configurée dans Paramètres → Données'),
                _InfoRow(
                    icon: Icons.auto_fix_high_outlined,
                    label: 'Modèle vide',
                    text: 'Générée si aucune source ne répond'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingStep() {
    final tokens = context.themeTokens;
    return Center(
      key: const ValueKey('searching'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 24),
          Text(
            _nameCtrl.text.trim(),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: tokens.ink),
          ),
          const SizedBox(height: 8),
          const _SearchingStatus(),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    final tokens = context.themeTokens;
    final images = _previewImages;
    final count = _previewCount;
    final name = _previewName;
    final desc = _previewDescription;

    return SingleChildScrollView(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SourceBadge(source: _source),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _step = _Step.name),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Modifier',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: tokens.ink)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc,
                style: TextStyle(
                    fontSize: 14,
                    color: tokens.ink.withOpacity(0.6),
                    height: 1.4)),
          ],
          const SizedBox(height: 6),
          Text(
            '$count item${count != 1 ? "s" : ""}',
            style: TextStyle(
                fontSize: 14,
                color: tokens.ink.withOpacity(0.6),
                fontWeight: FontWeight.w600),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ThumbnailGrid(imageUrls: images),
          ],
          if (_source == 'scaffold') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aucune source trouvée. Un modèle vide a été '
                      'généré — tu pourras ajouter des items manuellement.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_imageCompleteness < 0.5 && _source != 'scaffold') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Images incomplètes '
                      '(${(_imageCompleteness * 100).round()}% des items). '
                      'Vous pourrez les ajouter manuellement.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Créer cette collection'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingStep() {
    return const Center(
      key: ValueKey('saving'),
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _InfoRow(
      {required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: tokens.ink.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 13,
                    color: tokens.ink.withOpacity(0.6),
                    height: 1.3),
                children: [
                  TextSpan(
                      text: '$label — ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: tokens.ink)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchingStatus extends StatefulWidget {
  const _SearchingStatus();

  @override
  State<_SearchingStatus> createState() => _SearchingStatusState();
}

class _SearchingStatusState extends State<_SearchingStatus> {
  static const _labels = [
    'Vérification des fichiers locaux…',
    'Recherche sur Coleka.com…',
    'Requête vers le serveur distant…',
    'Génération du modèle…',
  ];
  int _idx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _idx = (_idx + 1) % _labels.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          _labels[_idx],
          key: ValueKey(_idx),
          style: TextStyle(
              color: tokens.ink.withOpacity(0.6), fontSize: 13),
        ),
      );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final Color color;
    final Color bg;
    final String label;
    switch (source) {
      case 'local':
        label = 'Cache local';
        color = const Color(0xFF2563EB);
        bg = const Color(0xFFEFF6FF);
      case 'coleka':
        label = 'Coleka.com';
        color = const Color(0xFF0EA5E9);
        bg = const Color(0xFFE0F2FE);
      case 'remote':
        label = 'En ligne';
        color = tokens.accent;
        bg = tokens.accentSoft;
      default:
        label = 'Modèle généré';
        color = Colors.orange.shade700;
        bg = Colors.orange.shade50;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _ThumbnailGrid extends StatelessWidget {
  final List<String> imageUrls;
  const _ThumbnailGrid({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final shown = imageUrls.take(9).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: shown.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          shown[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFEFEDE8),
            child: const Icon(Icons.image_outlined,
                color: Color(0xFFBBB8B2), size: 24),
          ),
        ),
      ),
    );
  }
}
