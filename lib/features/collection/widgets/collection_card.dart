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
    final ownedAsync = ref.watch(ownedCountProvider(collection.id));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ownedAsync.when(
                    data: (owned) {
                      final total = collection.itemCount;
                      final pct = total > 0 ? owned / total : 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            total == 0
                                ? 'Vide'
                                : '$owned possédé${owned > 1 ? "s" : ""} sur $total',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (total > 0) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 3,
                                backgroundColor: AppTheme.border,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppTheme.owned),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 13,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ownedAsync.when(
              data: (owned) {
                final total = collection.itemCount;
                if (total == 0) return const SizedBox.shrink();
                final pct = (owned / total * 100).round();
                return Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        pct == 100 ? AppTheme.owned : AppTheme.textSecondary,
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.more_vert,
                  size: 20, color: AppTheme.textSecondary),
              onPressed: () => _showOptions(context),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.border,
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
