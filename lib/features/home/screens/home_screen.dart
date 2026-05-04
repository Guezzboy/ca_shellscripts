import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/collection_providers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../widgets/object_card.dart';

/// Home screen — Hi-fi A variant from Colectio wireframes.
/// Hero progress ring + journal feed.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── greeting header ──
            SliverToBoxAdapter(child: _GreetingHeader(tokens: tokens)),
            // ── hero ring + floating cards ──
            SliverToBoxAdapter(
              child: collectionsAsync.when(
                data: (collections) => _HeroSection(
                  tokens: tokens,
                  totalOwned: collections.fold<int>(
                    0,
                    (sum, c) => sum + c.itemCount,
                  ),
                  totalAll: collections.fold<int>(
                    0,
                    (sum, c) => sum + c.itemCount,
                  ),
                ),
                loading: () => _HeroSection(tokens: tokens),
                error: (_, __) => _HeroSection(tokens: tokens),
              ),
            ),
            // ── journal: today ──
            SliverToBoxAdapter(
              child: _SectionLabel(tokens: tokens, text: "Aujourd'hui"),
            ),
            // Recent add card
            SliverToBoxAdapter(child: _RecentAddCard(tokens: tokens)),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // Badge unlocked card
            SliverToBoxAdapter(child: _BadgeCard(tokens: tokens)),
            // ── journal: yesterday ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: _SectionLabel(tokens: tokens, text: 'Hier'),
              ),
            ),
            SliverToBoxAdapter(child: _YesterdayCard(tokens: tokens)),

            // Bottom padding (above nav bar)
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }
}

// ── greeting ──
class _GreetingHeader extends StatelessWidget {
  final ThemeTokens tokens;
  const _GreetingHeader({required this.tokens});

  @override
  Widget build(BuildContext context) {
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
                  'Bonjour, Léa',
                  style: TextStyle(
                    fontSize: 12,
                    color: tokens.ink.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Belle journée pour collectionner ☀️',
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
              'L',
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
    this.totalOwned = 0,
    this.totalAll = 1,
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
          // Center ring
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
          // Floating mini cards
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

// ── journal: recent add card ──
class _RecentAddCard extends StatelessWidget {
  final ThemeTokens tokens;
  const _RecentAddCard({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
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
              color: const Color(0xFFF4A72B),
              label: 'Astérix',
              width: 44,
              height: 56,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu as ajouté',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Astérix légionnaire',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Moutarde du Lion \u2022 il y a 2h',
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
                color: tokens.accent,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── journal: badge card ──
class _BadgeCard extends StatelessWidget {
  final ThemeTokens tokens;
  const _BadgeCard({required this.tokens});

  @override
  Widget build(BuildContext context) {
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
              child: const Text('🏆', style: TextStyle(fontSize: 18)),
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
                  const Text(
                    'Petit trésor',
                    style: TextStyle(
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
  const _YesterdayCard({required this.tokens});

  @override
  Widget build(BuildContext context) {
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
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.ink,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: '3 ajouts',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' dans '),
                    TextSpan(
                      text: 'One Piece',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: tokens.ink.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
