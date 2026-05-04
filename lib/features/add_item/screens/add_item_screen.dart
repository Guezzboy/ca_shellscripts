import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/providers/item_providers.dart';
import '../../../core/models/display_item.dart';
import '../../../core/services/isbn_lookup_service.dart';
import '../../../core/services/badge_checker.dart';
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

  // ISBN
  final _isbnController = TextEditingController();
  final _isbnService = IsbnLookupService();

  // Create form
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  // Pre-filled book data from ISBN lookup
  String? _prefillAuthor;
  String? _prefillPublisher;
  String? _prefillYear;
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
    _isbnController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _scanIsbn() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _IsbnScannerDialog(),
    );
    if (result != null && result.isNotEmpty && mounted) {
      _isbnController.text = result;
      await _lookupIsbn(result);
    }
  }

  Future<void> _lookupIsbn(String isbn) async {
    if (isbn.trim().isEmpty) return;
    final book = await _isbnService.lookupIsbn(isbn.trim());
    if (!mounted) return;

    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ISBN introuvable.')),
      );
      return;
    }

    // Check duplicates
    final items =
        ref.read(collectionItemsProvider(widget.collectionId)).valueOrNull;
    final existing = items?.where(
        (i) => i.isbn != null && i.isbn!.replaceAll(RegExp(r'[^0-9X]'), '') == isbn.trim());
    if (existing != null && existing.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '"${existing.first.name}" est déjà dans votre collection.')),
        );
      }
      return;
    }

    // Show confirmation bottom sheet
    if (mounted) {
      await _showIsbnConfirmation(book, isbn.trim());
    }
  }

  Future<void> _showIsbnConfirmation(BookData book, String isbn) async {
    final tokens = context.themeTokens;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: tokens.ink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2)),
            ),
            if (book.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(book.coverUrl!,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            const SizedBox(height: 12),
            Text(book.title ?? 'Livre inconnu',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            if (book.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(book.subtitle!,
                  style: TextStyle(
                      fontSize: 14, color: tokens.ink.withOpacity(0.6)),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 12),
            if (book.authors.isNotEmpty)
              _infoRow('Auteur', book.authorString),
            if (book.publisher != null) _infoRow('Éditeur', book.publisher!),
            if (book.year != null) _infoRow('Année', book.year!),
            if (book.pageCount != null)
              _infoRow('Pages', book.pageCount.toString()),
            const SizedBox(height: 16),
            Text('ISBN: $isbn',
                style: TextStyle(
                    fontSize: 12, color: tokens.ink.withOpacity(0.6))),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter ce livre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      _prefillAuthor = book.authorString.isNotEmpty ? book.authorString : null;
      _prefillPublisher = book.publisher;
      _prefillYear = book.year;
      _nameController.text = book.title ?? '';
      _tabController.animateTo(1); // Switch to Create tab
    }
  }

  Widget _infoRow(String label, String value) {
    final tokens = context.themeTokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: tokens.ink.withOpacity(0.6))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
            isbnController: _isbnController,
            onScanIsbn: _scanIsbn,
            onLookupIsbn: () => _lookupIsbn(_isbnController.text),
          ),
          _CreateTab(
            nameController: _nameController,
            numberController: _numberController,
            isbnController: _isbnController,
            onScanIsbn: _scanIsbn,
            prefillAuthor: _prefillAuthor,
            prefillPublisher: _prefillPublisher,
            prefillYear: _prefillYear,
            saving: _saving,
            onSave: _saveCustomItem,
          ),
        ],
      ),
    );
  }

  Future<void> _saveCustomItem() async {
    var name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis.')),
      );
      return;
    }

    // If ISBN lookup pre-filled book data, embed it in the name so it's visible
    if (_prefillAuthor != null) {
      name = '$name — $_prefillAuthor';
      if (_prefillYear != null) name = '$name, $_prefillYear';
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
            source: _prefillAuthor != null ? 'isbn' : 'manual',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" ajouté à la collection.')),
        );
        BadgeChecker.afterAdd(context);
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
  final TextEditingController isbnController;
  final VoidCallback onScanIsbn;
  final VoidCallback onLookupIsbn;

  const _SearchTab({
    required this.collectionId,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.isbnController,
    required this.onScanIsbn,
    required this.onLookupIsbn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(
        itemSearchProvider((collectionId: collectionId, query: searchQuery)));

    return Column(
      children: [
        // ISBN row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: isbnController,
                  decoration: InputDecoration(
                    hintText: 'ISBN (code-barres)',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.qr_code, size: 18),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      onPressed: onScanIsbn,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: isbnController.text.isNotEmpty
                      ? (_) => onLookupIsbn()
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: isbnController.text.trim().isNotEmpty
                      ? onLookupIsbn
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('Rechercher'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 16),

        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          backgroundColor: context.themeTokens.accent,
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
  final TextEditingController isbnController;
  final VoidCallback onScanIsbn;
  final String? prefillAuthor;
  final String? prefillPublisher;
  final String? prefillYear;
  final bool saving;
  final VoidCallback onSave;

  const _CreateTab({
    required this.nameController,
    required this.numberController,
    required this.isbnController,
    required this.onScanIsbn,
    this.prefillAuthor,
    this.prefillPublisher,
    this.prefillYear,
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
          // ISBN row
          TextField(
            controller: isbnController,
            decoration: InputDecoration(
              labelText: 'ISBN (optionnel)',
              hintText: 'Scanner ou saisir le code-barres',
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: onScanIsbn,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              hintText: 'Ex: Verre Mickey Mouse',
            ),
          ),
          if (prefillAuthor != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Auteur: $prefillAuthor',
                  style: TextStyle(
                      fontSize: 12, color: context.themeTokens.ink.withOpacity(0.6))),
            ),
          if (prefillPublisher != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Éditeur: $prefillPublisher',
                  style: TextStyle(
                      fontSize: 12, color: context.themeTokens.ink.withOpacity(0.6))),
            ),
          if (prefillYear != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Année: $prefillYear',
                  style: TextStyle(
                      fontSize: 12, color: context.themeTokens.ink.withOpacity(0.6))),
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

// ── ISBN scanner dialog ────────────────────────────────────────────────────

class _IsbnScannerDialog extends StatefulWidget {
  @override
  State<_IsbnScannerDialog> createState() => _IsbnScannerDialogState();
}

class _IsbnScannerDialogState extends State<_IsbnScannerDialog> {
  late final MobileScannerController _ctrl;
  bool _found = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner un code-barres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _ctrl.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _ctrl,
        onDetect: (capture) {
          if (_found) return;
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final raw = barcode.rawValue;
            if (raw != null && raw.isNotEmpty) {
              _found = true;
              Navigator.of(context).pop(raw);
              return;
            }
          }
        },
      ),
    );
  }
}
