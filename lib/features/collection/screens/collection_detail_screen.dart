import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../core/providers/item_providers.dart';
import '../../../core/models/display_item.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/item_card.dart';

enum _FilterMode { all, owned, missing }

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final String collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  _FilterMode _filter = _FilterMode.all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final collectionAsync =
        ref.watch(collectionByIdProvider(widget.collectionId));
    final itemsAsync =
        ref.watch(collectionItemsProvider(widget.collectionId));
    final ownedCountAsync =
        ref.watch(ownedCountProvider(widget.collectionId));

    return Scaffold(
      appBar: AppBar(
        title: collectionAsync.when(
          data: (c) => Text(c?.name ?? 'Collection'),
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('Erreur'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildSearchBar(),
        ),
        actions: [
          PopupMenuButton<_FilterMode>(
            icon: const Icon(Icons.filter_list),
            initialValue: _filter,
            onSelected: (mode) => setState(() => _filter = mode),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: _FilterMode.all, child: Text('Tous')),
              const PopupMenuItem(
                  value: _FilterMode.owned, child: Text('Possédés ✓')),
              const PopupMenuItem(
                  value: _FilterMode.missing, child: Text('Manquants')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(itemsAsync, ownedCountAsync),
          Expanded(
            child: itemsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (items) {
                final filtered = _applyFilter(items);
                if (filtered.isEmpty) {
                  return _buildEmptyState(items.isEmpty);
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ItemCard(
                      item: item,
                      onTap: () => _onItemTap(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: SizedBox(
        height: 38,
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Rechercher dans la collection...',
            prefixIcon: const Icon(Icons.search, size: 18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildStatsBar(
    AsyncValue<List<DisplayItem>> itemsAsync,
    AsyncValue<int> ownedCountAsync,
  ) {
    return Container(
      color: AppTheme.primaryBrown.withAlpha(15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          itemsAsync.when(
            data: (items) => ownedCountAsync.when(
              data: (owned) {
                final total = items.where((i) => !i.isCustom).length;
                final custom = items.where((i) => i.isCustom).length;
                return Expanded(
                  child: Text(
                    '$owned / $total possédés'
                    '${custom > 0 ? " · $custom perso" : ""}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                );
              },
              loading: () => const Expanded(child: SizedBox.shrink()),
              error: (_, __) => const Expanded(child: SizedBox.shrink()),
            ),
            loading: () => const Expanded(child: SizedBox.shrink()),
            error: (_, __) => const Expanded(child: SizedBox.shrink()),
          ),
          if (_filter != _FilterMode.all)
            Chip(
              label: Text(
                _filter == _FilterMode.owned ? 'Possédés' : 'Manquants',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => setState(() => _filter = _FilterMode.all),
              deleteIcon: const Icon(Icons.close, size: 14),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noItems) {
    if (noItems) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Colors.brown.shade300),
            const SizedBox(height: 16),
            const Text('Collection vide'),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des items via photo ou recherche.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.brown.shade300),
          const SizedBox(height: 16),
          const Text('Aucun résultat'),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardboard,
          border: Border(
            top: BorderSide(color: Colors.brown.shade200),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomBarButton(
              icon: Icons.camera_alt,
              label: 'Photo',
              onTap: () => context.push('/add-photo/${widget.collectionId}'),
            ),
            _BottomBarButton(
              icon: Icons.edit,
              label: 'Manuel',
              onTap: () => context.push('/add-item/${widget.collectionId}'),
            ),
            _BottomBarButton(
              icon: Icons.download,
              label: 'Télécharger',
              onTap: () => context.push('/download'),
            ),
          ],
        ),
      ),
    );
  }

  List<DisplayItem> _applyFilter(List<DisplayItem> items) {
    var filtered = items;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              (i.number?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    switch (_filter) {
      case _FilterMode.owned:
        filtered = filtered.where((i) => i.owned).toList();
      case _FilterMode.missing:
        filtered = filtered.where((i) => !i.owned).toList();
      case _FilterMode.all:
        break;
    }
    return filtered;
  }

  Future<void> _onItemTap(DisplayItem item) async {
    if (item.isCustom) {
      _showCustomItemOptions(item);
      return;
    }
    await ref
        .read(collectionItemsProvider(widget.collectionId).notifier)
        .toggleOwned(item);
  }

  void _showCustomItemOptions(DisplayItem item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(item.name),
              subtitle: item.number != null ? Text('#${item.number}') : null,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer cet item'),
              onTap: () {
                Navigator.pop(context);
                // TODO: implement delete custom item
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryBrown, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.primaryBrown),
            ),
          ],
        ),
      ),
    );
  }
}
