import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Custom shell with 5-tab bottom nav + center FAB scanner button.
/// The FAB rises above the nav bar with an amber gradient, matching the
/// Colectio wireframe design.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  // ── tab definitions ──
  static const _tabs = <_TabDef>[
    _TabDef('Accueil', Icons.home_rounded, '/'),
    _TabDef('Collections', Icons.grid_view_rounded, '/collections'),
    _TabDef('Scanner', Icons.qr_code_scanner_rounded, '/scan'),
    _TabDef('Catalogue', Icons.menu_book_rounded, '/catalogue'),
    _TabDef('Réglages', Icons.settings_rounded, '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Scaffold(
      body: navigationShell,
      floatingActionButton: _ScanFAB(tokens: tokens),
      floatingActionButtonLocation: _CenterDockedFabLocation(),
      bottomNavigationBar: _BottomNav(
        shell: navigationShell,
        tokens: tokens,
      ),
    );
  }
}

// ── bottom nav bar ──
class _BottomNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  final ThemeTokens tokens;
  const _BottomNav({required this.shell, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(color: tokens.ink.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < AppShell._tabs.length; i++)
            _NavItem(
              def: AppShell._tabs[i],
              active: shell.currentIndex == i,
              tokens: tokens,
              onTap: () => shell.goBranch(
                i,
                initialLocation: i == shell.currentIndex,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabDef def;
  final bool active;
  final ThemeTokens tokens;
  final VoidCallback onTap;

  const _NavItem({
    required this.def,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Center tab (index 2) is the scanner — hidden in the bar, shown as FAB
    if (def.path == '/scan') return const Spacer();

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              def.icon,
              size: 22,
              color: active ? tokens.accentDeep : tokens.ink.withOpacity(0.4),
            ),
            const SizedBox(height: 3),
            Text(
              def.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color:
                    active ? tokens.accentDeep : tokens.ink.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── center scan FAB ──
class _ScanFAB extends StatelessWidget {
  final ThemeTokens tokens;
  const _ScanFAB({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/scan'),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [tokens.accent, tokens.accentDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: tokens.accent.withOpacity(0.5),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
          border: Border.all(
            color: tokens.surface,
            width: 4,
          ),
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

/// Custom FAB location that docks the button centered above the bottom bar.
class _CenterDockedFabLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2;
    final fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        38; // half above bar
    return Offset(fabX, fabY);
  }

  @override
  String toString() => '_CenterDockedFabLocation';
}

class _TabDef {
  final String label;
  final IconData icon;
  final String path;
  const _TabDef(this.label, this.icon, this.path);
}
