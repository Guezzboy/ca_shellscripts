import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/display_item.dart';
import '../../../core/providers/item_providers.dart';
import '../../../core/repositories/owned_item_repository.dart';
import '../../../shared/theme/app_theme.dart';

void showItemDetail(
    BuildContext context, DisplayItem item, String collectionId) {
  final container = ProviderScope.containerOf(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: _ItemDetailSheet(item: item, collectionId: collectionId),
    ),
  );
}

class _ItemDetailSheet extends ConsumerStatefulWidget {
  final DisplayItem item;
  final String collectionId;

  const _ItemDetailSheet({required this.item, required this.collectionId});

  @override
  ConsumerState<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends ConsumerState<_ItemDetailSheet> {
  late DisplayItem _item;
  int _imageIndex = 0;
  final PageController _pageCtrl = PageController();
  final TextEditingController _noteCtrl = TextEditingController();
  Timer? _debounce;
  final _noteRepo = OwnedItemRepository();
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadNote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (_item.owned && _item.ownedRecordId != null) {
      final note = await _noteRepo.loadNote(_item.ownedRecordId!);
      if (mounted) _noteCtrl.text = note ?? '';
    } else {
      if (mounted) _noteCtrl.clear();
    }
  }

  void _onNoteChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (_item.owned && _item.ownedRecordId != null) {
        _noteRepo.saveNote(_item.ownedRecordId!, value);
      }
    });
  }

  Future<void> _toggleOwned() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    await ref
        .read(collectionItemsProvider(widget.collectionId).notifier)
        .toggleOwned(_item);
    if (!mounted) return;
    final items =
        await ref.read(collectionItemsProvider(widget.collectionId).future);
    final fresh = items.where((i) => i.id == _item.id).firstOrNull;
    if (mounted) {
      setState(() {
        if (fresh != null) _item = fresh;
        _toggling = false;
      });
      await _loadNote();
    }
  }

  Future<void> _deleteCustom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet item ?'),
        content: Text('"${_item.name}" sera définitivement supprimé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(collectionItemsProvider(widget.collectionId).notifier)
          .deleteCustomItem(_item.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  // All image sources for this item
  List<String> get _images {
    if (_item.imagePaths.isNotEmpty) return _item.imagePaths;
    final urls = <String>[];
    if (_item.imageUrl != null && _item.imageUrl!.isNotEmpty) {
      urls.add(_item.imageUrl!);
    }
    final sprite = _item.metadata?['sprite_url'] as String?;
    if (sprite != null && sprite.isNotEmpty && sprite != _item.imageUrl) {
      urls.add(sprite);
    }
    return urls;
  }

  bool get _useLocalFiles => _item.imagePaths.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final meta = _item.metadata;

    return Container(
      // ~88% of screen height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gallery
                  _buildGallery(images),
                  // Thumbnails
                  if (images.length > 1) _buildThumbnails(images),
                  // Info
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        if (meta != null) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildMetadata(meta),
                        ],
                        if (_item.owned && !_item.isCustom) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildNotesField(),
                        ],
                        const SizedBox(height: 24),
                        _buildCta(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: images.isEmpty
              ? Container(
                  color: const Color(0xFFEFEDE8),
                  child: const Icon(Icons.image_outlined,
                      size: 64, color: Color(0xFFBBB8B2)),
                )
              : PageView.builder(
                  controller: _pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (_, i) => _buildGalleryImage(images[i]),
                ),
        ),
        // Owned badge
        if (_item.owned)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.owned,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Possédé',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        // Page counter
        if (images.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_imageIndex + 1} / ${images.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGalleryImage(String src) {
    if (_useLocalFiles) {
      return Image.file(File(src),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 48, color: Colors.grey));
    }
    return Image.network(src,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 48, color: Colors.grey));
  }

  Widget _buildThumbnails(List<String> images) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _pageCtrl.animateToPage(i,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: i == _imageIndex ? AppTheme.primary : AppTheme.border,
                width: i == _imageIndex ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: _useLocalFiles
                  ? Image.file(File(images[i]), fit: BoxFit.cover)
                  : Image.network(images[i], fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _item.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (_item.isRare)
              Container(
                margin: const EdgeInsets.only(top: 2, left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Text('⭐ Rare',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        if (_item.number != null) ...[
          const SizedBox(height: 3),
          Text('#${_item.number}',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary)),
        ],
        if (_item.isCustom) ...[
          const SizedBox(height: 4),
          const Text('Item personnalisé',
              style:
                  TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ],
    );
  }

  Widget _buildMetadata(Map<String, dynamic> meta) {
    final rows = <({String label, String value})>[];

    void add(String label, dynamic val) {
      if (val == null) return;
      final str = val is List ? val.join(', ') : val.toString();
      if (str.isNotEmpty) rows.add((label: label, value: str));
    }

    add('Type', meta['type']);
    add('Génération', meta['generation'] != null ? 'Gen ${meta['generation']}' : null);
    add('Édition', meta['annee_edition']);
    add('Série', meta['serie']);
    add('Couleur', meta['couleur_dominante']);
    add('N° Pokédex', meta['numero_pokedex'] != null ? '#${meta['numero_pokedex']}' : null);
    add('Licence', meta['licence']);

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Détails',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(r.label,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary)),
                  ),
                  Expanded(
                    child: Text(r.value,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8)),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          onChanged: _onNoteChanged,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'État, provenance, commentaire…',
            contentPadding: EdgeInsets.all(10),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCta() {
    if (_item.isCustom) {
      return OutlinedButton.icon(
        onPressed: _deleteCustom,
        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
        label:
            const Text('Supprimer', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red)),
      );
    }
    if (_toggling) {
      return const Center(
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return _item.owned
        ? OutlinedButton.icon(
            onPressed: _toggleOwned,
            icon: const Icon(Icons.remove_circle_outline,
                size: 16, color: Colors.red),
            label: const Text('Retirer de la collection',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red)),
          )
        : ElevatedButton.icon(
            onPressed: _toggleOwned,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Ajouter à la collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.owned,
              foregroundColor: Colors.white,
            ),
          );
  }
}
