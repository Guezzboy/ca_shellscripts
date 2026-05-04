import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/collection_card.dart';

class CollectionsListScreen extends ConsumerWidget {
  const CollectionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text('Collections'),
        backgroundColor: tokens.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: collectionsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 1.5)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (collections) {
          if (collections.isEmpty) {
            return _EmptyState(
              tokens: tokens,
              onCreate: () => context.push('/create-collection'),
              onDownload: () {},
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: collections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final col = collections[index];
                    return CollectionCard(
                      collection: col,
                      onTap: () => context.push('/collection/${col.id}'),
                      onDelete: () =>
                          _confirmDelete(context, ref, col.id, col.name),
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
                          onPressed: () {},
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
