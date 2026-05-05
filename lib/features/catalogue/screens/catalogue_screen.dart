import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';

/// Catalogue screen — "Bibliothèque" tab.
/// Browse popular collections and jump to the Découvrir tab for search + import.
class CatalogueScreen extends ConsumerWidget {
  const CatalogueScreen({super.key});

  static const _categories = [
    'Tendances', 'Verres', 'Livres', 'Cartes', 'Vinyles', 'Jouets',
  ];

  static const _popular = [
    ('🍷', 'Verres Moutarde du Lion', 'verres moutarde'),
    ('📚', 'Astérix — Albums', 'asterix'),
    ('🎴', 'Pokémon Base Set', 'pokemon'),
    ('💿', 'Vinyles Pif Gadget', 'pif gadget'),
    ('📌', 'Pin\'s Coca-Cola FR', 'coca cola'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.themeTokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: const Text('Catalogues'),
        backgroundColor: tokens.bg,
      ),
      body: Column(
        children: [
          // ── category pills ──
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((label) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => context.push('/download'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: tokens.ink.withOpacity(0.2)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: tokens.ink.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // ── info banner ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.accentSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: tokens.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recherche et import dans l\'onglet Découvrir',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.ink.withOpacity(0.7),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/download'),
                    child: const Text('Y aller',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── popular collections ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Populaires',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: tokens.ink)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: _popular.map((p) {
                final (emoji, name, query) = p;
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
                          color: tokens.accentSoft,
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.ink)),
                            const SizedBox(height: 2),
                            Text('Chercher dans Découvrir',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: tokens.ink.withOpacity(0.6))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/download'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: tokens.accent,
                                strokeAlign: BorderSide.strokeAlignInside),
                          ),
                          child: Icon(Icons.search, size: 16, color: tokens.accent),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
