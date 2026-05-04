import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/providers/collection_providers.dart';

/// Onboarding flow — 3 steps matching Colectio wireframes A, B, D.
/// Step 0: Illustrated welcome
/// Step 1: Collection type picker
/// Step 2: Camera permission
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_complete') ?? false);
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  final _pageCtrl = PageController();
  String? _selectedCategory;
  bool _creating = false;

  Future<void> _next() async {
    if (_step < 2) {
      _pageCtrl.animateToPage(_step + 1,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      return;
    }

    // Pre-create a collection from the selected category
    if (_selectedCategory != null && !_creating) {
      setState(() => _creating = true);
      try {
        await ref.read(collectionsProvider.notifier).create(_selectedCategory!);
      } catch (_) {
        // Collection creation failed — user can create manually later
      }
    }

    await OnboardingScreen.markComplete();
    widget.onDone();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Dots
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _step ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: i == _step
                          ? tokens.accent
                          : tokens.ink.withOpacity(0.2),
                    ),
                  );
                }),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _StepWelcome(tokens: tokens),
                  _StepPicker(
                    tokens: tokens,
                    selected: _selectedCategory,
                    onSelect: (c) =>
                        setState(() => _selectedCategory = c),
                  ),
                  _StepPermissions(tokens: tokens),
                ],
              ),
            ),
            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _creating ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _step == 2 ? "C'est parti" : 'Suivant',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  if (_step < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IgnorePointer(
                        ignoring: _creating,
                        child: GestureDetector(
                          onTap: _next,
                          child: Text(
                            'Passer',
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.ink.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 0: Illustrated welcome ──
class _StepWelcome extends StatelessWidget {
  final ThemeTokens tokens;
  const _StepWelcome({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustrated cards
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.accentSoft,
                      ),
                    ),
                  ),
                ),
                // Floating cards
                ...[
                  (x: 30.0, y: 10.0, r: -8.0, c: Color(0xFFF4A72B)),
                  (x: 110.0, y: 40.0, r: 6.0, c: Color(0xFFE07A1F)),
                  (x: 50.0, y: 100.0, r: -3.0, c: Color(0xFFFFD166)),
                  (x: 110.0, y: 110.0, r: 12.0, c: Color(0xFFF4A72B)),
                ].map((p) {
                  return Positioned(
                    left: p.x,
                    top: p.y,
                    child: Transform.rotate(
                      angle: p.r * 0.01745,
                      child: Container(
                        width: 50,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: p.c, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Positioned(top: 10, right: 40, child: Text('✨', style: TextStyle(fontSize: 22))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tes collections,\nenfin réunies.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mangas, verres, cartes ou trésors de brocante :\nun seul endroit pour tout suivre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: tokens.ink.withOpacity(0.65),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Collection type picker ──
class _StepPicker extends StatelessWidget {
  final ThemeTokens tokens;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _StepPicker({
    required this.tokens,
    required this.selected,
    required this.onSelect,
  });

  static const _categories = [
    (emoji: '📚', name: 'Mangas / BD'),
    (emoji: '🍷', name: 'Verres'),
    (emoji: '🎴', name: 'Cartes'),
    (emoji: '💿', name: 'Vinyles'),
    (emoji: '🧸', name: 'Jouets'),
    (emoji: '✨', name: 'Autre'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            'Bienvenue !',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Que veux-tu collectionner en premier ?',
            style: TextStyle(
              fontSize: 13,
              color: tokens.ink.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: _categories.map((c) {
                final active = selected == c.name;
                return GestureDetector(
                  onTap: () => onSelect(c.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: active ? tokens.accentSoft : tokens.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? tokens.accent
                            : tokens.ink.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 6),
                        Text(
                          c.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Text(
            'Tu pourras en ajouter d\'autres après ✨',
            style: TextStyle(
              fontSize: 11,
              color: tokens.ink.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Camera permission ──
class _StepPermissions extends StatelessWidget {
  final ThemeTokens tokens;
  const _StepPermissions({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.accentSoft,
              border: Border.all(color: tokens.accent, width: 2),
            ),
            alignment: Alignment.center,
            child: const Text('📷', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 14),
          Text(
            'Une dernière chose\u2026',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pour scanner tes objets en un geste,\non a besoin de l\'appareil photo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: tokens.ink.withOpacity(0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.ink.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _PermissionLine(
                    tokens, 'On scanne uniquement quand tu ouvres le scanner'),
                const SizedBox(height: 10),
                _PermissionLine(
                    tokens, 'Aucune photo n\'est envoyée sans ton accord'),
                const SizedBox(height: 10),
                _PermissionLine(
                    tokens, 'Tu peux changer d\'avis dans les Réglages'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionLine extends StatelessWidget {
  final ThemeTokens tokens;
  final String text;
  const _PermissionLine(this.tokens, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check, size: 18, color: tokens.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: tokens.ink),
          ),
        ),
      ],
    );
  }
}
