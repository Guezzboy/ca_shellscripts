import 'package:flutter/material.dart';
import '../../../core/services/collection_search_service.dart';
import '../../../shared/theme/app_theme.dart';

class SearchResultCard extends StatelessWidget {
  final CollectionSearchResult result;
  final VoidCallback onImport;
  final bool alreadyImported;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.onImport,
    this.alreadyImported = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final col = result.collection;
    final meta = result.meta;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header : nom + source chip ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    col.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _SourceChip(source: meta.source),
              ],
            ),
            if (col.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                col.description,
                style: TextStyle(
                    fontSize: 12, color: Colors.brown.shade600, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),

            // ── Stats ──
            Row(
              children: [
                _Stat(Icons.list_alt, '${col.totalItems} items'),
                const SizedBox(width: 14),
                _Stat(Icons.image_outlined,
                    '${(meta.imageCompleteness * 100).toInt()}% images'),
              ],
            ),
            const SizedBox(height: 4),

            // ── Barre de complétude images ──
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: meta.imageCompleteness,
                minHeight: 4,
                backgroundColor: Colors.grey.shade200,
                color: meta.imageCompleteness > 0.5
                    ? tokens.accent
                    : meta.imageCompleteness > 0.2
                        ? Colors.amber.shade600
                        : Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 12),

            // ── Action ──
            Align(
              alignment: Alignment.centerRight,
              child: alreadyImported
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: tokens.accentSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: tokens.accent),
                          const SizedBox(width: 5),
                          Text('Déjà importée',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.accent)),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onImport,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Importer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final String source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (source) {
      'local' => (Colors.green.shade100, Colors.green.shade800, 'locale'),
      'coleka' =>
        (Colors.blue.shade100, Colors.blue.shade800, 'Coleka'),
      _ => (Colors.indigo.shade50, Colors.indigo.shade700, source),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Stat(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: tokens.ink.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: tokens.ink.withOpacity(0.6))),
      ],
    );
  }
}
