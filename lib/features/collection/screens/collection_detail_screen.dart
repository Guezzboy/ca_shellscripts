import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../core/providers/item_providers.dart';
import '../../../core/models/display_item.dart';
import '../../../core/services/collection_export_service.dart';
import '../../../core/services/badge_checker.dart';
import '../../../core/repositories/item_repository.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

enum _Filter { all, owned, missing, wanted }

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final String collectionId;
  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen>
    with TickerProviderStateMixin {
  _Filter _filter = _Filter.all;
  String _search = '';
  final _searchController = TextEditingController();
  bool _videGrenierMode = false;

  late final AnimationController _trophyCtrl;
  late final Animation<double> _trophyScale;
  bool _wasComplete = false;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;
  bool _showEmptyOverlay = false;

  @override
  void initState() {
    super.initState();
    _trophyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _trophyScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.12), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 20),
    ]).animate(_trophyCtrl);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bounceAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    // Check if empty overlay was already shown
    SharedPreferences.getInstance().then((prefs) {
      final shown = prefs.getBool('onboarding_grid_tip_shown') ?? false;
      if (mounted) setState(() => _showEmptyOverlay = !shown);
    });
  }

  @override
  void dispose() {
    _trophyCtrl.dispose();
    _bounceCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _dismissOverlay() async {
    setState(() => _showEmptyOverlay = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_grid_tip_shown', true);
  }

  Future<void> _markAllOwned(List<DisplayItem> items) async {
    final notifier =
        ref.read(collectionItemsProvider(widget.collectionId).notifier);
    for (final item in items) {
      if (!item.owned) {
        await notifier.toggleOwned(item);
      }
    }
    await _dismissOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    final collectionAsync =
        ref.watch(collectionByIdProvider(widget.collectionId));
    final itemsAsync =
        ref.watch(collectionItemsProvider(widget.collectionId));
    final ownedAsync = ref.watch(ownedCountProvider(widget.collectionId));

    // Trophy bounce when the collection first reaches 100 %
    ref.listen(ownedCountProvider(widget.collectionId), (_, next) {
      next.whenData((owned) {
        final items =
            ref.read(collectionItemsProvider(widget.collectionId)).valueOrNull;
        if (items == null || items.isEmpty) return;
        final isComplete = owned >= items.length;
        if (isComplete && !_wasComplete) _trophyCtrl.forward(from: 0);
        _wasComplete = isComplete;

        // Dismiss empty overlay on first owned item
        if (owned > 0 && _showEmptyOverlay) {
          _dismissOverlay();
        }
      });
    });

    // Start/stop bounce animation based on overlay visibility
    if (_showEmptyOverlay && !_bounceCtrl.isAnimating) {
      _bounceCtrl.repeat(reverse: true);
    } else if (!_showEmptyOverlay && _bounceCtrl.isAnimating) {
      _bounceCtrl.stop();
    }

    return Scaffold(
      backgroundColor: tokens.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: tokens.surface,
            foregroundColor: tokens.ink,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: collectionAsync.when(
              data: (c) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c?.name ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.3)),
                  if (_videGrenierMode)
                    const Text('Mode Vide-Grenier',
                        style: TextStyle(
                            fontSize: 11, color: Colors.amber)),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            actions: [
              IconButton(
                onPressed: () => _exportCollection(),
                icon: const Icon(Icons.share_outlined, size: 20),
                tooltip: 'Exporter cette collection',
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _videGrenierMode = !_videGrenierMode),
                icon: Icon(
                  _videGrenierMode
                      ? Icons.shopping_bag
                      : Icons.shopping_bag_outlined,
                  color: _videGrenierMode
                      ? Colors.amber.shade700
                      : tokens.ink.withOpacity(0.6),
                ),
                tooltip: 'Mode Vide-Grenier',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(94),
              child: Column(
                children: [
                  Container(
                    color: tokens.surface,
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: itemsAsync.when(
                      data: (items) => ownedAsync.when(
                        data: (owned) => _buildProgressHeader(items, owned),
                        loading: () => const SizedBox(height: 30),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      loading: () => const SizedBox(height: 30),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  Container(
                    color: tokens.surface,
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
          loading: () => const _ShimmerGrid(),
          error: (e, _) => ErrorRetry(
            message: 'Erreur : $e',
            onRetry: () =>
                ref.invalidate(collectionItemsProvider(widget.collectionId)),
          ),
          data: (items) {
            final filtered = _applyFilter(items);

            // Vide-grenier mode: compact list with swipe
            if (_videGrenierMode) {
              final vgItems = filtered
                  .where((i) => i.wanted || i.owned)
                  .toList();
              if (vgItems.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun item recherché ou possédé.\nPassez en mode normal pour en ajouter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.ink.withOpacity(0.6)),
                  ),
                );
              }
              return _buildVideGrenierList(vgItems);
            }

            if (filtered.isEmpty) {
              return Center(
                child: Text(
                  items.isEmpty ? 'Collection vide' : 'Aucun resultat',
                  style: TextStyle(color: tokens.ink.withOpacity(0.6)),
                ),
              );
            }

            // Owned count for overlay logic
            final ownedCount = items.where((i) => i.owned).length;
            final showOverlay = _showEmptyOverlay && ownedCount == 0;

            return Stack(
              children: [
                // Grid
                GridView.builder(
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
                    onTap: () => showItemDetail(
                        context, filtered[i], widget.collectionId),
                    onToggleOwned: () => ref
                        .read(collectionItemsProvider(widget.collectionId)
                            .notifier)
                        .toggleOwned(filtered[i]),
                    onCycle: () async {
                      await ref
                          .read(collectionItemsProvider(widget.collectionId)
                              .notifier)
                          .cycleState(filtered[i]);
                      _checkWantedBadge();
                    },
                  ),
                ),

                // Empty state overlay (Positioned.fill so BackdropFilter covers full screen)
                if (showOverlay)
                  Positioned.fill(child: _buildEmptyOverlay(items)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _videGrenierMode
          ? FloatingActionButton.extended(
              onPressed: () => _shareWishlist(),
              icon: const Icon(Icons.share),
              label: const Text('Partager'),
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildEmptyOverlay(List<DisplayItem> allItems) {
    final tokens = context.themeTokens;
    return Stack(
      children: [
        // Blurred grid behind
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.black54),
            ),
          ),
        ),

        // Content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouncing magnifying glass
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnim.value),
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.manage_search_rounded,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Vous ne possedez encore aucun item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Appui long sur un item pour l\'ajouter\na votre collection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Arrow pointing down toward grid
                AnimatedBuilder(
                  animation: _bounceAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounceAnim.value * 0.5),
                      child: Transform.rotate(
                        angle: 2.6, // pointing down-left
                        child: child,
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 28,
                    color: Colors.white38,
                  ),
                ),
                const SizedBox(height: 24),

                // Mark all as owned button
                ElevatedButton.icon(
                  onPressed: () => _markAllOwned(allItems),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Marquer tout comme possede'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader(List<DisplayItem> items, int owned) {
    final tokens = context.themeTokens;
    final total = items.length;
    final pct = total > 0 ? (owned / total).clamp(0.0, 1.0) : 0.0;
    final isComplete = total > 0 && pct == 1.0;
    final pctInt = (pct * 100).round();
    final custom = items.where((i) => i.isCustom).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '$owned / $total items \u2022 $pctInt%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.ink,
              ),
            ),
            if (custom > 0) ...[
              const SizedBox(width: 6),
              Text(
                '($custom perso)',
                style: TextStyle(
                    fontSize: 11, color: tokens.ink.withOpacity(0.6)),
              ),
            ],
            const Spacer(),
            ScaleTransition(
              scale: _trophyScale,
              child: Icon(
                Icons.emoji_events_rounded,
                size: 20,
                color: isComplete
                    ? const Color(0xFFFFB300)
                    : const Color(0xFFD0CCBF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final tokens = context.themeTokens;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher\u2026',
                hintStyle:
                    TextStyle(fontSize: 13, color: tokens.ink.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, size: 18,
                    color: tokens.ink.withOpacity(0.6)),
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
            label: '\u2713',
            active: _filter == _Filter.owned,
            activeColor: tokens.accent,
            onTap: () => setState(() => _filter = _Filter.owned)),
        const SizedBox(width: 4),
        _FilterChip(
            label: '\u25CB',
            active: _filter == _Filter.missing,
            onTap: () => setState(() => _filter = _Filter.missing)),
        const SizedBox(width: 4),
        _FilterChip(
            label: '🔍',
            active: _filter == _Filter.wanted,
            activeColor: Colors.amber.shade700,
            onTap: () => setState(() => _filter = _Filter.wanted)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final tokens = context.themeTokens;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(top: BorderSide(color: tokens.ink.withOpacity(0.15))),
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

  void _shareWishlist() async {
    final items =
        ref.read(collectionItemsProvider(widget.collectionId)).valueOrNull;
    if (items == null) return;
    final wantedItems = items.where((i) => i.wanted).toList();
    if (wantedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun item dans la wishlist.')),
      );
      return;
    }

    final collection =
        ref.read(collectionByIdProvider(widget.collectionId)).valueOrNull;
    final name = collection?.name ?? 'Ma collection';
    final buf = StringBuffer();
    buf.writeln('📋 Wishlist — $name');
    buf.writeln();
    for (final item in wantedItems) {
      final num = item.number != null ? '#${item.number} ' : '';
      buf.writeln('• $num${item.name}');
    }

    await Share.share(buf.toString(), subject: 'Wishlist — $name');
  }

  Future<void> _exportCollection() async {
    try {
      final exportService = CollectionExportService();
      final json =
          await exportService.exportCollection(widget.collectionId);
      final collection =
          ref.read(collectionByIdProvider(widget.collectionId)).valueOrNull;
      final name = collection?.name ?? 'collection';
      await Share.share(json, subject: 'Collection — $name');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export : $e')),
        );
      }
    }
  }

  Widget _buildVideGrenierList(List<DisplayItem> items) {
    final tokens = context.themeTokens;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return Dismissible(
          key: ValueKey(item.id),
          background: Container(
            color: tokens.accent,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Swipe right → mark owned
              if (!item.owned) {
                await ref
                    .read(collectionItemsProvider(widget.collectionId)
                        .notifier)
                    .toggleOwned(item);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      content: Text('"${item.name}" marqué comme possédé'),
                      action: SnackBarAction(
                        label: 'Annuler',
                        onPressed: () => ref
                            .read(collectionItemsProvider(widget.collectionId)
                                .notifier)
                            .toggleOwned(item),
                      ),
                    ));
                }
              }
              return false; // Don't actually dismiss
            } else {
              // Swipe left → remove wanted / unmark owned
              if (item.wanted && !item.owned) {
                await ref
                    .read(collectionItemsProvider(widget.collectionId)
                        .notifier)
                    .toggleWanted(item);
                _checkWantedBadge();
              } else if (item.owned) {
                await ref
                    .read(collectionItemsProvider(widget.collectionId)
                        .notifier)
                    .toggleOwned(item);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(SnackBar(
                      content: Text('"${item.name}" retiré'),
                      action: SnackBarAction(
                        label: 'Annuler',
                        onPressed: () => ref
                            .read(collectionItemsProvider(widget.collectionId)
                                .notifier)
                            .toggleOwned(item),
                      ),
                    ));
                }
              }
              return false;
            }
          },
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 48,
                child: item.imageUrl != null
                    ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFEFEDE8),
                            child: Icon(Icons.image_outlined,
                                size: 20, color: tokens.ink.withOpacity(0.6))))
                    : Container(
                        color: const Color(0xFFEFEDE8),
                        child: Icon(Icons.image_outlined,
                            size: 20, color: tokens.ink.withOpacity(0.6))),
              ),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: item.owned
                    ? tokens.ink
                    : tokens.ink.withOpacity(0.6),
              ),
            ),
            subtitle: Row(
              children: [
                if (item.number != null) ...[
                  Text('#${item.number}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                ],
                if (item.wanted && !item.owned)
                  Text('🔍 Recherché',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700)),
                if (item.owned)
                  Text('✓ Possédé',
                      style: TextStyle(
                          fontSize: 12, color: tokens.accent)),
              ],
            ),
            trailing: Icon(
              item.owned
                  ? Icons.check_circle
                  : Icons.search,
              color: item.owned
                  ? tokens.accent
                  : Colors.amber.shade700,
            ),
            onTap: () =>
                showItemDetail(context, item, widget.collectionId),
          ),
        );
      },
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
      _Filter.wanted => list.where((i) => i.wanted).toList(),
      _Filter.all => list,
    };
  }

  Future<void> _checkWantedBadge() async {
    if (!mounted) return;
    final repo = ItemRepository();
    final count = await repo.countWanted();
    BadgeChecker.afterWantedChanged(context, count);
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
    final tokens = context.themeTokens;
    final color = activeColor ?? tokens.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? color : tokens.ink.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : tokens.ink.withOpacity(0.6),
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
        label: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => const ShimmerItemCard(),
    );
  }
}
