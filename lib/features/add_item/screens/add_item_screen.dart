import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/item_providers.dart';
import '../../../core/models/display_item.dart';
import '../../../shared/theme/app_theme.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final String collectionId;

  const AddItemScreen({super.key, required this.collectionId});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Custom item form
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un item'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Rechercher dans la base'),
            Tab(text: 'Créer un item'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SearchTab(
            collectionId: widget.collectionId,
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
          ),
          _CreateTab(
            nameController: _nameController,
            numberController: _numberController,
            saving: _saving,
            onSave: _saveCustomItem,
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomItem() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(collectionItemsProvider(widget.collectionId).notifier)
          .addCustomItem(
            name: name,
            number: _numberController.text.trim().isEmpty
                ? null
                : _numberController.text.trim(),
            source: 'manual',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" ajouté à la collection.')),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Search tab ─────────────────────────────────────────────────────────────

class _SearchTab extends ConsumerWidget {
  final String collectionId;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _SearchTab({
    required this.collectionId,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(
        itemSearchProvider((collectionId: collectionId, query: searchQuery)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            autofocus: true,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom ou numéro...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        if (searchQuery.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Tapez pour rechercher dans la base téléchargée.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Expanded(
            child: searchAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Aucun résultat dans la base.'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              DefaultTabController.of(context).animateTo(1),
                          child: const Text('Créer un item personnalisé'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _SearchResultTile(
                      item: item,
                      onMark: () async {
                        await ref
                            .read(collectionItemsProvider(collectionId)
                                .notifier)
                            .toggleOwned(item);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '"${item.name}" marqué comme possédé.')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final DisplayItem item;
  final VoidCallback onMark;

  const _SearchResultTile({required this.item, required this.onMark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.brown.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(item.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.image, color: Colors.brown.shade300)),
              )
            : Icon(Icons.image_outlined, color: Colors.brown.shade300),
      ),
      title: Text(item.name),
      subtitle: item.number != null ? Text('#${item.number}') : null,
      trailing: ElevatedButton(
        onPressed: onMark,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.owned,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
        child: const Text('Possédé ✓'),
      ),
    );
  }
}

// ── Create tab ─────────────────────────────────────────────────────────────

class _CreateTab extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController numberController;
  final bool saving;
  final VoidCallback onSave;

  const _CreateTab({
    required this.nameController,
    required this.numberController,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Créer un item personnalisé',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              hintText: 'Ex: Verre Mickey Mouse',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: numberController,
            decoration: const InputDecoration(
              labelText: 'Numéro (optionnel)',
              hintText: 'Ex: 042',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add),
            label: Text(saving ? 'Ajout...' : 'Ajouter à la collection'),
          ),
        ],
      ),
    );
  }
}
