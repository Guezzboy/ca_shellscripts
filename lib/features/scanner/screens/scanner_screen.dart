import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

/// Scanner screen — Hybrid code-barres + photo.
/// Matches the Colectio wireframe variant A: dark viewfinder, tab switch, pulsing scan line.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: SafeArea(
        child: Column(
          children: [
            // ── top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Scanner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.flash_on, color: Colors.white, size: 20),
                ],
              ),
            ),

            // ── tab switch: Code / Photo ──
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModeSwitch(tokens: tokens),
            ),

            // ── viewfinder ──
            const Expanded(child: _Viewfinder()),

            // ── bottom controls ──
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(Icons.upload_file,
                      color: Colors.white70, size: 22),
                  // Shutter button
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFF4A72B), Color(0xFFE07A1F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
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

/// Tab switch: Code-barres | Photo
class _ModeSwitch extends StatefulWidget {
  final ThemeTokens tokens;
  const _ModeSwitch({required this.tokens});

  @override
  State<_ModeSwitch> createState() => _ModeSwitchState();
}

class _ModeSwitchState extends State<_ModeSwitch> {
  bool _code = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SwitchPill(
            label: 'Code',
            icon: Icons.qr_code,
            active: _code,
            accent: widget.tokens.accent,
            onTap: () => setState(() => _code = true),
          ),
          _SwitchPill(
            label: 'Photo',
            icon: Icons.camera_alt_outlined,
            active: !_code,
            accent: widget.tokens.accent,
            onTap: () => setState(() => _code = false),
          ),
        ],
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _SwitchPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? Colors.white : Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Viewfinder with corner brackets and pulsing scan line.
class _Viewfinder extends StatefulWidget {
  const _Viewfinder();

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // View box
          Container(
            width: 220,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          // Corner brackets
          ..._corners(),
          // Scan line
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Positioned(
                left: 12,
                right: 12,
                top: 30 + (_pulseCtrl.value.abs() * 100),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Color(0xFFF4A72B), Colors.transparent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF4A72B).withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Pulsing ring
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Container(
                width: 220,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFF4A72B)
                        .withOpacity(0.3 * (1 - _pulseCtrl.value.abs())),
                    width: 2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const length = 30.0;
    const thick = 3.0;
    const c = Color(0xFFF4A72B);
    return [
      // top-left
      Positioned(
        top: 0, left: 0,
        child: Container(
          width: length, height: length,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: c, width: thick),
              left: BorderSide(color: c, width: thick),
            ),
          ),
        ),
      ),
      // top-right
      Positioned(
        top: 0, right: 0,
        child: Container(
          width: length, height: length,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(topRight: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: c, width: thick),
              right: BorderSide(color: c, width: thick),
            ),
          ),
        ),
      ),
      // bottom-left
      Positioned(
        bottom: 0, left: 0,
        child: Container(
          width: length, height: length,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(22)),
            border: Border(
              bottom: BorderSide(color: c, width: thick),
              left: BorderSide(color: c, width: thick),
            ),
          ),
        ),
      ),
      // bottom-right
      Positioned(
        bottom: 0, right: 0,
        child: Container(
          width: length, height: length,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(22)),
            border: Border(
              bottom: BorderSide(color: c, width: thick),
              right: BorderSide(color: c, width: thick),
            ),
          ),
        ),
      ),
    ];
  }
}
