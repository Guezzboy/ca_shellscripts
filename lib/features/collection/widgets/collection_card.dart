import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/collection.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';

class CollectionCard extends ConsumerWidget {
  final Collection collection;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final ownedAsync = ref.watch(ownedCountProvider(collection.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Collection emoji/icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: tokens.accentSoft,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _emojiFor(collection.name),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              collection.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                          ownedAsync.when(
                            data: (owned) {
                              final total = collection.itemCount;
                              if (total == 0) return const SizedBox.shrink();
                              return Text(
                                '$owned/${total}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.accentDeep,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ownedAsync.when(
                        data: (owned) {
                          final total = collection.itemCount;
                          final pct = total > 0 ? owned / total : 0.0;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor:
                                  tokens.ink.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tokens.accent,
                              ),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(
                          minHeight: 6,
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: tokens.ink.withOpacity(0.4)),
                  onPressed: () => _showOptions(context, tokens),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _emojiFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('verre') || n.contains('moutarde')) return '🍷';
    if (n.contains('manga') || n.contains('one piece') || n.contains('livre'))
      return '📚';
    if (n.contains('carte') || n.contains('pokémon') || n.contains('pokemon'))
      return '🎴';
    if (n.contains('vinyl') || n.contains('pif')) return '💿';
    if (n.contains('pin')) return '📌';
    return '📦';
  }

  void _showOptions(BuildContext context, ThemeTokens tokens) {
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: tokens.ink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer la collection',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
