import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../core/providers/item_providers.dart';
import '../../../core/models/display_item.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/item_card.dart';

enum _Filter { all, owned, missing }

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final String collectionId;
  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  _Filter _filter = _Filter.all;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync =
        ref.watch(collectionByIdProvider(widget.collectionId));
    final itemsAsync =
        ref.watch(collectionItemsProvider(widget.collectionId));
    final ownedAsync = ref.watch(ownedCountProvider(widget.collectionId));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: collectionAsync.when(
              data: (c) => Text(c?.name ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.3)),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(96),
              child: Column(
                children: [
                  // Stats row
                  Container(
                    color: AppTheme.surface,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: itemsAsync.when(
                      data: (items) => ownedAsync.when(
                        data: (owned) => _buildStats(items, owned),
                        loading: () => const SizedBox(height: 20),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () => const SizedBox(height: 20),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  // Filter + search bar
                  Container(
                    color: AppTheme.surface,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                    child: _buildFilterBar(),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
        ],
        body: itemsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (items) {
            final filtered = _applyFilter(items);
            if (filtered.isEmpty) {
              return Center(
                child: Text(
                  items.isEmpty ? 'Collection vide' : 'Aucun résultat',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 0.62,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) => ItemCard(
                item: filtered[i],
                onTap: () => _onItemTap(filtered[i]),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildStats(List<DisplayItem> items, int owned) {
    final total = items.where((i) => !i.isCustom).length;
    final custom = items.where((i) => i.isCustom).length;
    final pct = total > 0 ? owned / (total + custom) : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppTheme.textPrimary),
                  children: [
                    TextSpan(
                      text: '$owned',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                    TextSpan(
                      text: ' / ${total + custom}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary),
                    ),
                    if (custom > 0)
                      TextSpan(
                        text: '  ($custom perso)',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 3,
                  backgroundColor: AppTheme.border,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.owned),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '${(pct * 100).round()}%',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: pct == 1.0 ? AppTheme.owned : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher…',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search, size: 18,
                    color: AppTheme.textSecondary),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _FilterChip(
            label: 'Tous',
            active: _filter == _Filter.all,
            onTap: () => setState(() => _filter = _Filter.all)),
        const SizedBox(width: 4),
        _FilterChip(
            label: '✓',
            active: _filter == _Filter.owned,
            activeColor: AppTheme.owned,
            onTap: () => setState(() => _filter = _Filter.owned)),
        const SizedBox(width: 4),
        _FilterChip(
            label: '○',
            active: _filter == _Filter.missing,
            onTap: () => setState(() => _filter = _Filter.missing)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            _BarButton(
              icon: Icons.camera_alt_outlined,
              label: 'Photo',
              onTap: () =>
                  context.push('/add-photo/${widget.collectionId}'),
            ),
            const SizedBox(width: 8),
            _BarButton(
              icon: Icons.edit_outlined,
              label: 'Manuel',
              onTap: () =>
                  context.push('/add-item/${widget.collectionId}'),
            ),
            const SizedBox(width: 8),
            _BarButton(
              icon: Icons.download_outlined,
              label: 'Importer',
              onTap: () => context.push('/download'),
            ),
          ],
        ),
      ),
    );
  }

  List<DisplayItem> _applyFilter(List<DisplayItem> items) {
    var list = items;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              (i.number?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return switch (_filter) {
      _Filter.owned => list.where((i) => i.owned).toList(),
      _Filter.missing => list.where((i) => !i.owned).toList(),
      _Filter.all => list,
    };
  }

  Future<void> _onItemTap(DisplayItem item) async {
    if (item.isCustom) {
      _showCustomOptions(item);
      return;
    }
    await ref
        .read(collectionItemsProvider(widget.collectionId).notifier)
        .toggleOwned(item);
  }

  void _showCustomOptions(DisplayItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              title: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: item.number != null
                  ? Text('N° ${item.number}')
                  : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? color : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BarButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
