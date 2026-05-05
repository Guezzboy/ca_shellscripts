import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/collection_providers.dart' hide HomeStats;
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../widgets/collection_card.dart';

class CollectionsListScreen extends ConsumerWidget {
  const CollectionsListScreen({super.key});

  String _sortLabel(CollectionSortMode mode) => switch (mode) {
        CollectionSortMode.dateNewest => 'Plus récent',
        CollectionSortMode.dateOldest => 'Plus ancien',
        CollectionSortMode.nameAsc => 'Nom A–Z',
        CollectionSortMode.nameDesc => 'Nom Z–A',
        CollectionSortMode.completionAsc => 'Progression ↑',
        CollectionSortMode.completionDesc => 'Progression ↓',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final sortMode = ref.watch(collectionSortModeProvider);
    final collectionsAsync = ref.watch(sortedCollectionsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text('Collections'),
        backgroundColor: tokens.bg,
        actions: [
          PopupMenuButton<CollectionSortMode>(
            icon: const Icon(Icons.sort_outlined, size: 22),
            tooltip: 'Trier',
            initialValue: sortMode,
            onSelected: (mode) =>
                ref.read(collectionSortModeProvider.notifier).state = mode,
            itemBuilder: (_) => CollectionSortMode.values
                .map((m) => PopupMenuItem(
                      value: m,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m == sortMode)
                            Icon(Icons.check, size: 16, color: tokens.accent)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(_sortLabel(m)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: collectionsAsync.when(
        loading: () => const _ShimmerLoading(),
        error: (e, _) => ErrorRetry(
          message: 'Erreur : $e',
          onRetry: () => ref.invalidate(sortedCollectionsProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyState(
              tokens: tokens,
              onCreate: () => context.push('/create-collection'),
              onDownload: () => context.push('/download'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return CollectionCard(
                      collection: entry.collection,
                      onTap: () =>
                          context.push('/collection/${entry.collection.id}'),
                      onDelete: () => _confirmDelete(context, ref,
                          entry.collection.id, entry.collection.name),
                    );
                  },
                ),
              ),
              // Action buttons
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/create-collection'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nouvelle'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/download'),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Importer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "$name" et tous ses items ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(collectionsProvider.notifier).delete(id);
    }
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => const ShimmerListTile(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeTokens tokens;
  final VoidCallback onCreate;
  final VoidCallback onDownload;

  const _EmptyState({
    required this.tokens,
    required this.onCreate,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: tokens.accent,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune collection',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tokens.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Importez une base JSON ou créez\nune collection vide.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.ink.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Créer une collection'),
            ),
          ],
        ),
      ),
    );
  }
}
