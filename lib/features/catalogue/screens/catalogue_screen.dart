import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

/// Catalogue screen — "Bibliothèque" variant A from Colectio wireframes.
/// Browse and load complete reference collections.
class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text('Catalogues'),
        backgroundColor: tokens.bg,
      ),
      body: Column(
        children: [
          // ── search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.ink.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search,
                      size: 16, color: tokens.ink.withOpacity(0.5)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Verres, mangas, cartes\u2026',
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: tokens.ink.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: TextStyle(fontSize: 11, color: tokens.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── category pills ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CatPill(tokens: tokens, label: 'Tendances', active: true),
                _CatPill(tokens: tokens, label: 'Verres'),
                _CatPill(tokens: tokens, label: 'Livres'),
                _CatPill(tokens: tokens, label: 'Cartes'),
                _CatPill(tokens: tokens, label: 'Vinyles'),
              ],
            ),
          ),

          // ── collection list ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _CatalogueItem(
                  tokens: tokens,
                  emoji: '🍷',
                  name: 'Verres Moutarde du Lion',
                  count: 54,
                  subtitle: 'vérifié par la communauté',
                  loaded: true,
                ),
                _CatalogueItem(
                  tokens: tokens,
                  emoji: '📚',
                  name: 'Astérix \u2014 Albums',
                  count: 40,
                  subtitle: 'vérifié par la communauté',
                ),
                _CatalogueItem(
                  tokens: tokens,
                  emoji: '🎴',
                  name: 'Pokémon Base Set',
                  count: 102,
                  subtitle: 'vérifié par la communauté',
                ),
                _CatalogueItem(
                  tokens: tokens,
                  emoji: '💿',
                  name: 'Vinyles Pif Gadget',
                  count: 28,
                  subtitle: 'vérifié par la communauté',
                ),
                _CatalogueItem(
                  tokens: tokens,
                  emoji: '📌',
                  name: "Pin\u2019s Coca-Cola FR",
                  count: 64,
                  subtitle: 'vérifié par la communauté',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatPill extends StatelessWidget {
  final ThemeTokens tokens;
  final String label;
  final bool active;

  const _CatPill({
    required this.tokens,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? tokens.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? tokens.accent : tokens.ink.withOpacity(0.2),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : tokens.ink.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueItem extends StatelessWidget {
  final ThemeTokens tokens;
  final String emoji;
  final String name;
  final int count;
  final String subtitle;
  final bool loaded;

  const _CatalogueItem({
    required this.tokens,
    required this.emoji,
    required this.name,
    required this.count,
    required this.subtitle,
    this.loaded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.ink.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: loaded
                  ? tokens.accentSoft
                  : tokens.ink.withOpacity(0.06),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count objets \u2022 $subtitle',
                  style: TextStyle(
                    fontSize: 10,
                    color: tokens.ink.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (loaded)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: tokens.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Chargé',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: tokens.ink.withOpacity(0.2),
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Text(
                '+ Charger',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: tokens.ink.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
