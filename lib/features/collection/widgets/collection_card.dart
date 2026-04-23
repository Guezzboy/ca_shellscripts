import 'package:flutter/material.dart';
import '../../../core/models/collection.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final ownedAsync =
        ref.watch(ownedCountProvider(collection.id));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBrown.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.collections_bookmark,
                      color: AppTheme.primaryBrown,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ownedAsync.when(
                          data: (owned) => Text(
                            '$owned / ${collection.itemCount} items',
                            style: TextStyle(
                                color: Colors.brown.shade600, fontSize: 13),
                          ),
                          loading: () => const SizedBox(
                              height: 14,
                              child: LinearProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ownedAsync.when(
                data: (owned) {
                  final total = collection.itemCount;
                  final pct = total > 0 ? owned / total : 0.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.brown.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.ownedGreen),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}% complété',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.brown.shade600,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
