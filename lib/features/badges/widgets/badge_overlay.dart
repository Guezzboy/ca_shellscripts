import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Full-screen badge unlock overlay with confetti + pop animation.
/// Matches the Colectio wireframe variant A: Confetti + flip.
class BadgeOverlay extends StatefulWidget {
  final String emoji;
  final String name;
  final String description;
  final VoidCallback onDismiss;

  const BadgeOverlay({
    super.key,
    required this.emoji,
    required this.name,
    required this.description,
    required this.onDismiss,
  });

  @override
  State<BadgeOverlay> createState() => _BadgeOverlayState();
}

class _BadgeOverlayState extends State<BadgeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popCtrl;
  late final Animation<double> _popScale;

  final _confetti = <_Confetti>[];

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.1), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _popCtrl, curve: Curves.easeOut),
    );
    _popCtrl.forward();

    // Generate confetti
    for (var i = 0; i < 20; i++) {
      _confetti.add(_Confetti(
        x: 10.0 + (i * 13) % 260,
        y: 60.0 + ((i * 37) % 200),
        rotation: (i * 31) % 360,
        color: [
          const Color(0xFFF4A72B),
          const Color(0xFFE07A1F),
          const Color(0xFFFFD166),
          Colors.white,
        ][i % 4],
        size: (i * 7) % 8 + 4.0,
      ));
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark backdrop
          Positioned.fill(
            child: Container(color: Colors.black54),
          ),
          // Confetti
          ..._confetti.map(
            (c) => Positioned(
              left: c.x,
              top: c.y,
              child: Transform.rotate(
                angle: c.rotation * 0.01745,
                child: Container(
                  width: c.size,
                  height: c.size * 1.4,
                  decoration: BoxDecoration(
                    color: c.color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          // Center badge card
          Center(
            child: ScaleTransition(
              scale: _popScale,
              child: Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF4A72B), Color(0xFFE07A1F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      offset: const Offset(0, 20),
                      blurRadius: 50,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 70),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Top label
          const Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Text(
              'Nouveau badge',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Bottom congratulation
          Positioned(
            top: 370,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Tu es sur ta lancée 🎉',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // CTA button
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE07A1F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Trop bien !',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Share.share(
                      'Je viens de débloquer le badge '
                      '"${widget.name}" dans Colectio ! '
                      '${widget.emoji}',
                    );
                  },
                  child: const Text(
                    'Partager',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti {
  final double x;
  final double y;
  final double rotation;
  final Color color;
  final double size;

  const _Confetti({
    required this.x,
    required this.y,
    required this.rotation,
    required this.color,
    required this.size,
  });
}

/// Show badge overlay as a full-screen dialog.
void showBadgeOverlay(
  BuildContext context, {
  required String emoji,
  required String name,
  required String description,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => BadgeOverlay(
      emoji: emoji,
      name: name,
      description: description,
      onDismiss: () => Navigator.of(context).pop(),
    ),
  );
}
