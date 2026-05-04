import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/display_item.dart';
import '../../../core/providers/item_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/repositories/item_repository.dart';
import '../../../core/repositories/owned_item_repository.dart';
import '../../../core/services/badge_checker.dart';
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
  final _itemRepo = ItemRepository();
  final _picker = ImagePicker();
  final _uuid = const Uuid();
  bool _toggling = false;
  bool _bookExpanded = false;
  List<String> _userPhotos = [];

  bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  // All images to show: user photos first, then network reference images.
  List<String> get _images {
    if (_item.isCustom) return _userPhotos;
    final net = <String>[];
    if (_item.imageUrl != null && _item.imageUrl!.isNotEmpty) {
      net.add(_item.imageUrl!);
    }
    final sprite = _item.metadata?['sprite_url'] as String?;
    if (sprite != null && sprite.isNotEmpty && sprite != _item.imageUrl) {
      net.add(sprite);
    }
    return [..._userPhotos, ...net];
  }

  bool _isUserPhoto(String src) => _userPhotos.contains(src);

  static bool _isLocalPath(String src) =>
      src.startsWith('/') || src.startsWith('file://');

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _loadItemData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItemData() async {
    if (_item.isCustom) {
      if (mounted) setState(() => _userPhotos = List.from(_item.imagePaths));
      return;
    }
    if (_item.owned && _item.ownedRecordId != null) {
      final results = await Future.wait([
        _noteRepo.loadNote(_item.ownedRecordId!),
        _noteRepo.loadUserPhotos(_item.ownedRecordId!),
      ]);
      if (mounted) {
        _noteCtrl.text = (results[0] as String?) ?? '';
        setState(() => _userPhotos = (results[1] as List<String>?) ?? []);
      }
    } else {
      if (mounted) {
        _noteCtrl.clear();
        setState(() => _userPhotos = []);
      }
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

  // ── Photo management ─────────────────────────────────────────────────────

  Future<void> _showAddPhotoSheet() async {
    if (_isDesktop) {
      await _pickFileDesktop();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: _tokens.ink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final files =
            await _picker.pickMultiImage(maxWidth: 1200, imageQuality: 85);
        for (final f in files) {
          await _saveAndAddPhoto(f.path);
        }
      } else {
        final f = await _picker.pickImage(
            source: source, maxWidth: 1200, imageQuality: 85);
        if (f != null) await _saveAndAddPhoto(f.path);
      }
    } catch (_) {}
  }

  Future<void> _pickFileDesktop() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;
    for (final f in result.files) {
      if (f.path != null) await _saveAndAddPhoto(f.path!);
    }
  }

  Future<void> _saveAndAddPhoto(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(
        '${dir.path}/item_photos/${widget.collectionId}/${_item.id}');
    await folder.create(recursive: true);
    final dest = File('${folder.path}/${_uuid.v4()}.jpg');
    await File(sourcePath).copy(dest.path);
    final updated = [..._userPhotos, dest.path];
    await _persistUserPhotos(updated);
    if (mounted) setState(() => _userPhotos = updated);
    BadgeChecker.afterAddPhoto(context);
  }

  Future<void> _persistUserPhotos(List<String> photos) async {
    if (_item.isCustom) {
      await ref
          .read(customItemRepositoryProvider)
          .updateImagePaths(_item.id, photos);
      ref.invalidate(collectionItemsProvider(widget.collectionId));
    } else if (_item.ownedRecordId != null) {
      await _noteRepo.saveUserPhotos(_item.ownedRecordId!, photos);
    }
  }

  Future<void> _showPhotoOptions(String src) async {
    final userIdx = _userPhotos.indexOf(src);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: _tokens.ink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2)),
            ),
            if (userIdx > 0)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Mettre en premier'),
                onTap: () {
                  Navigator.pop(ctx);
                  _movePhotoFirst(userIdx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.swap_vert_outlined),
              title: const Text('Réorganiser les photos'),
              onTap: () {
                Navigator.pop(ctx);
                _showReorderSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer cette photo',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeletePhoto(src);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _movePhotoFirst(int index) {
    final updated = [..._userPhotos];
    final photo = updated.removeAt(index);
    updated.insert(0, photo);
    _persistUserPhotos(updated);
    setState(() {
      _userPhotos = updated;
      _imageIndex = 0;
      _pageCtrl.jumpToPage(0);
    });
  }

  Future<void> _confirmDeletePhoto(String src) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_isLocalPath(src)) {
      try {
        await File(src).delete();
      } catch (_) {}
    }
    final updated = _userPhotos.where((p) => p != src).toList();
    await _persistUserPhotos(updated);
    if (mounted) {
      setState(() {
        _userPhotos = updated;
        _imageIndex = min(_imageIndex, max(0, _images.length - 1));
      });
    }
  }

  void _showReorderSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        var photos = List<String>.from(_userPhotos);
        return StatefulBuilder(
          builder: (ctx, setModal) => Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.65),
            decoration: BoxDecoration(
              color: _tokens.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  decoration: BoxDecoration(
                      color: _tokens.ink.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      const Text('Réorganiser les photos',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: photos.length,
                    onReorder: (oldIdx, newIdx) {
                      if (newIdx > oldIdx) newIdx--;
                      final p = photos.removeAt(oldIdx);
                      photos.insert(newIdx, p);
                      setModal(() {});
                      _persistUserPhotos(photos);
                      setState(() => _userPhotos = List.from(photos));
                    },
                    itemBuilder: (_, i) => ListTile(
                      key: ValueKey(photos[i]),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(photos[i]),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFEFEDE8),
                          ),
                        ),
                      ),
                      title: Text('Photo ${i + 1}',
                          style: const TextStyle(fontSize: 14)),
                      trailing: Icon(Icons.drag_handle,
                          color: _tokens.ink.withOpacity(0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Owned toggle ─────────────────────────────────────────────────────────

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
      await _loadItemData();
      BadgeChecker.afterToggleOwned(context, widget.collectionId);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  ThemeTokens get _tokens => context.themeTokens;

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final meta = _item.metadata;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: _tokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: _tokens.ink.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGallery(images),
                  _buildThumbnailRow(images),
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
                        if (!_item.isCustom &&
                            (_hasBookData || _bookExpanded)) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildBookDetails(),
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

  // ── Gallery ───────────────────────────────────────────────────────────────

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return GestureDetector(
        onTap: _showAddPhotoSheet,
        child: Container(
          height: 220,
          color: const Color(0xFFEFEDE8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  size: 48, color: Colors.brown.shade300),
              const SizedBox(height: 12),
              Text('Ajouter vos photos',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.brown.shade400)),
              const SizedBox(height: 4),
              Text('Appareil photo ou galerie',
                  style: TextStyle(
                      fontSize: 13, color: Colors.brown.shade300)),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (_, i) => _buildGalleryImage(images[i]),
          ),
        ),
        if (_item.owned)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _tokens.accent,
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
    final image = _isLocalPath(src)
        ? Image.file(File(src),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 48, color: Colors.grey))
        : CachedNetworkImage(imageUrl: src,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 48, color: Colors.grey));

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: image,
    );
  }

  void _openFullscreen(BuildContext context) {
    final images = _images;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenViewer(
          images: images,
          initialIndex: _imageIndex,
          isLocal: _isLocalPath,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // ── Thumbnail row ─────────────────────────────────────────────────────────

  Widget _buildThumbnailRow(List<String> images) {
    // Always show thumbnail row (for "+" tile) after gallery is non-empty,
    // but also show a compact add row even when gallery is empty.
    final showThumbs = images.isNotEmpty;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: (showThumbs ? images.length : 0) + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          if (i == images.length) return _buildAddTile();
          final src = images[i];
          final isUser = _isUserPhoto(src);
          return GestureDetector(
            onTap: () => _pageCtrl.animateToPage(i,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut),
            onLongPress: isUser ? () => _showPhotoOptions(src) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: i == _imageIndex
                      ? _tokens.accent
                      : _tokens.ink.withOpacity(0.12),
                  width: i == _imageIndex ? 2 : 1,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: _buildThumbnailImage(src),
                  ),
                  // Small dot on user photos to distinguish from network refs
                  if (isUser)
                    const Positioned(
                      top: 2,
                      left: 2,
                      child: Icon(Icons.person, size: 9, color: Colors.white),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _showAddPhotoSheet,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _tokens.bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _tokens.ink.withOpacity(0.12)),
        ),
        child: Icon(Icons.add_a_photo_outlined,
            size: 18, color: _tokens.ink.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildThumbnailImage(String src) {
    if (_isLocalPath(src)) {
      return Image.file(File(src),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 16, color: Colors.grey));
    }
    return CachedNetworkImage(imageUrl: src,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 16, color: Colors.grey));
  }

  // ── Header & metadata ────────────────────────────────────────────────────

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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: _tokens.ink,
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
            if (_item.wanted && !_item.owned) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Text('🔍 Recherché',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
        if (_item.number != null) ...[
          const SizedBox(height: 3),
          Text('#${_item.number}',
              style: TextStyle(
                  fontSize: 14, color: _tokens.ink.withOpacity(0.6))),
        ],
        if (_item.isCustom) ...[
          const SizedBox(height: 4),
          Text('Item personnalisé',
              style:
                  TextStyle(fontSize: 12, color: _tokens.ink.withOpacity(0.6))),
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
    add('Génération',
        meta['generation'] != null ? 'Gen ${meta['generation']}' : null);
    add('Édition', meta['annee_edition']);
    add('Série', meta['serie'] ?? meta['series']);
    add('Couleur', meta['couleur_dominante']);
    add('N° Pokédex',
        meta['numero_pokedex'] != null ? '#${meta['numero_pokedex']}' : null);
    add('Sous-titre', meta['subtitle']);
    add('Année', meta['year']);
    add('Licence', meta['licence']);

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détails',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _tokens.ink.withOpacity(0.6),
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
                        style: TextStyle(
                            fontSize: 13,
                            color: _tokens.ink.withOpacity(0.6))),
                  ),
                  Expanded(
                    child: Text(r.value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _tokens.ink)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ── Book details ───────────────────────────────────────────────────────

  bool get _hasBookData =>
      _item.isbn != null ||
      _item.author != null ||
      _item.publisher != null ||
      _item.publishYear != null ||
      _item.edition != null ||
      _item.genre != null ||
      _item.condition != null ||
      _item.purchasePrice != null ||
      _item.estimatedValue != null;

  Widget _buildBookDetails() {
    if (!_hasBookData && !_bookExpanded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _bookExpanded = !_bookExpanded),
          child: Row(
            children: [
              Text('Détails',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _tokens.ink.withOpacity(0.6),
                      letterSpacing: 0.8)),
              const Spacer(),
              Icon(
                _bookExpanded
                    ? Icons.expand_less
                    : Icons.expand_more,
                size: 18,
                color: _tokens.ink.withOpacity(0.6),
              ),
            ],
          ),
        ),
        if (_bookExpanded) ...[
          const SizedBox(height: 8),
          if (!_hasBookData)
            Text(
              'Ajoutez des informations sur ce livre (ISBN, auteur, etc.).',
              style:
                  TextStyle(fontSize: 13, color: _tokens.ink.withOpacity(0.6)),
            ),
          if (_item.isbn != null)
            _BookRow(
                label: 'ISBN', value: _item.isbn!,
                onTap: () => _editBookField('ISBN', 'isbn', _item.isbn)),
          if (_item.author != null)
            _BookRow(
                label: 'Auteur', value: _item.author!,
                onTap: () =>
                    _editBookField('Auteur', 'author', _item.author)),
          if (_item.publisher != null)
            _BookRow(
                label: 'Éditeur', value: _item.publisher!,
                onTap: () => _editBookField(
                    'Éditeur', 'publisher', _item.publisher)),
          if (_item.publishYear != null)
            _BookRow(
                label: 'Année', value: _item.publishYear!,
                onTap: () => _editBookField(
                    'Année de publication', 'publishYear', _item.publishYear)),
          if (_item.edition != null)
            _BookRow(
                label: 'Édition', value: _item.edition!,
                onTap: () =>
                    _editBookField('Édition', 'edition', _item.edition)),
          if (_item.genre != null)
            _BookRow(
                label: 'Genre', value: _item.genre!,
                onTap: () =>
                    _editBookField('Genre', 'genre', _item.genre)),
          if (_item.condition != null)
            _BookRow(
                label: 'État', value: _item.condition!,
                onTap: () => _editBookField(
                    'État', 'condition', _item.condition)),
          if (_item.purchasePrice != null)
            _BookRow(
                label: 'Prix payé',
                value: '${_item.purchasePrice!.toStringAsFixed(2)} €',
                onTap: () => _editBookField(
                    'Prix payé', 'purchasePrice',
                    _item.purchasePrice?.toStringAsFixed(2))),
          if (_item.estimatedValue != null)
            _BookRow(
                label: 'Valeur estimée',
                value: '${_item.estimatedValue!.toStringAsFixed(2)} €',
                onTap: () => _editBookField(
                    'Valeur estimée', 'estimatedValue',
                    _item.estimatedValue?.toStringAsFixed(2))),

          // "Ajouter un champ" button
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddBookField(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter un champ'),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editBookField(
      String label, String field, String? current) async {
    final ctrl = TextEditingController(text: current ?? '');
    final isNumeric = field == 'purchasePrice' || field == 'estimatedValue';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              isNumeric ? TextInputType.number : TextInputType.text,
          decoration: const InputDecoration(
            hintText: 'Laisser vide pour supprimer',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          if (current != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    // Build update map (using SQL column names)
    // Map Dart field names to SQL column names
    const _dartToSql = {
      'isbn': 'isbn',
      'author': 'author',
      'publisher': 'publisher',
      'publishYear': 'publish_year',
      'edition': 'edition',
      'genre': 'genre',
      'condition': 'condition',
      'purchasePrice': 'purchase_price',
      'estimatedValue': 'estimated_value',
    };
    final col = _dartToSql[field] ?? field;
    final update = <String, dynamic>{};
    if (isNumeric) {
      final val = double.tryParse(result.replaceAll(',', '.'));
      update[col] = result.isEmpty ? null : val;
    } else {
      update[col] = result.isEmpty ? null : result;
    }

    await _itemRepo.updateBookFields(_item.id, update);

    // Refresh local state
    ref.invalidate(collectionItemsProvider(widget.collectionId));
    if (mounted) {
      final items = await ref
          .read(collectionItemsProvider(widget.collectionId).future);
      final fresh = items.where((i) => i.id == _item.id).firstOrNull;
      if (fresh != null) setState(() => _item = fresh);
    }
  }

  Future<void> _showAddBookField() async {
    final fields = <String, String>{
      'isbn': 'ISBN',
      'author': 'Auteur',
      'publisher': 'Éditeur',
      'publishYear': 'Année de publication',
      'edition': 'Édition / Tome',
      'genre': 'Genre',
      'condition': 'État',
      'purchasePrice': 'Prix payé',
      'estimatedValue': 'Valeur estimée',
    };

    final empty = fields.keys
        .where((k) => switch (k) {
              'isbn' => _item.isbn == null,
              'author' => _item.author == null,
              'publisher' => _item.publisher == null,
              'publishYear' => _item.publishYear == null,
              'edition' => _item.edition == null,
              'genre' => _item.genre == null,
              'condition' => _item.condition == null,
              'purchasePrice' => _item.purchasePrice == null,
              'estimatedValue' => _item.estimatedValue == null,
              _ => false,
            })
        .toList();

    if (empty.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tous les champs sont déjà remplis.')),
        );
      }
      return;
    }

    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                  color: _tokens.ink.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ajouter un champ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            ...empty.map((k) => ListTile(
                  title: Text(fields[k]!),
                  onTap: () => Navigator.of(ctx).pop(k),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    await _editBookField(fields[chosen]!, chosen, null);
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _tokens.ink.withOpacity(0.6),
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
    return Row(
      children: [
        // "Je le cherche" button
        Expanded(
          child: _item.wanted
              ? OutlinedButton.icon(
                  onPressed: () => _toggleWanted(),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Ne plus chercher'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _tokens.ink.withOpacity(0.6),
                    side: BorderSide(color: _tokens.ink.withOpacity(0.12)),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _toggleWanted(),
                  icon: Icon(Icons.search, size: 16,
                      color: Colors.amber.shade700),
                  label: Text('Je le cherche',
                      style: TextStyle(color: Colors.amber.shade700)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber.shade400),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        // "Je le possède" button
        Expanded(
          child: _item.owned
              ? OutlinedButton.icon(
                  onPressed: _toggleOwned,
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 16, color: Colors.red),
                  label: const Text('Retirer',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                )
              : ElevatedButton.icon(
                  onPressed: _toggleOwned,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Je le possède'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tokens.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _toggleWanted() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    await ref
        .read(collectionItemsProvider(widget.collectionId).notifier)
        .toggleWanted(_item);
    if (!mounted) return;
    final items =
        await ref.read(collectionItemsProvider(widget.collectionId).future);
    final fresh = items.where((i) => i.id == _item.id).firstOrNull;
    if (mounted) {
      setState(() {
        if (fresh != null) _item = fresh;
        _toggling = false;
      });
      final wantedCount = await _itemRepo.countWanted();
      BadgeChecker.afterWantedChanged(context, wantedCount);
    }
  }
}

class _BookRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _BookRow(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13, color: tokens.ink.withOpacity(0.6))),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.ink)),
                  ),
                  Icon(Icons.edit_outlined,
                      size: 14, color: tokens.ink.withOpacity(0.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fullscreen photo viewer ─────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool Function(String) isLocal;

  const _FullscreenViewer({
    required this.images,
    required this.initialIndex,
    required this.isLocal,
  });

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late final PageController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: _index);
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
        title: Text(
          '${_index + 1} / ${widget.images.length}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final src = widget.images[i];
          final image = widget.isLocal(src)
              ? Image.file(File(src), fit: BoxFit.contain)
              : CachedNetworkImage(imageUrl: src, fit: BoxFit.contain);
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 5.0,
            child: Center(child: image),
          );
        },
      ),
    );
  }
}
