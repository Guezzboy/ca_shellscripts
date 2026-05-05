import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../core/services/badge_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/collection_emoji.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../widgets/object_card.dart';

/// Home screen — data-driven with real progress ring and journal feed.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) => _HomeContent(tokens: tokens, stats: stats),
          loading: () => const _HomeContent(tokens: null),
          error: (_, __) => const _HomeContent(tokens: null),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final ThemeTokens? tokens;
  final HomeStats? stats;
  const _HomeContent({required this.tokens, this.stats});

  @override
  Widget build(BuildContext context) {
    final t = tokens ?? context.themeTokens;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _GreetingHeader(tokens: t)),
        if (stats != null)
          SliverToBoxAdapter(
            child: _HeroSection(
              tokens: t,
              totalOwned: stats!.totalOwned,
              totalAll: stats!.totalItems,
            ),
          )
        else
          const SliverToBoxAdapter(child: ShimmerHomeHero()),
        // ── per-collection progress ──
        if (stats != null && stats!.collections.isNotEmpty)
          SliverToBoxAdapter(
            child: _CollectionsSection(tokens: t, stats: stats!),
          ),
        // ── journal: today ──
        SliverToBoxAdapter(
          child: _SectionLabel(tokens: t, text: "Aujourd'hui"),
        ),
        SliverToBoxAdapter(
          child: _RecentAddCard(tokens: t, stats: stats),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: _BadgeCard(tokens: t, badge: stats?.lastBadge),
        ),
        // ── journal: yesterday ──
        if (stats != null && stats!.yesterdayEntries.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: _SectionLabel(tokens: t, text: 'Hier'),
            ),
          ),
          SliverToBoxAdapter(
            child: _YesterdayCard(
              tokens: t,
              stats: stats!,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }
}

// ── greeting ──
String _greetingForHour(int hour) {
  if (hour >= 6 && hour < 12) return 'Belle journée pour collectionner ☀️';
  if (hour >= 12 && hour < 18) return 'Continue ta collection ☀️';
  return 'Belle soirée de collection 🌙';
}

class _GreetingHeader extends StatelessWidget {
  final ThemeTokens tokens;
  const _GreetingHeader({required this.tokens});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.7, -0.8),
          radius: 1.2,
          colors: [
            tokens.accentSoft,
            tokens.bg,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.ink.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _greetingForHour(hour),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.accentSoft,
              border: Border.all(color: tokens.accent, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              'C',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tokens.accentDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── hero progress ring with floating items ──
class _FloatingCard {
  final Color color;
  final double tilt;
  final double top;
  final double? left;
  final double? right;

  const _FloatingCard({
    required this.color,
    required this.tilt,
    required this.top,
    this.left,
    this.right,
  });
}

class _HeroSection extends StatelessWidget {
  final ThemeTokens tokens;
  final int totalOwned;
  final int totalAll;

  const _HeroSection({
    required this.tokens,
    required this.totalOwned,
    required this.totalAll,
  });

  static const _floatingCards = [
    _FloatingCard(color: Color(0xFFF4A72B), tilt: -12.0, top: 6.0, left: 38.0),
    _FloatingCard(color: Color(0xFFE07A1F), tilt: 10.0, top: 50.0, right: 32.0),
    _FloatingCard(color: Color(0xFFFFD166), tilt: -8.0, top: 80.0, left: 46.0),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: ProgressRing(
              value: totalAll > 0 ? totalOwned / totalAll : 0.0,
              size: 150,
              strokeWidth: 9,
              color: tokens.accent,
              color2: tokens.accentDeep,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${totalAll > 0 ? (totalOwned * 100 ~/ totalAll) : 0}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: tokens.accentDeep,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalOwned / $totalAll objets',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._floatingCards.map(
            (c) => Positioned(
              top: c.top,
              left: c.left,
              right: c.right,
              child: ObjectCard(
                color: c.color,
                size: 'sm',
                tilt: c.tilt,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── section label ──
class _SectionLabel extends StatelessWidget {
  final ThemeTokens tokens;
  final String text;
  const _SectionLabel({required this.tokens, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: tokens.ink.withOpacity(0.55),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── time ago helper ──
String _timeAgo(int timestampMs) {
  final diff = DateTime.now().millisecondsSinceEpoch - timestampMs;
  if (diff < 60 * 1000) return "à l'instant";
  final mins = diff ~/ (60 * 1000);
  if (mins < 60) return 'il y a ${mins}min';
  final hours = mins ~/ 60;
  if (hours < 24) return 'il y a ${hours}h';
  final days = hours ~/ 24;
  return 'il y a ${days}j';
}

// ── journal: recent add card ──
class _RecentAddCard extends StatelessWidget {
  final ThemeTokens tokens;
  final HomeStats? stats;

  const _RecentAddCard({required this.tokens, this.stats});

  @override
  Widget build(BuildContext context) {
    // Determine what to show
    String? itemName;
    String? collectionName;
    String? timeAgo;
    Color cardColor = const Color(0xFFF4A72B);
    String? label;

    if (stats != null) {
      final item = stats!.lastAddedItem;
      final custom = stats!.lastAddedCustom;
      if (item != null) {
        itemName = item.name;
        collectionName = stats!.lastAddedCollectionName;
        timeAgo = _timeAgo(item.createdAt);
        label = item.name.substring(0, item.name.length.clamp(0, 8));
      } else if (custom != null) {
        itemName = custom['name'] as String?;
        collectionName = stats!.lastAddedCollectionName;
        timeAgo = _timeAgo(custom['created_at'] as int);
        final n = itemName ?? '';
        label = n.substring(0, n.length.clamp(0, 8));
      }
    }

    final hasItem = itemName != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasItem ? null : () => context.push('/collections'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
          children: [
            ObjectCard(
              color: cardColor,
              label: label,
              width: 44,
              height: 56,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName != null ? 'Tu as ajouté' : 'En attente',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    itemName ?? 'Ajoute ton premier objet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    collectionName != null && timeAgo != null
                        ? '$collectionName \u2022 $timeAgo'
                        : 'Commence une collection !',
                    style: TextStyle(
                      fontSize: 10,
                      color: tokens.ink.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: itemName != null
                    ? tokens.accent
                    : tokens.ink.withOpacity(0.15),
              ),
              alignment: Alignment.center,
              child: Icon(
                itemName != null ? Icons.check : Icons.add,
                color: itemName != null ? Colors.white : tokens.ink.withOpacity(0.4),
                size: 14,
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── journal: badge card ──
class _BadgeCard extends StatelessWidget {
  final ThemeTokens tokens;
  final Badge? badge;

  const _BadgeCard({required this.tokens, this.badge});

  @override
  Widget build(BuildContext context) {
    if (badge == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tokens.accent, tokens.accentDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tokens.accent.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
              alignment: Alignment.center,
              child: Text(badge!.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Badge débloqué !',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge!.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

// ── journal: yesterday ──
class _YesterdayCard extends StatelessWidget {
  final ThemeTokens tokens;
  final HomeStats stats;
  const _YesterdayCard({required this.tokens, required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.yesterdayEntries;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              height: 56,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: ObjectCard(
                      color: const Color(0xFFF4A72B),
                      width: 44,
                      height: 56,
                      tilt: -4,
                    ),
                  ),
                  Positioned(
                    left: 20,
                    child: ObjectCard(
                      color: const Color(0xFFE07A1F),
                      width: 44,
                      height: 56,
                      tilt: 4,
                    ),
                  ),
                  Positioned(
                    left: 38,
                    child: ObjectCard(
                      color: const Color(0xFFFFD166),
                      width: 44,
                      height: 56,
                      tilt: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.ink,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: '${e.count} ajout${e.count > 1 ? 's' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' dans '),
                          TextSpan(
                            text: e.name,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: tokens.ink.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── per-collection progress section ──
class _CollectionsSection extends StatelessWidget {
  final ThemeTokens tokens;
  final HomeStats stats;
  const _CollectionsSection({required this.tokens, required this.stats});

  @override
  Widget build(BuildContext context) {
    final list = stats.collections;
    final showAll = list.length <= 5;
    final visible = showAll ? list : list.sublist(0, 5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(tokens: tokens, text: 'Collections'),
          ...visible.map(
            (c) => _CollectionStatTile(
              tokens: tokens,
              id: c.id,
              name: c.name,
              owned: c.owned,
              total: c.total,
              percentage: c.percentage,
            ),
          ),
          if (!showAll)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
              child: GestureDetector(
                onTap: () => context.push('/collections'),
                child: Text(
                  'Voir les ${list.length} collections',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tokens.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionStatTile extends StatelessWidget {
  final ThemeTokens tokens;
  final String id;
  final String name;
  final int owned;
  final int total;
  final double percentage;

  const _CollectionStatTile({
    required this.tokens,
    required this.id,
    required this.name,
    required this.owned,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final pctInt = (percentage * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/collection/$id'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: tokens.accentSoft,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emojiFor(name),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 4,
                          backgroundColor: tokens.ink.withOpacity(0.08),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(tokens.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$owned/$total \u00b7 $pctInt%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: tokens.accentDeep,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: tokens.ink.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
